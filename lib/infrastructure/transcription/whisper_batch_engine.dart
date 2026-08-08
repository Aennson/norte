import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/transcript.dart';
import '../../domain/failures/failure.dart';
import '../../domain/ports/transcription_credential_store.dart';
import '../../domain/ports/transcription_engine.dart';

/// [BatchTranscription] over the Whisper transcriptions API
/// (`docs/architecture.md` §9.2).
///
/// **Why batch for a recorded meeting.** Latency is irrelevant once the
/// meeting is over, the file may be ninety minutes long, and the price per
/// minute is a fraction of a realtime session's. Routing is fixed per use case
/// (§9.2), so nothing here is user-configurable except the key.
///
/// **BYOK.** The key is read from [TranscriptionCredentialStore] per request
/// and never held in a field (BR-08). No key at all is [MissingApiKeyFailure]
/// rather than [AuthFailure]: one sends the user to Settings to add something,
/// the other to fix something.
///
/// **The file is never deleted here.** The port says so and this sprint's
/// retry rule depends on it: a failed upload must leave the audio exactly
/// where it was, or "try again" would mean "record it again" (S04-UT-02).
///
/// **Errors.** Every outcome is a [Failure]; a `DioException` never escapes
/// (`docs/project-rules.md` §6).
class WhisperBatchEngine implements BatchTranscription {
  WhisperBatchEngine({
    required this.dio,
    required this.credentialStore,
    this.model = defaultModel,
    this.baseUrl = defaultBaseUrl,
  });

  final Dio dio;
  final TranscriptionCredentialStore credentialStore;

  /// Model id. Configurable because the user pays for it.
  final String model;
  final String baseUrl;

  /// The default transcription model.
  static const String defaultModel = 'whisper-1';

  /// The API host.
  static const String defaultBaseUrl = 'https://api.openai.com';

  /// Path of the transcriptions endpoint.
  static const String endpoint = '/v1/audio/transcriptions';

  final StreamController<double> _progress =
      StreamController<double>.broadcast();

  @override
  TranscriptionMode get mode => TranscriptionMode.batch;

  /// Upload progress, `0.0..1.0`.
  ///
  /// It reports the **upload**, which is the honest thing it can measure: once
  /// the bytes are sent the service is working and says nothing until it
  /// answers. The UI shows a determinate bar while uploading and an
  /// indeterminate stage while transcribing, rather than inventing a curve for
  /// the half nobody can see.
  @override
  Stream<double> get progress => _progress.stream;

  @override
  Future<Transcript> transcribeFile(String path, {String? language}) async {
    final File audio = File(path);
    if (!await audio.exists()) {
      // Checked before the key is read: a missing file is the caller's bug and
      // there is no point troubling the secure store over it.
      throw NotFoundFailure('no audio file at "$path"');
    }

    final String apiKey = await _apiKey();
    final FormData form = FormData.fromMap(<String, Object?>{
      'file': await MultipartFile.fromFile(path, filename: p.basename(path)),
      'model': model,
      // `verbose_json` is what carries the detected language back. Plain
      // `json` would force the engine to echo whatever the caller asked for,
      // and the port promises the engine's answer rather than the question.
      'response_format': 'verbose_json',
      if (language != null && language.isNotEmpty) 'language': language,
    });

    try {
      final Response<Object?> response = await dio.post<Object?>(
        '$baseUrl$endpoint',
        data: form,
        onSendProgress: _report,
        options: Options(
          headers: <String, Object?>{'authorization': 'Bearer $apiKey'},
          // 5xx must reach `_failureFor` as a status rather than as a
          // DioException, so the two are classified in one place.
          validateStatus: (int? status) => status != null,
        ),
      );

      final int status = response.statusCode ?? 0;
      if (status >= 400) throw _failureFor(status, response.headers);

      return _parse(response.data, language);
    } on Failure {
      rethrow;
    } on DioException catch (error) {
      throw _failureForDio(error);
    } catch (_) {
      // Nothing but a Failure leaves this method, so an unanticipated response
      // cannot escape past the use case's `on Failure` and vanish.
      throw const TranscriptionFailure(
        'the transcription service returned something this app could not read',
      );
    }
  }

  /// Closes the progress stream. Call when the engine is discarded.
  Future<void> dispose() => _progress.close();

  // --- internals ---------------------------------------------------------

  /// The user's key, or [MissingApiKeyFailure].
  Future<String> _apiKey() async {
    final String? key = await credentialStore.read();
    if (key == null || key.trim().isEmpty) {
      throw const MissingApiKeyFailure(
        'no transcription API key is configured — add one in Settings',
      );
    }
    return key.trim();
  }

  void _report(int sent, int total) {
    if (_progress.isClosed || total <= 0) return;
    _progress.add((sent / total).clamp(0.0, 1.0));
  }

  Transcript _parse(Object? data, String? requested) {
    final Object? decoded = data is String ? _tryDecode(data) : data;
    if (decoded is! Map<String, Object?>) {
      throw const TranscriptionFailure(
        'the transcription service did not answer with JSON',
      );
    }

    final Object? text = decoded['text'];
    if (text is! String || text.trim().isEmpty) {
      // An empty transcript is a failure, not a short meeting. Passing it on
      // would send the summarizer an empty string and produce a confident
      // summary of nothing.
      throw const TranscriptionFailure('the transcription came back empty');
    }

    final Object? detected = decoded['language'];
    return Transcript(
      text: text.trim(),
      // The engine's detection wins; the request is the fallback, and 'unknown'
      // is what an engine that reported neither has actually told us.
      language: detected is String && detected.isNotEmpty
          ? detected
          : (requested ?? 'unknown'),
    );
  }

  Object? _tryDecode(String payload) {
    try {
      return jsonDecode(payload);
    } on FormatException {
      return null;
    }
  }

  Failure _failureFor(int status, Headers headers) => switch (status) {
    401 || 403 => const AuthFailure(
      'the transcription key was rejected — check it in Settings',
    ),
    404 => const NotFoundFailure('no such transcription model'),
    413 => const ValidationFailure('the recording is too long to upload'),
    415 => const ValidationFailure('the recording is in an unsupported format'),
    429 => RateLimitFailure(
      'the transcription service is rate limiting',
      _retryAfter(headers),
    ),
    // Everything from 500 up, and any 4xx not named above. The sprint asks
    // specifically that 5xx be a TranscriptionFailure: the audio is intact and
    // the operation is worth trying again (S04-IT-01).
    _ => const TranscriptionFailure('the transcription service failed'),
  };

  Duration? _retryAfter(Headers headers) {
    final String? value = headers.value('retry-after');
    final int? seconds = value == null ? null : int.tryParse(value);
    return seconds == null ? null : Duration(seconds: seconds);
  }

  Failure _failureForDio(DioException error) => switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => const TimeoutFailure(
      'the transcription service did not answer in time',
    ),
    DioExceptionType.connectionError ||
    DioExceptionType.unknown => const NetworkFailure(),
    DioExceptionType.cancel => const TranscriptionFailure(
      'the transcription was cancelled',
    ),
    DioExceptionType.badCertificate => const NetworkFailure(
      'the transcription service presented an untrusted certificate',
    ),
    DioExceptionType.badResponse => _failureFor(
      error.response?.statusCode ?? 0,
      error.response?.headers ?? Headers(),
    ),
  };
}
