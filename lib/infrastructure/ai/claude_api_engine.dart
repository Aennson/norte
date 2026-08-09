import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/entities/intent_context.dart';
import '../../domain/entities/meeting.dart';
import '../../domain/entities/meeting_template.dart';
import '../../domain/entities/voice_intent.dart';
import '../../domain/failures/failure.dart';
import '../../domain/ports/ai_credential_store.dart';
import '../../domain/ports/ai_engine.dart';
import '../../domain/ports/clock.dart';
import 'intent_codec.dart';
import 'meeting_summary_codec.dart';

/// [AiEngine] over the Claude Messages API (`docs/architecture.md` §7.2).
///
/// **BYOK.** The key is the user's own, read from [AiCredentialStore] on each
/// request and never held in a field (BR-08). No key configured is
/// [MissingApiKeyFailure], not a crash and not a generic auth error — the two
/// send the user to different places, and only one of them is Settings.
///
/// **Prompt caching.** The template's system prompt is sent as the system
/// message with `cache_control`, and the transcript as the user message. That
/// split is the whole point: the system prompt is identical for every meeting
/// summarized under a template, so it is billed once and read cheaply
/// thereafter. Nothing meeting-specific may leak into it, which is why the
/// codec builds it from the template alone.
///
/// **Streaming.** Summaries are streamed. Not for progressive display — a
/// summary is JSON and cannot be rendered until it closes — but because a long
/// retro can take longer to generate than a plain HTTP request is willing to
/// wait. Streaming is the difference between a slow summary and a timeout.
///
/// **Errors.** Every outcome is a [Failure]; a `DioException` never escapes
/// (`docs/project-rules.md` §6).
class ClaudeApiEngine implements AiEngine {
  ClaudeApiEngine({
    required this.dio,
    required this.credentialStore,
    required this.clock,
    this.model = defaultModel,
    this.baseUrl = defaultBaseUrl,
    this.maxTokens = defaultMaxTokens,
    this.codec = const MeetingSummaryCodec(),
    this.intentCodec = const IntentCodec(),
    this.log,
  });

  final Dio dio;
  final AiCredentialStore credentialStore;
  final Clock clock;

  /// Model id. Configurable because the user pays for it.
  final String model;
  final String baseUrl;
  final int maxTokens;
  final MeetingSummaryCodec codec;
  final IntentCodec intentCodec;

  /// Diagnostics sink for what the API said when it refused a request.
  ///
  /// A 4xx from this endpoint is **this app's bug, not the user's** — a
  /// malformed body, a schema the validator rejects — and the response
  /// explains which. Discarding it, as the first version did, turned "your
  /// request is invalid because X" into `Claude answered 400` and left X
  /// unknowable from outside the process.
  ///
  /// It carries the API's own error message, which describes the request's
  /// shape rather than its content: no transcript, no utterance, no key.
  final void Function(String line)? log;

  /// The default model.
  static const String defaultModel = 'claude-opus-5';

  /// The API host.
  static const String defaultBaseUrl = 'https://api.anthropic.com';

  /// The API version header the Messages API requires.
  static const String apiVersion = '2023-06-01';

  /// Ceiling on one response. Generous on purpose: on this model the budget
  /// covers thinking as well as the summary, and a truncated summary is
  /// indistinguishable from a meeting that had nothing to say.
  static const int defaultMaxTokens = 16000;

  /// Ceiling on one intent answer. Three small fields; anything approaching
  /// this is a model that has stopped answering the question.
  static const int intentMaxTokens = 512;

  @override
  AiCapabilities get capabilities => const AiCapabilities(
    // Remote. This is what makes the PII redactor mandatory (BR-07).
    isLocal: false,
    supportsStreaming: true,
    supportsPromptCache: true,
    maxTokens: defaultMaxTokens,
  );

  @override
  Future<MeetingSummary> summarize(
    String transcript,
    MeetingTemplate template,
  ) async {
    final String key = await _apiKey();
    final String raw = await _stream(key, <String, Object?>{
      'model': model,
      'max_tokens': maxTokens,
      // The cached half. `cache_control` marks the prefix — tools, then
      // system — as reusable across every summary under this template.
      'system': <Object?>[
        <String, Object?>{
          'type': 'text',
          'text': codec.systemPromptFor(template),
          'cache_control': <String, Object?>{'type': 'ephemeral'},
        },
      ],
      // The uncached half: everything that varies per meeting sits after the
      // breakpoint, so it never invalidates the prefix.
      'messages': <Object?>[
        <String, Object?>{'role': 'user', 'content': transcript},
      ],
      'output_config': <String, Object?>{
        // Summarizing is not the kind of work that rewards deep deliberation,
        // and the user is paying per token.
        'effort': 'medium',
        // Constrains the answer to the codec's shape. It does not make the
        // parser optional — `CopilotCliEngine` has no such affordance, and a
        // constrained model can still be cut short.
        'format': <String, Object?>{
          'type': 'json_schema',
          'schema': MeetingSummaryCodec.schemaFor(template),
        },
      },
      'stream': true,
    });

    return codec.parse(
      raw,
      template,
      generatedAt: clock.now().toUtc(),
      engineId: model,
    );
  }

  @override
  Future<VoiceIntent> parseIntent(
    String utterance,
    IntentContext context,
  ) async {
    final String key = await _apiKey();
    final String raw = await _stream(key, <String, Object?>{
      'model': model,
      // An intent is three fields. The ceiling exists to stop a runaway
      // answer, not to leave room for one.
      'max_tokens': intentMaxTokens,
      // **Thinking off, and this is the largest lever there is.** On this
      // model thinking is *on by default* — omitting the field does not mean
      // "no thinking", and `effort: 'low'` does not turn it off either. The
      // manual pass measured Claude at 3292–5700 ms per command with it on,
      // against a 3 s budget for the whole pipeline (§15): the target was
      // unreachable without this line.
      //
      // Deliberating is the wrong shape of work here. The utterance is one
      // spoken sentence and the answer is a six-way choice with a handful of
      // string slots, constrained by a schema — the model is classifying, not
      // reasoning. Legal at `effort: 'low'`; the API refuses this combination
      // only above `high`.
      //
      // The two known hazards of disabling thinking do not reach this call:
      // a tool call written as prose (there are no tools here) and `<thinking>`
      // tags leaking into the answer (`output_config.format` constrains the
      // response to the codec's schema, and `IntentCodec` refuses anything it
      // cannot read rather than acting on it).
      'thinking': <String, Object?>{'type': 'disabled'},
      // The cached half, and this one earns the cache far better than the
      // summarizer's: the intent prompt is byte-identical on every voice
      // command the user ever speaks.
      'system': <Object?>[
        <String, Object?>{
          'type': 'text',
          'text': intentCodec.systemPrompt,
          'cache_control': <String, Object?>{'type': 'ephemeral'},
        },
      ],
      'messages': <Object?>[
        <String, Object?>{
          'role': 'user',
          'content': intentCodec.userMessageFor(utterance, context),
        },
      ],
      'output_config': <String, Object?>{
        // The user is holding a microphone and waiting: the p95 budget for
        // committed-speech to intent-ready is three seconds
        // (`docs/architecture.md` §15), and deliberation is what spends it.
        'effort': 'low',
        'format': <String, Object?>{
          'type': 'json_schema',
          'schema': IntentCodec.schema,
        },
      },
      // Streamed like the summary, for one unglamorous reason: it is the
      // adapter's only transport, and a second one would be a second set of
      // error paths to get right. The answer is small enough that the
      // difference is noise next to the model's own latency.
      'stream': true,
    });

    return intentCodec.parse(raw, context: context);
  }

  @override
  Future<void> primeCache() async {
    try {
      final String key = await _apiKey();
      await dio.post<void>(
        '$baseUrl/v1/messages',
        // Byte-identical `system` to the one [parseIntent] sends, because that
        // is the entire cached prefix: nothing is rendered before it, and the
        // breakpoint sits on it. What follows may differ freely.
        data: <String, Object?>{
          'model': model,
          // The whole request. Prefill runs and writes the cache; nothing is
          // generated, so nothing is billed as output.
          'max_tokens': 0,
          'system': <Object?>[
            <String, Object?>{
              'type': 'text',
              'text': intentCodec.systemPrompt,
              'cache_control': <String, Object?>{'type': 'ephemeral'},
            },
          ],
          // Read during prefill, never answered. It sits after the breakpoint,
          // so it is not part of what gets cached.
          'messages': <Object?>[
            <String, Object?>{'role': 'user', 'content': 'warmup'},
          ],
          // `max_tokens: 0` is refused alongside `stream` and
          // `output_config.format`, so neither is sent. Both belong to
          // generating an answer, and this request generates none.
        },
        options: Options(
          headers: <String, Object?>{
            'x-api-key': key,
            'anthropic-version': apiVersion,
            'content-type': 'application/json',
          },
          validateStatus: (int? status) => true,
        ),
      );
    } catch (_) {
      // Deliberately silent, and the contract says so. The worst outcome of a
      // failed warm-up is the cold request the app would have made anyway;
      // the worst outcome of letting this throw is a session that never
      // starts because the cache could not be primed.
    }
  }

  /// The user's key, or [MissingApiKeyFailure].
  Future<String> _apiKey() async {
    final String? key = await credentialStore.read();
    if (key == null || key.trim().isEmpty) throw const MissingApiKeyFailure();
    return key.trim();
  }

  /// Performs one streaming request and returns the assembled text.
  Future<String> _stream(String apiKey, Map<String, Object?> body) async {
    try {
      final Response<ResponseBody> response = await dio.post<ResponseBody>(
        '$baseUrl/v1/messages',
        data: body,
        options: Options(
          responseType: ResponseType.stream,
          headers: <String, Object?>{
            'x-api-key': apiKey,
            'anthropic-version': apiVersion,
            'content-type': 'application/json',
            'accept': 'text/event-stream',
          },
          validateStatus: (int? status) => status != null && status < 500,
        ),
      );

      final int status = response.statusCode ?? 0;
      if (status >= 400) {
        // Read the body before throwing. It is the only place the API says
        // *why*, and by the time the failure reaches a caller the stream is
        // gone.
        log?.call('HTTP $status — ${await _errorBody(response.data)}');
        throw _failureFor(status, response.headers);
      }

      final ResponseBody? stream = response.data;
      if (stream == null) {
        throw const AiResponseFailure('the engine returned an empty response');
      }
      return await _readSse(stream);
    } on Failure {
      rethrow;
    } on DioException catch (error) {
      throw _failureForDio(error);
    } catch (_) {
      // As in the Jira adapter: nothing but a Failure leaves this method, so
      // an unanticipated response cannot escape as a raw error past the use
      // case's `on Failure` and vanish.
      throw const AiResponseFailure(
        'the engine returned something this app could not read',
      );
    }
  }

  /// Accumulates `content_block_delta` text from the event stream.
  ///
  /// Only text deltas are collected. Thinking blocks stream too and are
  /// deliberately dropped: they are the model's reasoning, not the summary,
  /// and concatenating them would corrupt the JSON the codec has to read.
  Future<String> _readSse(ResponseBody body) async {
    final StringBuffer answer = StringBuffer();
    Failure? failure;
    final Map<String, int> usage = <String, int>{};

    await for (final String line
        in utf8.decoder.bind(body.stream).transform(const LineSplitter())) {
      if (!line.startsWith('data:')) continue;
      final String payload = line.substring(5).trim();
      if (payload.isEmpty || payload == '[DONE]') continue;

      final Object? event = switch (payload) {
        final String text => _tryDecode(text),
      };
      if (event is! Map<String, Object?>) continue;

      switch (event['type']) {
        case 'message_start':
          // Input and cache counts ride on the opening event; the output
          // count arrives on `message_delta` at the end.
          if (event['message'] case final Map<String, Object?> message) {
            _collectUsage(message['usage'], into: usage);
          }
        case 'message_delta':
          _collectUsage(event['usage'], into: usage);
        case 'content_block_delta':
          final Object? delta = event['delta'];
          if (delta is Map<String, Object?> && delta['type'] == 'text_delta') {
            final Object? text = delta['text'];
            if (text is String) answer.write(text);
          }
        case 'error':
          // The API reports mid-stream problems in the stream itself; a 200
          // that ends in an error event must not read as a short summary.
          failure = _failureForStreamError(event['error']);
      }
    }

    _reportUsage(usage);

    if (failure != null) throw failure;
    if (answer.isEmpty) {
      throw const AiResponseFailure('the engine returned an empty summary');
    }
    return answer.toString();
  }

  /// Copies the token counts off one `usage` object.
  void _collectUsage(Object? raw, {required Map<String, int> into}) {
    if (raw is! Map<String, Object?>) return;
    for (final MapEntry<String, Object?> entry in raw.entries) {
      if (entry.value case final num value) into[entry.key] = value.toInt();
    }
  }

  /// Says what the request cost, in tokens, and **whether the cache was read**.
  ///
  /// The prompt is marked `cache_control` and is byte-identical on every voice
  /// command, so it ought to be served from cache after the first — but "ought
  /// to" is the part nobody could check: a cache that silently never hits looks
  /// exactly like one that always does. `cache_read_input_tokens` at zero
  /// across a session is the answer, and it is the number that decides whether
  /// shortening the prompt would help or would push it under the cacheable
  /// floor and make things worse.
  ///
  /// Counts only — no transcript, no utterance, no key (BR-06).
  void _reportUsage(Map<String, int> usage) {
    if (log == null || usage.isEmpty) return;
    log!.call(
      'usage: in ${usage['input_tokens'] ?? 0} '
      '(cache read ${usage['cache_read_input_tokens'] ?? 0}, '
      'written ${usage['cache_creation_input_tokens'] ?? 0}) '
      '· out ${usage['output_tokens'] ?? 0}',
    );
  }

  /// The API's explanation of a refusal, as text.
  ///
  /// Best effort by design: a body that cannot be read must not replace the
  /// failure with a different one, so anything unexpected becomes a short note
  /// rather than an exception.
  Future<String> _errorBody(ResponseBody? body) async {
    if (body == null) return '(no body)';
    try {
      final String text = await utf8.decoder.bind(body.stream).join();
      return text.length > 600 ? '${text.substring(0, 600)}…' : text;
    } catch (_) {
      return '(body unreadable)';
    }
  }

  Object? _tryDecode(String payload) {
    try {
      return jsonDecode(payload);
    } on FormatException {
      return null;
    }
  }

  Failure _failureForStreamError(Object? error) {
    final String? type = error is Map<String, Object?>
        ? error['type'] as String?
        : null;
    return switch (type) {
      'overloaded_error' => const RateLimitFailure('Claude is overloaded'),
      'rate_limit_error' => const RateLimitFailure('Claude is rate limiting'),
      'authentication_error' => const AuthFailure(
        'Claude rejected the API key',
      ),
      _ => const EngineFailure('the engine failed part-way through'),
    };
  }

  Failure _failureFor(int status, Headers headers) => switch (status) {
    401 || 403 => const AuthFailure(
      'Claude rejected the API key — check it in Settings',
    ),
    404 => const NotFoundFailure('no such Claude model'),
    413 => const ValidationFailure(
      'the transcript is too long for one request',
      'transcript',
    ),
    429 => RateLimitFailure('Claude is rate limiting', _retryAfter(headers)),
    _ => EngineFailure('Claude answered $status'),
  };

  Failure _failureForDio(DioException error) {
    final Object? thrown = error.error;
    if (thrown is Failure) return thrown;
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => const TimeoutFailure(
        'Claude did not answer in time',
      ),
      DioExceptionType.connectionError ||
      DioExceptionType.unknown => const NetworkFailure('cannot reach Claude'),
      DioExceptionType.badCertificate => const NetworkFailure(
        'Claude presented an untrusted certificate',
      ),
      DioExceptionType.cancel => const NetworkFailure('request cancelled'),
      DioExceptionType.badResponse => _failureFor(
        error.response?.statusCode ?? 0,
        error.response?.headers ?? Headers(),
      ),
    };
  }

  Duration? _retryAfter(Headers headers) {
    final String? value = headers.value('retry-after');
    final int? seconds = value == null ? null : int.tryParse(value);
    return seconds == null ? null : Duration(seconds: seconds);
  }
}
