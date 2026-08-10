import '../entities/ai_engine_settings.dart';

/// Storage for [AiEngineSettings] and [AiEngineUsage].
///
/// A preference and a counter, never a secret — the same reasoning as
/// `VoiceSettingsStore`, and nothing here goes near the secure store (BR-08).
///
/// **Contract**
/// * [read] and [readUsage] return the defaults when nothing has been stored,
///   never `null`. A first run and a run after a wipe behave identically.
/// * A stored value that cannot be read is treated as absent. The app must
///   start with an unreadable preference, because the alternative is an install
///   that will not open until someone edits a database by hand.
/// * [write] replaces the settings whole.
/// * [recordAnswer] raises one engine's count by one and is the **only** way
///   the counter moves. A caller cannot set it, so it cannot disagree with what
///   actually happened.
/// * A storage error surfaces as a thrown `StorageFailure`.
///
/// **Usage lives here rather than in memory** because the question it answers —
/// "which engine has been replying to me?" — is asked across sessions, and a
/// counter that resets on launch would answer it only for people who never
/// close the app.
abstract interface class AiEngineSettingsStore {
  /// The stored settings, or the defaults.
  Future<AiEngineSettings> read();

  /// Replaces the stored settings.
  Future<void> write(AiEngineSettings settings);

  /// The stored per-engine counts, or empty.
  Future<AiEngineUsage> readUsage();

  /// Raises [engineId]'s count by one.
  ///
  /// Called after an engine has answered, never before it is asked: the
  /// counter records answers, and an engine that failed and fell back has
  /// produced none (S07-E2E-01 asserts the increment lands on the engine that
  /// actually replied).
  Future<void> recordAnswer(String engineId);
}
