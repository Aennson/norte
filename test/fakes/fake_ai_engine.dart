import 'dart:async';

import 'package:norte/domain/entities/meeting.dart';
import 'package:norte/domain/entities/meeting_template.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/ai_engine.dart';
import 'package:norte/infrastructure/ai/meeting_summary_codec.dart';

/// One `summarize` call, as the engine received it.
class AiCall {
  const AiCall({required this.transcript, required this.template});

  /// **The text the engine was given** — the assertion BR-07 turns on. If a
  /// CPF is in here, redaction did not happen.
  final String transcript;

  final MeetingTemplate template;

  /// What the adapter would send as the system message.
  String get systemPrompt =>
      const MeetingSummaryCodec().systemPromptFor(template);

  @override
  String toString() => 'summarize(${transcript.length} chars, ${template.id})';
}

/// Deterministic [AiEngine] driven by fixtures
/// (`docs/testing-strategy.md` §3).
///
/// **It parses with the real codec.** The fixtures are raw model answers, run
/// through the same `MeetingSummaryCodec` the Claude adapter uses, so the fake
/// cannot be more forgiving than production — which is what makes S03-CT-01 a
/// contract test rather than two suites agreeing with themselves.
class FakeAiEngine implements AiEngine {
  FakeAiEngine({
    Map<String, String>? summaries,
    Map<String, String>? intents,
    this.capabilities = const AiCapabilities(
      isLocal: false,
      supportsStreaming: true,
      supportsPromptCache: true,
      maxTokens: 8192,
    ),
    DateTime? generatedAt,
  }) : summaries = summaries ?? <String, String>{},
       intents = intents ?? <String, String>{},
       generatedAt = generatedAt ?? DateTime.utc(2026, 8, 8, 12);

  /// transcript → raw model answer.
  final Map<String, String> summaries;

  /// utterance → intent JSON (Sprint 05).
  final Map<String, String> intents;

  @override
  final AiCapabilities capabilities;

  /// The instant every summary is stamped with, so tests stay deterministic.
  final DateTime generatedAt;

  /// Every call received, in order.
  final List<AiCall> calls = <AiCall>[];

  /// When set, every call throws it instead of answering.
  Failure? failWith;

  /// Raw answers to give, in order, ahead of the fixture map.
  ///
  /// This is what drives the retry policy (S03-UT-06): queue an unreadable
  /// answer followed by a good one and the use case must ask twice; queue two
  /// unreadable ones and it must give up rather than ask a third time.
  final List<String> scriptedAnswers = <String>[];

  /// Artificial delay before answering.
  Duration latency = Duration.zero;

  /// When `true`, calls never complete — used to exercise timeout handling.
  bool hang = false;

  /// Convenience for the common case: always answer with [raw].
  // ignore: use_setters_to_change_properties
  void alwaysAnswer(String raw) {
    _fallbackAnswer = raw;
  }

  String? _fallbackAnswer;

  /// The transcript of the most recent call, or `null` when there was none.
  String? get lastTranscript => calls.isEmpty ? null : calls.last.transcript;

  @override
  Future<MeetingSummary> summarize(
    String transcript,
    MeetingTemplate template,
  ) async {
    calls.add(AiCall(transcript: transcript, template: template));

    if (hang) return Completer<MeetingSummary>().future;
    if (latency > Duration.zero) await Future<void>.delayed(latency);

    final Failure? failure = failWith;
    if (failure != null) throw failure;

    final String? raw = scriptedAnswers.isNotEmpty
        ? scriptedAnswers.removeAt(0)
        : summaries[transcript] ?? _fallbackAnswer;
    if (raw == null) {
      throw StateError(
        'FakeAiEngine has no summary fixture for a ${transcript.length}-char '
        'transcript. Add one to `summaries`, `scriptedAnswers`, or call '
        '`alwaysAnswer` — do not rely on a default.',
      );
    }

    // The real parser, including its refusal to return a partial summary.
    return const MeetingSummaryCodec().parse(
      raw,
      template,
      generatedAt: generatedAt,
      engineId: 'fake',
    );
  }

  @override
  Future<String> parseIntent(String utterance) async {
    final String? response = intents[utterance];
    if (response == null) {
      throw StateError('FakeAiEngine has no intent fixture for: "$utterance".');
    }
    return response;
  }

  /// Transcripts seen, in call order.
  List<String> get transcripts =>
      calls.map((AiCall call) => call.transcript).toList();

  /// Forgets every recorded interaction.
  void reset() {
    calls.clear();
    scriptedAnswers.clear();
    failWith = null;
    latency = Duration.zero;
    hang = false;
  }
}
