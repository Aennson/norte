import 'package:flutter_test/flutter_test.dart';
import 'package:norte/presentation/voice/voice_latency_log.dart';

/// The latency instrumentation the sprint's validation rules require.
///
/// Not a documented sprint case — added under `docs/project-rules.md` §5.4.
/// The report quotes a p95, so the arithmetic behind that number is worth
/// pinning: a "percentile" that silently reported the mean would make the
/// sprint's own evidence meaningless.
///
/// Since Sprint 05a the number is also *attributed*, and attribution has its
/// own way of lying — a per-stage percentile read off the worst total, or an
/// unmeasured stage counted as a fast one, would name the wrong service to go
/// and optimise. Those two are pinned here as well.
void main() {
  /// A sample whose stages are given in milliseconds, for readability.
  VoiceLatencySample sample({int scribe = 0, int local = 0, int claude = 0}) =>
      VoiceLatencySample(
        transcription: Duration(milliseconds: scribe),
        grounding: Duration(milliseconds: local),
        parse: Duration(milliseconds: claude),
      );

  group('the percentile arithmetic', () {
    test('p95 is null until something has been measured', () {
      final VoiceLatencyLog log = VoiceLatencyLog();
      expect(log.p95PostCommit, isNull);
      expect(log.p95Total, isNull);
      expect(log.p95Transcription, isNull);
      expect(log.p95Parse, isNull);
    });

    test('p95 ignores a single outlier in twenty', () {
      final VoiceLatencyLog log = VoiceLatencyLog();
      for (int i = 0; i < 19; i++) {
        log.record(sample(claude: 200));
      }
      log.record(sample(claude: 4000));

      // One slow command in twenty is the 100th percentile, not the 95th, and
      // nearest-rank says so: `ceil(20 × 0.95) = 19`. A p95 that moved on a
      // single sample would be a maximum wearing a percentile's name.
      expect(log.p95PostCommit, const Duration(milliseconds: 200));
    });

    test('p95 catches a rate a mean would hide', () {
      final VoiceLatencyLog log = VoiceLatencyLog();
      // Two slow commands in twenty. The mean is 580ms and looks healthy; the
      // p95 is four seconds, which is what the user actually experienced.
      for (int i = 0; i < 18; i++) {
        log.record(sample(claude: 200));
      }
      log
        ..record(sample(claude: 4000))
        ..record(sample(claude: 4000));

      expect(log.p95PostCommit, const Duration(seconds: 4));
    });

    test('a single measurement is its own p95', () {
      final VoiceLatencyLog log = VoiceLatencyLog()
        ..record(sample(claude: 900));

      expect(log.p95PostCommit, const Duration(milliseconds: 900));
    });

    test('the window rolls rather than growing', () {
      final VoiceLatencyLog log = VoiceLatencyLog(capacity: 3);
      for (int i = 1; i <= 5; i++) {
        log.record(sample(claude: i * 100));
      }

      expect(log.count, 3);
      expect(log.samples.first.parse, const Duration(milliseconds: 300));
    });
  });

  group('the split', () {
    test('post-commit still means what Sprint 05 reported', () {
      // The 3973 ms in the report was commit → intent ready. Scribe's share was
      // never in it, so adding that share must not silently move the number
      // being compared against the < 3s target.
      final VoiceLatencySample one = sample(
        scribe: 1500,
        local: 30,
        claude: 2000,
      );

      expect(one.postCommit, const Duration(milliseconds: 2030));
      expect(one.total, const Duration(milliseconds: 3530));
    });

    test('each stage gets its own percentile, not the worst sample\'s', () {
      // The point of the split. The slowest command overall is not the one
      // with the slowest parse here: reading Claude's p95 off the worst total
      // would report 400ms and send a day of optimisation at the wrong half.
      final VoiceLatencyLog log = VoiceLatencyLog()
        ..record(sample(scribe: 3000, claude: 400))
        ..record(sample(scribe: 200, claude: 2500));

      expect(log.p95Transcription, const Duration(seconds: 3));
      expect(log.p95Parse, const Duration(milliseconds: 2500));
      expect(log.p95PostCommit, const Duration(milliseconds: 2500));
    });

    test('an unmeasured Scribe share is absent, never zero', () {
      // A typed slot answer has no partial to anchor on. Counting it as 0ms
      // would drag Scribe's percentile down with a command Scribe never
      // handled — the precise way an instrument talks its own subject out of
      // trouble.
      final VoiceLatencyLog log = VoiceLatencyLog()
        ..record(
          const VoiceLatencySample(
            grounding: Duration.zero,
            parse: Duration(milliseconds: 800),
          ),
        )
        ..record(sample(scribe: 1200, claude: 800));

      expect(log.p95Transcription, const Duration(milliseconds: 1200));
      expect(log.p95Parse, const Duration(milliseconds: 800));
      // The total is only defined where every stage was observed.
      expect(log.samples.first.total, isNull);
      expect(log.p95Total, const Duration(milliseconds: 2000));
    });

    test('the local share is measured rather than assumed small', () {
      // Grounding reads the task list to build the prompt's issue keys. It
      // ought to be negligible, and it has its own field so that "ought" is
      // checkable against a database that has grown.
      final VoiceLatencyLog log = VoiceLatencyLog()
        ..record(sample(scribe: 100, local: 900, claude: 100));

      expect(log.p95Grounding, const Duration(milliseconds: 900));
      expect(log.p95PostCommit, const Duration(seconds: 1));
    });
  });

  group('the diagnostics sink', () {
    test('every measurement is reported with all three shares named', () {
      final List<String> lines = <String>[];
      VoiceLatencyLog(
        sink: lines.add,
      ).record(sample(scribe: 850, local: 12, claude: 2400));

      expect(lines.single, contains('scribe 850ms'));
      expect(lines.single, contains('local 12ms'));
      expect(lines.single, contains('claude 2400ms'));
      // Durations only — no transcript, no intent, nothing that would need
      // redacting and nothing BR-06 could object to.
      expect(lines.single, isNot(contains('PROJ')));
    });

    test('an unmeasured share reads as unavailable, not as fast', () {
      final List<String> lines = <String>[];
      VoiceLatencyLog(sink: lines.add).record(
        const VoiceLatencySample(
          grounding: Duration.zero,
          parse: Duration(milliseconds: 700),
        ),
      );

      expect(lines.single, contains('scribe n/a'));
      expect(lines.single, isNot(contains('scribe 0ms')));
    });
  });
}
