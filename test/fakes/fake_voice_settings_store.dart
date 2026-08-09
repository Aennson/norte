import 'package:norte/domain/entities/voice_settings.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/voice_settings_store.dart';

/// In-memory [VoiceSettingsStore] (`docs/testing-strategy.md` §3).
///
/// Constructed with the defaults, which means **confirming Jira writes** — a
/// test that wants the other behaviour has to ask for it in so many words,
/// and so cannot silently inherit a laxer setting than a real user has.
class FakeVoiceSettingsStore implements VoiceSettingsStore {
  FakeVoiceSettingsStore([this.settings = const VoiceSettings()]);

  VoiceSettings settings;

  /// Number of times [write] has been called.
  int writes = 0;

  /// When set, every call throws it.
  Failure? failWith;

  @override
  Future<VoiceSettings> read() async {
    _guard();
    return settings;
  }

  @override
  Future<void> write(VoiceSettings value) async {
    _guard();
    writes++;
    settings = value;
  }

  void _guard() {
    final Failure? failure = failWith;
    if (failure != null) throw failure;
  }
}
