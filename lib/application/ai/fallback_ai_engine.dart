import '../../domain/entities/intent_context.dart';
import '../../domain/entities/meeting.dart';
import '../../domain/entities/meeting_template.dart';
import '../../domain/entities/voice_intent.dart';
import '../../domain/failures/failure.dart';
import '../../domain/ports/ai_engine.dart';
import '../../domain/ports/ai_engine_settings_store.dart';

/// One engine in the chain, with the id its answers are counted against.
class NamedEngine {
  const NamedEngine({
    required this.id,
    required this.label,
    required this.engine,
  });

  /// Stable id, used for the usage counter and the diagnostics log.
  final String id;

  /// Human-readable name, used in the message the user is shown.
  final String label;

  final AiEngine engine;
}

/// The BR-10 policy: primary → one retry → fallback → a clear error
/// (`docs/architecture.md` §7.3).
///
/// **This is an [AiEngine], so nothing above it knows the chain exists.**
/// `SummarizeMeeting` and `IntentParser` call `summarize` and `parseIntent` and
/// get an answer or a [Failure]; whether that answer came from the engine the
/// user chose is recorded, not raised. That is the point of S07-E2E-01 — a
/// transparent fallback shows the user their summary, not an apology.
///
/// **The sequence is exact, and the order of the checks is the specification.**
/// Primary, then primary once more, then — only if the user allows it — the
/// fallback once. Not two retries, not a retry on the fallback, and not a
/// fallback attempt when the setting is off (S07-UT-02 scenario D asserts the
/// fallback is never *touched*, which is stronger than asserting it did not
/// answer: an engine that is asked and fails has still spent the user's money).
///
/// **The retry is unconditional, and that is deliberate.** An obvious
/// improvement is to skip it for failures that cannot change — a missing API
/// key will still be missing, a CLI that is not installed will not have
/// installed itself, a transcript that is too long is still too long — and an
/// earlier draft of this class did exactly that, classifying failures into
/// retryable and settled.
///
/// It was removed. BR-10 specifies the **exact sequence** primary → retry →
/// fallback → error, and `docs/project-rules.md` is law over a local
/// optimisation: a rule that says "exact" stops meaning anything the first time
/// an implementation decides it knows better. The cost of the extra call is one
/// failed attempt on a request that was already failing, and the benefit was
/// never correctness — it was speed on the unhappy path.
///
/// The classification is not gone, only relocated to where it does not
/// contradict a rule: `_isRetryable` in `OutboxDispatcher` still decides what
/// the Jira queue re-attempts, because that queue's schedule is measured in
/// hours rather than milliseconds and BR-10 has nothing to say about it.
class FallbackAiEngine implements AiEngine {
  FallbackAiEngine({
    required this.primary,
    required this.fallback,
    required this.fallbackEnabled,
    this.usage,
    this.log,
  });

  /// The engine the user chose.
  final NamedEngine primary;

  /// The engine to try when the primary cannot answer.
  ///
  /// `null` when there is nothing to fall back to — the user chose the only
  /// engine available on their platform — which behaves exactly like the
  /// setting being off.
  final NamedEngine? fallback;

  /// Whether the user permits a fallback (BR-10).
  final bool fallbackEnabled;

  /// Where answers are counted. Absent in tests that do not care.
  final AiEngineSettingsStore? usage;

  /// Diagnostics sink. **Every switch is logged with its reason** — the
  /// sprint's validation rule, and the only way a user can find out that the
  /// engine they picked is not the one answering, since the whole design goal
  /// above it is that they cannot tell.
  final void Function(String line)? log;

  @override
  AiCapabilities get capabilities => primary.engine.capabilities;

  @override
  Future<MeetingSummary> summarize(
    String transcript,
    MeetingTemplate template,
  ) => _through<MeetingSummary>(
    'summarize',
    (AiEngine engine) => engine.summarize(transcript, template),
  );

  @override
  Future<VoiceIntent> parseIntent(String utterance, IntentContext context) =>
      _through<VoiceIntent>(
        'parseIntent',
        (AiEngine engine) => engine.parseIntent(utterance, context),
      );

  @override
  Future<void> primeCache() async {
    // Warms the primary only. The fallback is by definition the engine that is
    // not expected to be used, and warming it would spend a request on that
    // expectation being wrong. It never throws, so nothing here needs a guard
    // beyond the port's own promise.
    await primary.engine.primeCache();
  }

  /// Runs [call] through the chain.
  Future<T> _through<T>(
    String operation,
    Future<T> Function(AiEngine engine) call,
  ) async {
    Failure? primaryFailure;

    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        final T answer = await call(primary.engine);
        await _count(primary.id);
        return answer;
      } on Failure catch (failure) {
        primaryFailure = failure;
        _log(
          '$operation: ${primary.id} failed '
          '(attempt $attempt/2) — ${failure.runtimeType}: ${failure.message}',
        );
      }
    }

    final NamedEngine? second = fallback;
    if (!fallbackEnabled || second == null) {
      _log(
        '$operation: no fallback — '
        '${!fallbackEnabled ? 'disabled by the user' : 'none configured'}',
      );
      throw _exhausted(<NamedEngine>[primary], primaryFailure);
    }

    // The switch itself, with its reason. This is the line the sprint's
    // validation rule is about and the one S07-E2E-01 looks for.
    _log(
      '$operation: switching ${primary.id} → ${second.id} — '
      '${primaryFailure?.runtimeType ?? 'unknown'}',
    );

    try {
      final T answer = await call(second.engine);
      await _count(second.id);
      return answer;
    } on Failure catch (failure) {
      _log(
        '$operation: ${second.id} failed too — '
        '${failure.runtimeType}: ${failure.message}',
      );
      throw _exhausted(<NamedEngine>[primary, second], failure);
    }
  }

  /// The end of the chain, phrased for someone who has to fix it.
  ///
  /// It names the engines that were tried and points at Settings, because at
  /// this point the app has nothing left to try and the next move is the
  /// user's (S07-E2E-02). The underlying failure's own message is included:
  /// "Copilot could not be started — is it installed?" is the sentence that
  /// ends the search, and burying it under a generic one would restart it.
  AiUnavailableFailure _exhausted(List<NamedEngine> tried, Failure? cause) {
    final String names = tried.map((NamedEngine e) => e.label).join(' and ');
    final String because = cause == null ? '' : ' (${cause.message})';
    return AiUnavailableFailure(
      'No AI engine could answer. Tried $names$because. '
      'Check the AI Engine section in Settings.',
      tried: tried.map((NamedEngine e) => e.id).toList(growable: false),
    );
  }

  /// Records that [engineId] produced an answer.
  ///
  /// Best effort: a counter that failed to save must not turn a summary the
  /// user is waiting for into an error. The failure is logged and dropped.
  Future<void> _count(String engineId) async {
    final AiEngineSettingsStore? store = usage;
    if (store == null) return;
    try {
      await store.recordAnswer(engineId);
    } on Failure catch (failure) {
      _log('usage: could not record $engineId — ${failure.runtimeType}');
    }
  }

  void _log(String line) => log?.call('[ai] $line');
}
