/// Provisional port declarations for the fakes whose real ports belong to a
/// later sprint (`sprint-00` deliverable 5).
///
/// Sprint 00 must not create domain entities (`Meeting`, `Task`, `VoiceIntent`
/// — see the sprint's "Out" scope and `docs/architecture.md` §11, where
/// `domain/entities/` is still empty), so the contracts below are expressed in
/// primitives and small transport records. Each one is promoted to
/// `lib/domain/ports/` — with its real entity types — in the sprint noted on it.
///
/// Ports that need nothing from the future already live in `domain/ports/`
/// (`Clock`, `NotificationScheduler`) and their fakes implement the real thing.
library;

/// What an AI engine can do — mirrors `docs/architecture.md` §7.1.
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
}

/// Provisional `AiEngine` — promoted in Sprint 03 (`summarize`) and Sprint 05
/// (`parseIntent`), once `MeetingSummary` and `VoiceIntent` exist.
abstract interface class AiEngine {
  /// Summarizes [transcript] under [systemPrompt]; returns the raw model text.
  Future<String> summarize(String transcript, String systemPrompt);

  /// Parses [utterance] into the intent JSON described in §6.2.
  Future<String> parseIntent(String utterance);

  AiCapabilities get capabilities;
}

/// The three fields the app is allowed to keep about a Jira issue (BR-09):
/// never a mirror of the ticket.
class JiraIssueSnapshot {
  const JiraIssueSnapshot({
    required this.issueKey,
    required this.siteUrl,
    required this.status,
  });

  final String issueKey;
  final String siteUrl;

  /// Display cache only — Jira remains the source of truth.
  final String status;
}

/// Provisional `JiraGateway` — promoted in Sprint 02.
abstract interface class JiraGateway {
  /// Reads the current snapshot of [issueKey].
  Future<JiraIssueSnapshot> fetchIssue(String issueKey);

  /// Moves [issueKey] to [status]. Idempotent by [operationId] (BR-05).
  Future<void> transition({
    required String issueKey,
    required String status,
    required String operationId,
  });

  /// Comments on [issueKey]. Idempotent by [operationId] (BR-05).
  Future<void> addComment({
    required String issueKey,
    required String body,
    required String operationId,
  });
}

/// Result of a batch transcription.
class Transcript {
  const Transcript({required this.text, required this.language});

  final String text;
  final String language;
}

/// A realtime transcription event — `partial` while the speaker is mid-phrase,
/// `committed` once VAD closes the segment (`docs/architecture.md` §9.3).
class TranscriptEvent {
  const TranscriptEvent({required this.text, required this.isCommitted});

  final String text;
  final bool isCommitted;
}

/// Provisional `BatchTranscription` — promoted in Sprint 04.
abstract interface class BatchTranscription {
  /// Transcribes the audio file at [path].
  Future<Transcript> transcribeFile(String path, {String? language});

  /// Progress in `0.0..1.0` for the file currently being transcribed.
  Stream<double> get progress;
}

/// Provisional `RealtimeTranscription` — promoted in Sprint 05.
abstract interface class RealtimeTranscription {
  /// Streams events for the PCM 16kHz mono audio in [pcm16k].
  Stream<TranscriptEvent> start(Stream<List<int>> pcm16k);

  /// Closes the session. Safe to call when no session is open.
  Future<void> stop();
}
