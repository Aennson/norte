import 'package:flutter_test/flutter_test.dart';
import 'package:norte/presentation/voice/voice_latency_log.dart';

/// The latency instrumentation the sprint's validation rules require.
///
/// Not a documented sprint case — added under `docs/project-rules.md` §5.4.
/// The report quotes a p95, so the arithmetic behind that number is worth
/// pinning: a "percentile" that silently reported the mean would make the
/// sprint's own evidence meaningless.
void main() {
  test('p95 is null until something has been measured', () {
    expect(VoiceLatencyLog().p95, isNull);
  });

  test('p95 ignores a single outlier in twenty', () {
    final VoiceLatencyLog log = VoiceLatencyLog();
    for (int i = 0; i < 19; i++) {
      log.record(const Duration(milliseconds: 200));
    }
    log.record(const Duration(seconds: 4));

    // One slow command in twenty is the 100th percentile, not the 95th, and
    // nearest-rank says so: `ceil(20 × 0.95) = 19`. A p95 that moved on a
    // single sample would be a maximum wearing a percentile's name.
    expect(log.p95, const Duration(milliseconds: 200));
  });

  test('p95 catches a rate a mean would hide', () {
    final VoiceLatencyLog log = VoiceLatencyLog();
    // Two slow commands in twenty. The mean is 580ms and looks healthy; the
    // p95 is four seconds, which is what the user actually experienced.
    for (int i = 0; i < 18; i++) {
      log.record(const Duration(milliseconds: 200));
    }
    log
      ..record(const Duration(seconds: 4))
      ..record(const Duration(seconds: 4));

    expect(log.p95, const Duration(seconds: 4));
  });

  test('a single measurement is its own p95', () {
    final VoiceLatencyLog log = VoiceLatencyLog()
      ..record(const Duration(milliseconds: 900));

    expect(log.p95, const Duration(milliseconds: 900));
  });

  test('the window rolls rather than growing', () {
    final VoiceLatencyLog log = VoiceLatencyLog(capacity: 3);
    for (int i = 1; i <= 5; i++) {
      log.record(Duration(milliseconds: i * 100));
    }

    expect(log.count, 3);
    expect(log.samples.first, const Duration(milliseconds: 300));
  });

  test('every measurement is reported to the diagnostics sink', () {
    final List<String> lines = <String>[];
    VoiceLatencyLog(sink: lines.add).record(const Duration(milliseconds: 850));

    expect(lines.single, contains('850ms'));
    // Durations only — no transcript, no intent, nothing that would need
    // redacting and nothing BR-06 could object to.
    expect(lines.single, isNot(contains('PROJ')));
  });
}
