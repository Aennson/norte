import 'package:flutter_test/flutter_test.dart';
import 'package:norte/application/usecases/summarize_meeting.dart';
import 'package:norte/domain/entities/meeting.dart';
import 'package:norte/domain/failures/result.dart';
import 'package:norte/domain/ports/ai_engine.dart';
import 'package:norte/domain/services/pii_redactor.dart';
import 'package:norte/infrastructure/ai/claude_code_cli_engine.dart';
import 'package:norte/infrastructure/ai/cli_ai_engine.dart';
import 'package:norte/infrastructure/ai/copilot_cli_engine.dart';

import '../fakes/fake_ai_engine.dart';
import '../fakes/fake_clock.dart';
import '../fakes/fake_id_generator.dart';
import '../support/cli_fixtures.dart';
import '../support/fake_process_runner.dart';
import '../support/meeting_fixtures.dart';

/// S07-IT-01 — BR-07 across the CLI engines, end to end through the subprocess.
///
/// **The sprint's exit criteria were re-read under DEC-037, not met as
/// printed.** As written, this test asks for three scenarios, and the middle one
/// — *"off + local → CPF passes intact"* — describes a state this app can no
/// longer reach. The sprint was planned on `architecture.md` saying a CLI
/// engine is local inference; the CLI was then installed and run, and it
/// answered with a server-chosen model against a billed request. DEC-037 set
/// `isLocal = false` on every CLI engine, which means BR-07's relaxation never
/// applies to one, and the setting that would have disabled the redactor is
/// therefore not offered anywhere in the app. Implementing the scenario as
/// printed would have required inventing the setting *and* lying about
/// `isLocal`, and the pair of them would have shipped a CPF to a remote model.
///
/// What is asserted instead, keeping the ID:
///
/// 1. A CPF reaches the CLI engine **redacted** — the sprint's first scenario,
///    unchanged.
/// 2. It reaches it redacted **whichever way the prompt is delivered**, argv or
///    stdin, because the two CLIs differ there and a rule that held for only one
///    of them would be worse than no rule.
/// 3. **No setting changes that**, because the branch that would is conditioned
///    on `isLocal` and no engine that ships in v1.0 reports `true`. The branch
///    is shown to be live — a genuinely local engine does receive raw text —
///    so what is asserted is that it is unreachable, not that it is absent.
///
/// This is an integration test rather than a unit one because the assertion is
/// about what crosses the process boundary: the use case redacts, the adapter
/// builds a command line, and the check is made on the bytes the child was
/// actually handed. A test that stopped at `engine.lastTranscript` would pass
/// while the adapter appended the raw transcript to argv.
void main() {
  final DateTime now = DateTime.utc(2026, 8, 10, 12);

  /// The Copilot JSONL for a valid retro summary, with real bookkeeping around
  /// it so the parse is the one production performs.
  List<String> copilotStdout() => <String>[
    ...copilotNoise,
    copilotAnswer(summaryFixture('retro.json')),
    copilotResult,
  ];

  SummarizeMeeting through(AiEngine engine) => SummarizeMeeting(
    engine: engine,
    clock: FakeClock(now),
    idGenerator: FakeIdGenerator.sequence(<String>['meeting-1']),
  );

  group('S07-IT-01: a CPF never reaches a CLI engine', () {
    test('S07-IT-01: Copilot receives the transcript redacted, in argv',
        () async {
      final FakeProcessRunner runner = FakeProcessRunner.always(
        () => FakeProcess(stdout: copilotStdout()),
      );

      final Result<Meeting> result = await through(
        CopilotCliEngine(
          runner: runner,
          clock: FakeClock(now),
          isWindows: true,
        ),
      )(
        transcript: transcriptWithPii,
        template: retroTemplate,
        title: 'Retro',
      );

      expect(result.isOk, isTrue);

      // What the child process was handed — the command line itself, which on
      // Windows is also what shows up in the process list.
      final String sent = runner.invocations.single.prompt;
      expect(sent, isNot(contains('123.456.789-09')));
      expect(sent, isNot(contains('12345678909')));
      expect(sent, contains(PiiRedactor.cpfMask));
      // The whole of BR-07, not only the CPF the sprint names.
      expect(const PiiRedactor().containsPii(sent), isFalse);
    });

    test('S07-IT-01: Claude Code receives it redacted too, on stdin', () async {
      final FakeProcessRunner runner = FakeProcessRunner.always(
        () => FakeProcess(
          stdout: <String>[claudeCodeAnswer(summaryFixture('retro.json'))],
        ),
      );

      final Result<Meeting> result = await through(
        ClaudeCodeCliEngine(
          runner: runner,
          clock: FakeClock(now),
          isWindows: true,
        ),
      )(
        transcript: transcriptWithPii,
        template: retroTemplate,
        title: 'Retro',
      );

      expect(result.isOk, isTrue);

      // The other delivery path. `promptOnStdin` exists so a long meeting is
      // not truncated by the command-line ceiling, and it would be an easy
      // place to lose the redaction, because nothing about stdin looks like
      // the argv the rule was first written about.
      final ProcessInvocation call = runner.invocations.single;
      expect(call.stdin, isNotNull);
      expect(call.stdin, isNot(contains('123.456.789-09')));
      expect(const PiiRedactor().containsPii(call.stdin!), isFalse);
      // And nothing leaked into argv on the way past.
      expect(call.arguments.join(' '), isNot(contains('123.456.789-09')));
    });

    test(
      'S07-IT-01: the raw transcript is still what the meeting keeps',
      () async {
        final FakeProcessRunner runner = FakeProcessRunner.always(
          () => FakeProcess(stdout: copilotStdout()),
        );

        final Result<Meeting> result = await through(
          CopilotCliEngine(
            runner: runner,
            clock: FakeClock(now),
            isWindows: true,
          ),
        )(
          transcript: transcriptWithPii,
          template: retroTemplate,
          title: 'Retro',
        );

        // Redaction is what the *engine* is shown, not what the user loses.
        // A rule that quietly rewrote the user's own transcript would be a
        // data-loss bug wearing a privacy rule's clothes.
        expect((result as Ok<Meeting>).value.rawTranscript,
            contains('123.456.789-09'));
      },
    );
  });

  group('S07-IT-01: no setting can relax it for a CLI engine', () {
    test('S07-IT-01: both CLI engines report isLocal false (DEC-037)', () {
      final FakeProcessRunner runner = FakeProcessRunner.always(FakeProcess.new);
      final FakeClock clock = FakeClock(now);

      for (final CliAiEngine engine in <CliAiEngine>[
        CopilotCliEngine(runner: runner, clock: clock, isWindows: true),
        ClaudeCodeCliEngine(runner: runner, clock: clock, isWindows: true),
      ]) {
        // The single boolean the relaxation hangs off. The sprint planned for
        // it to be `true`; running the CLI proved otherwise.
        expect(engine.capabilities.isLocal, isFalse);
      }
    });

    test(
      'S07-IT-01: the relaxation branch is live, and no shipped engine '
      'reaches it',
      () async {
        // Proving the negative honestly. If the use case simply never passed
        // raw text to anyone, the assertions above would hold for a completely
        // different reason and would keep holding if BR-07 were deleted.
        final FakeAiEngine local = FakeAiEngine(
          capabilities: const AiCapabilities(
            isLocal: true,
            supportsStreaming: false,
            supportsPromptCache: false,
            maxTokens: 8192,
          ),
        )..alwaysAnswer(summaryFixture('retro.json'));

        await through(local)(
          transcript: transcriptWithPii,
          template: retroTemplate,
          title: 'Retro',
        );

        // The branch works: a genuinely local engine is given the raw text.
        expect(local.lastTranscript, contains('123.456.789-09'));

        // And nothing the user can select is such an engine. There is no
        // setting to check because there is no setting: the condition is a
        // property of the adapter, not a preference.
        final FakeProcessRunner runner = FakeProcessRunner.always(
          FakeProcess.new,
        );
        final FakeClock clock = FakeClock(now);
        expect(
          <bool>[
            CopilotCliEngine(
              runner: runner,
              clock: clock,
              isWindows: true,
            ).capabilities.isLocal,
            ClaudeCodeCliEngine(
              runner: runner,
              clock: clock,
              isWindows: true,
            ).capabilities.isLocal,
          ],
          everyElement(isFalse),
        );
      },
    );
  });
}
