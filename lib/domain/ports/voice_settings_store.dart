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
/// * [watch] emits the current settings immediately and again after every
///   write, so a change in Settings reaches the voice pipeline without a
///   restart.
/// * A storage error surfaces as a thrown `StorageFailure`.
abstract interface class VoiceSettingsStore {
  /// The stored settings, or the defaults.
  Future<VoiceSettings> read();

  /// Replaces the stored settings.
  Future<void> write(VoiceSettings settings);

  /// Reactive view of the stored settings.
  Stream<VoiceSettings> watch();
}
