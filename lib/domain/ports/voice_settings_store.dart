import '../entities/voice_settings.dart';

/// Storage for [VoiceSettings].
///
/// A preference, not a secret: it lives in the local database like any other
/// user data, and nothing here ever touches the secure store (BR-08 governs
/// keys, and there are none in this file).
///
/// **Contract**
/// * [read] returns the defaults when nothing has been stored — never `null`.
///   A first run and a run after a wipe behave identically, and both confirm
///   Jira writes.
/// * [write] replaces the stored settings whole.
/// * A storage error surfaces as a thrown `StorageFailure`.
///
/// **There is no `watch`.** The pipeline reads the settings at the moment it
/// needs them, which is both simpler and stricter than a stream: a stream has
/// a window — right after launch, before its first emission — in which a
/// reader sees the defaults rather than the user's choice. For a preference
/// whose default is "ask" that window is harmless, and for one whose default
/// were "do not ask" it would be a bug waiting to happen. Reading on demand
/// has no window at all.
abstract interface class VoiceSettingsStore {
  /// The stored settings, or the defaults.
  Future<VoiceSettings> read();

  /// Replaces the stored settings.
  Future<void> write(VoiceSettings settings);
}
