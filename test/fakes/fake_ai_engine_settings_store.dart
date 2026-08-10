import 'package:norte/domain/entities/ai_engine_settings.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/ai_engine_settings_store.dart';

/// In-memory [AiEngineSettingsStore] (`docs/testing-strategy.md` §3).
///
/// Constructed with the defaults — the remote engine, fallback on, no model
/// pinned — so a test that wants a CLI engine has to say so. Inheriting a
/// subprocess engine by accident is exactly the kind of quiet assumption the
/// strategy document asks fakes not to make.
///
/// [recordAnswer] goes through the same `increment` the real store uses rather
/// than a counter of its own: S07-E2E-01 asserts *which* engine's count moved,
/// and a fake that kept its own tally could agree with the caller while the
/// real store disagreed.
class FakeAiEngineSettingsStore implements AiEngineSettingsStore {
  FakeAiEngineSettingsStore([
    this.settings = const AiEngineSettings(),
    this.usage = const AiEngineUsage(),
  ]);

  AiEngineSettings settings;
  AiEngineUsage usage;

  /// Number of times [write] has been called.
  int writes = 0;

  /// Engine ids handed to [recordAnswer], in order.
  final List<String> recorded = <String>[];

  /// When set, every call throws it.
  Failure? failWith;

  @override
  Future<AiEngineSettings> read() async {
    _guard();
    return settings;
  }

  @override
  Future<void> write(AiEngineSettings value) async {
    _guard();
    writes++;
    settings = value;
  }

  @override
  Future<AiEngineUsage> readUsage() async {
    _guard();
    return usage;
  }

  @override
  Future<void> recordAnswer(String engineId) async {
    _guard();
    recorded.add(engineId);
    usage = usage.increment(engineId);
  }

  void _guard() {
    final Failure? failure = failWith;
    if (failure != null) throw failure;
  }
}
