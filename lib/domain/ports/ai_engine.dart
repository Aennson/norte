import '../entities/intent_context.dart';
import '../entities/meeting.dart';
import '../entities/meeting_template.dart';
import '../entities/voice_intent.dart';

/// What an AI engine can do (`docs/architecture.md` §7.1).
///
/// Read by the application layer to decide policy, not by the UI to decide
/// wording — [isLocal] in particular is a **business** input: it is the one
/// condition under which BR-07 permits the PII redactor to be relaxed.
class AiCapabilities {
  const AiCapabilities({
    required this.isLocal,
    required this.supportsStreaming,
    required this.supportsPromptCache,
    required this.maxTokens,
  });

  /// `true` when inference runs on the user's machine, which is the only
  /// condition under which PII redaction may be relaxed (BR-07).
  final bool isLocal;

  final bool supportsStreaming;
  final bool supportsPromptCache;
  final int maxTokens;

  @override
  bool operator ==(Object other) =>
      other is AiCapabilities &&
      other.isLocal == isLocal &&
      other.supportsStreaming == supportsStreaming &&
      other.supportsPromptCache == supportsPromptCache &&
      other.maxTokens == maxTokens;

  @override
  int get hashCode =>
      Object.hash(isLocal, supportsStreaming, supportsPromptCache, maxTokens);
}

/// The pluggable AI engine (`docs/architecture.md` §7.1).
///
/// Two adapters implement it — `ClaudeApiEngine` now, `CopilotCliEngine` in
/// Sprint 07 — and the contract suite (S03-CT-01) runs the same cases against
/// every one, so the domain cannot come to depend on a particular provider's
/// habits.
///
/// **Contract**
/// * [summarize] receives the transcript **already redacted** when the caller
///   is required to redact (BR-07). The engine does not redact for itself:
///   putting the rule in the use case means one implementation covers every
///   adapter, including ones written later.
/// * [summarize] returns a [MeetingSummary] whose `sections` are keyed by the
///   titles in `template.sections`, in that order. A section the meeting did
///   not cover is present with an empty body rather than absent — a missing
///   key would be indistinguishable from a parse that went wrong.
/// * `actionItems` is empty when `template.extractActionItems` is `false`, and
///   may be empty when it is `true`. Every returned item carries a non-empty
///   `id`, unique within the summary, and no `convertedTaskId`.
/// * **Errors are [Failure]s, never raw exceptions** (`docs/project-rules.md`
///   §6). Specifically: `MissingApiKeyFailure` when the user has configured no
///   key, `AiResponseFailure` when the answer cannot be read as a summary,
///   `AuthFailure` when a key is rejected, `RateLimitFailure`,
///   `TimeoutFailure`, `NetworkFailure`.
/// * The retry policy is **not** here. One malformed answer is retried by
///   `SummarizeMeeting`, which is the layer that knows the attempt is cheap
///   and the user is waiting (S03-UT-06).
abstract interface class AiEngine {
  /// Summarizes [transcript] under [template].
  ///
  /// `template.systemPrompt` is sent as the system message and the transcript
  /// as the user message — that split is what makes prompt caching possible,
  /// and it is asserted by S03-UT-03, so an adapter may not fold the two
  /// together for convenience.
  Future<MeetingSummary> summarize(String transcript, MeetingTemplate template);

  /// Parses [utterance] into a [VoiceIntent] (`docs/architecture.md` §6.2).
  ///
  /// [context] carries the situation the utterance was spoken in — the
  /// locale, the user's linked issue keys, and, on the second pass of a
  /// missing-slot exchange, the intent and slots already established.
  ///
  /// Promoted from `Future<String>` here in Sprint 05, which is the sprint
  /// that first has a caller able to act on the richer type (DEC-017). The
  /// shared `IntentCodec` does the reading, so every adapter returns an intent
  /// validated against the same schema (S05-CT-02).
  ///
  /// Throws [AiResponseFailure] when the answer cannot be read as an intent.
  /// It does **not** answer `IntentType.unknown` in that case: an unreadable
  /// answer and a model that understood nothing are different facts, and only
  /// `IntentParser` is entitled to collapse them.
  Future<VoiceIntent> parseIntent(String utterance, IntentContext context);

  /// Warms whatever the engine caches for [parseIntent], ahead of a real
  /// command.
  ///
  /// **Why the port has this at all.** The intent prompt is cached, and the
  /// first command of a session pays to *write* that cache: measured at
  /// 7406 ms against 2676–3160 ms for the four that read it. The user speaks
  /// their first command into the slowest request the app ever makes, and it
  /// is the one they judge the feature by.
  ///
  /// **Contract**
  /// * Best effort, and **never throws** — no key, no network, a rejected
  ///   request, all end the same way: quietly. A warm-up that can break a
  ///   session is worse than a cold cache (`sprint-05` report §7.4).
  /// * Changes nothing a caller can observe. An engine that caches nothing —
  ///   a local one, or `CopilotCliEngine` in Sprint 07 — satisfies this by
  ///   doing nothing at all.
  /// * Safe to call when one is already in flight, and safe to ignore the
  ///   returned future.
  Future<void> primeCache();

  /// What this engine supports. Constant for the life of the instance.
  AiCapabilities get capabilities;
}
