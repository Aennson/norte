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

// `JiraGateway` and `JiraIssueSnapshot` were promoted in Sprint 02, `AiEngine`
// and `AiCapabilities` in Sprint 03, and `BatchTranscription` with `Transcript`
// in Sprint 04 — all now live in `lib/domain/`, and their fakes implement the
// real ports. `AiEngine`'s `parseIntent` still returns raw text; it is promoted
// to `VoiceIntent` in Sprint 05, which is where that entity acquires a caller
// (DEC-017).
//
// `Transcript` was promoted **unchanged**, which is the useful thing to know
// about it: the provisional shape written in Sprint 00 without a caller turned
// out to be the shape Sprint 04 needed. `BatchTranscription` was promoted
// unchanged too, `String path` and all (DEC-021).

/// A realtime transcription event — `partial` while the speaker is mid-phrase,
/// `committed` once VAD closes the segment (`docs/architecture.md` §9.3).
class TranscriptEvent {
  const TranscriptEvent({required this.text, required this.isCommitted});

  final String text;
  final bool isCommitted;
}

/// Provisional `RealtimeTranscription` — promoted in Sprint 05.
abstract interface class RealtimeTranscription {
  /// Streams events for the PCM 16kHz mono audio in [pcm16k].
  Stream<TranscriptEvent> start(Stream<List<int>> pcm16k);

  /// Closes the session. Safe to call when no session is open.
  Future<void> stop();
}
