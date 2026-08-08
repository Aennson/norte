/// The deterministic test doubles listed in `docs/testing-strategy.md` §3.
///
/// Import this barrel from any test that needs a fake:
/// `import '../fakes/fakes.dart';`
library;

export 'fake_ai_engine.dart';
export 'fake_batch_transcription.dart';
export 'fake_clock.dart';
export 'fake_id_generator.dart';
export 'fake_jira_gateway.dart';
export 'fake_notification_scheduler.dart';
export 'fake_realtime_transcription.dart';
export 'ports/provisional_ports.dart';
