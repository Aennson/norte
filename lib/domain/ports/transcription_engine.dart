import 'dart:typed_data';

import '../entities/transcript.dart';

/// How an engine consumes audio (`docs/architecture.md` §9.1).
///
/// Routing is fixed per use case rather than chosen by the user (§9.2), so this
/// exists to let a caller assert it got the engine it expected, not to let one
/// pick.
enum TranscriptionMode { batch, realtime }

/// Anything that turns speech into text (`docs/architecture.md` §9.1).
abstract interface class TranscriptionEngine {
  TranscriptionMode get mode;
}

/// Transcription of a finished audio file (`docs/architecture.md` §9.1).
///
/// `WhisperBatchEngine` implements it now; the contract suite (S04-CT-01) runs
/// the same cases against every implementation, including the fake, so a test
/// that passes against `FakeBatchTranscription` is testing the same contract
/// the app runs against.
///
/// **Contract**
/// * [transcribeFile] takes a **path**, not a `dart:io` `File`. The domain
///   stays free of platform types, which is what lets the use-case tests run
///   against a temporary directory without a plugin (DEC-021).
/// * The returned [Transcript] carries the engine's detected language, which
///   may differ from the [language] that was asked for.
/// * **Errors are [Failure]s, never raw exceptions** (`docs/project-rules.md`
///   §6). Specifically: `TranscriptionFailure` when the service fails or
///   answers with something unreadable, `AuthFailure` when the key is
///   rejected, `MissingApiKeyFailure` when there is no key at all,
///   `NotFoundFailure` when the path does not exist, plus `RateLimitFailure`,
///   `TimeoutFailure` and `NetworkFailure`.
/// * **The audio file is never deleted by the engine.** It is the caller's
///   file, and the sprint's retry-without-re-recording rule depends on it
///   surviving a failure — an engine that tidied up after itself would destroy
///   the one thing the retry needs (S04-UT-02).
abstract interface class BatchTranscription implements TranscriptionEngine {
  /// Transcribes the audio file at [path].
  ///
  /// [language] is a hint: given, it tells the engine what to expect and
  /// improves accuracy; omitted, the engine detects it.
  Future<Transcript> transcribeFile(String path, {String? language});

  /// Progress in `0.0..1.0` for the file currently being transcribed.
  ///
  /// A broadcast stream — the recording screen listens while the use case
  /// drives, and neither owns it. An engine that cannot report progress emits
  /// nothing rather than faking a curve; the UI shows an indeterminate stage,
  /// which is honest about not knowing.
  Stream<double> get progress;
}

/// One thing the engine heard (`docs/architecture.md` §9.3).
///
/// A `partial` is the engine's current best guess while the speaker is
/// mid-phrase and is replaced by the next one; a `committed` event closes the
/// segment once VAD decides the speaker stopped, and is the only kind anything
/// downstream may act on. [text] is always the **whole** segment so far, not
/// the delta — a consumer renders the latest event and never accumulates.
class TranscriptEvent {
  const TranscriptEvent({required this.text, required this.isCommitted});

  /// The segment as heard so far.
  final String text;

  /// `true` once VAD closed the segment and the text will not change again.
  final bool isCommitted;

  @override
  bool operator ==(Object other) =>
      other is TranscriptEvent &&
      other.text == text &&
      other.isCommitted == isCommitted;

  @override
  int get hashCode => Object.hash(text, isCommitted);

  @override
  String toString() =>
      'TranscriptEvent(${isCommitted ? 'committed' : 'partial'}: "$text")';
}

/// Live transcription of audio as it is spoken (`docs/architecture.md` §9.1).
///
/// `ScribeRealtimeEngine` implements it over a WebSocket; the contract suite
/// (S05-CT-01) runs the same event script against every implementation,
/// including `FakeRealtimeTranscription`, so a use-case test written against
/// the fake is testing the contract the app runs against.
///
/// **Contract**
/// * [start] consumes **PCM 16 kHz mono, signed 16-bit little-endian**. The
///   port takes bytes rather than a recorder because the domain must not know
///   what a microphone is; the composition root decides where they come from.
/// * The returned stream emits zero or more `partial`s followed by at most one
///   `committed` per segment, in that order, and closes when the session ends.
/// * **Errors are [Failure]s, never raw exceptions** (`docs/project-rules.md`
///   §6): `NetworkFailure` when the socket cannot be reached or is lost beyond
///   recovery, `AuthFailure` on a rejected key, `MissingApiKeyFailure` when
///   there is none, plus `RateLimitFailure` and `TimeoutFailure`.
/// * **BR-06 — no byte of audio is ever written to disk.** A reconnection may
///   hold speech in memory to replay it, and that buffer is capped at five
///   seconds; beyond it the oldest audio is dropped rather than spilled
///   anywhere. An adapter that persisted audio to survive a drop would trade
///   the one guarantee the user was given for a convenience.
/// * [stop] closes the session and is safe to call when none is open. No event
///   arrives after it.
abstract interface class RealtimeTranscription implements TranscriptionEngine {
  /// Opens a session and streams what it hears from [pcm16k].
  Stream<TranscriptEvent> start(Stream<Uint8List> pcm16k);

  /// Closes the session. Safe to call when no session is open.
  Future<void> stop();
}
