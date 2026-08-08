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
