import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/entities/intent_context.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/infrastructure/ai/claude_code_cli_engine.dart';
import 'package:norte/infrastructure/ai/cli_ai_engine.dart';
import 'package:norte/infrastructure/ai/copilot_cli_engine.dart';

import '../fakes/fakes.dart';
import '../support/fake_process_runner.dart';

/// One Copilot JSONL line carrying an assistant answer.
String copilotAnswer(String payload) => jsonEncode(<String, Object?>{
  'type': 'assistant.message',
  'data': <String, Object?>{'content': payload},
});

/// The bookkeeping Copilot really emits around an answer, taken from the
/// Sprint 07 manual pass. Present in the fixtures because the parser has to
/// step over it, and a fixture with only the payload would never prove that.
const List<String> copilotNoise = <String>[
  '{"type":"session.mcp_server_status_changed","data":{"status":"connected"}}',
  '{"type":"assistant.turn_start","data":{"turnId":"0"}}',
];

/// The trailer Copilot writes after the answer.
const String copilotResult = '{"type":"result","exitCode":0,"usage":{}}';

/// A valid intent, as `IntentCodec` reads one.
const String validIntent =
    '{"intent":"createTask","slots":{"title":"revisar o PR"},'
    '"confidence":0.91}';

void main() {
  final IntentContext context = IntentContext(locale: 'pt-BR');

  CliAiEngine copilot(FakeProcessRunner runner, {String? model}) =>
      CopilotCliEngine(
        runner: runner,
        clock: FakeClock(DateTime.utc(2026, 8, 10, 12)),
        isWindows: true,
        model: model,
      );

  group('S07-UT-03: timeout and watchdog', () {
    test(
      'S07-UT-03: a CLI that never answers fails at the deadline and is killed',
      () async {
        final FakeProcessRunner runner = FakeProcessRunner.always(
          () => FakeProcess(neverExits: true),
        );
        final CliAiEngine engine = CopilotCliEngine(
          runner: runner,
          clock: FakeClock(DateTime.utc(2026, 8, 10, 12)),
          isWindows: true,
          // Short, because the assertion is about the deadline being enforced
          // rather than about its length. Thirty seconds of real waiting in a
          // unit test would be thirty seconds on every CI run for ever.
          timeout: const Duration(milliseconds: 50),
        );

        await expectLater(
          engine.parseIntent('cria uma tarefa', context),
          throwsA(isA<AiTimeoutFailure>()),
        );

        // The half that matters. A timeout that returned without killing the
        // child would look identical from here and would leak one process per
        // failed request — the exact defect the sprint asks about.
        expect(runner.started.single.killed, isTrue);
      },
    );

    test('S07-UT-03: an answer inside the deadline is not killed', () async {
      final FakeProcessRunner runner = FakeProcessRunner.always(
        () => FakeProcess(stdout: <String>[copilotAnswer(validIntent)]),
      );

      await copilot(runner).parseIntent('cria uma tarefa', context);

      expect(runner.started.single.killed, isFalse);
    });
  });

  group('S07-UT-04: stdout parsing', () {
    test('S07-UT-04: a clean answer is read', () async {
      final FakeProcessRunner runner = FakeProcessRunner.always(
        () => FakeProcess(stdout: <String>[copilotAnswer(validIntent)]),
      );

      final intent = await copilot(
        runner,
      ).parseIntent('cria uma tarefa', context);

      expect(intent.slots['title'], 'revisar o PR');
    });

    test(
      'S07-UT-04: noise before and after the payload is stepped over',
      () async {
        final FakeProcessRunner runner = FakeProcessRunner.always(
          () => FakeProcess(
            stdout: <String>[
              // Not JSON at all — an update notice, which either CLI may print
              // on any day without that being a failure.
              'A new release of the CLI is available.',
              ...copilotNoise,
              copilotAnswer(validIntent),
              copilotResult,
            ],
          ),
        );

        final intent = await copilot(
          runner,
        ).parseIntent('cria uma tarefa', context);

        expect(intent.slots['title'], 'revisar o PR');
      },
    );

    test('S07-UT-04: empty output is AiProcessFailure', () async {
      final FakeProcessRunner runner = FakeProcessRunner.always(
        () => FakeProcess(stdout: const <String>[]),
      );

      await expectLater(
        copilot(runner).parseIntent('cria uma tarefa', context),
        throwsA(isA<AiProcessFailure>()),
      );
    });

    test(
      'S07-UT-04: a non-zero exit is AiProcessFailure carrying the code',
      () async {
        final FakeProcessRunner runner = FakeProcessRunner.always(
          () => FakeProcess(
            // Output *and* a bad exit code. An adapter that read stdout first
            // would answer happily from a process that failed.
            stdout: <String>[copilotAnswer(validIntent)],
            stderr: const <String>['not signed in'],
            exit: 1,
          ),
        );

        await expectLater(
          copilot(runner).parseIntent('cria uma tarefa', context),
          throwsA(
            isA<AiProcessFailure>().having(
              (AiProcessFailure f) => f.exitCode,
              'exitCode',
              1,
            ),
          ),
        );
      },
    );

    test(
      'S07-UT-04: an executable that will not start is AiProcessFailure',
      () async {
        await expectLater(
          copilot(FakeProcessRunner.missing()).parseIntent('cria', context),
          throwsA(isA<AiProcessFailure>()),
        );
      },
    );

    test("S07-UT-04: Claude Code's single JSON object is read too", () async {
      final FakeProcessRunner runner = FakeProcessRunner.always(
        () => FakeProcess(
          stdout: <String>[
            jsonEncode(<String, Object?>{
              'type': 'result',
              'subtype': 'success',
              'is_error': false,
              'result': validIntent,
            }),
          ],
        ),
      );

      final intent = await ClaudeCodeCliEngine(
        runner: runner,
        clock: FakeClock(DateTime.utc(2026, 8, 10, 12)),
        isWindows: true,
      ).parseIntent('cria uma tarefa', context);

      expect(intent.slots['title'], 'revisar o PR');
    });
  });

  group('S07-UT-05: unavailable on mobile', () {
    test('S07-UT-05: both CLI engines report unavailable off Windows', () {
      final FakeProcessRunner runner = FakeProcessRunner.always(
        FakeProcess.new,
      );
      final FakeClock clock = FakeClock(DateTime.utc(2026, 8, 10, 12));

      expect(
        CopilotCliEngine(
          runner: runner,
          clock: clock,
          isWindows: false,
        ).unavailable,
        isTrue,
      );
      expect(
        ClaudeCodeCliEngine(
          runner: runner,
          clock: clock,
          isWindows: false,
        ).unavailable,
        isTrue,
      );
      expect(
        CopilotCliEngine(
          runner: runner,
          clock: clock,
          isWindows: true,
        ).unavailable,
        isFalse,
      );
    });

    test('S07-UT-05: an unavailable engine starts no process at all', () async {
      final FakeProcessRunner runner = FakeProcessRunner.always(
        FakeProcess.new,
      );
      final CliAiEngine engine = CopilotCliEngine(
        runner: runner,
        clock: FakeClock(DateTime.utc(2026, 8, 10, 12)),
        isWindows: false,
      );

      await expectLater(
        engine.parseIntent('cria uma tarefa', context),
        throwsA(isA<AiProcessFailure>()),
      );
      // Reporting unavailable and then trying anyway would be worse than
      // either behaviour on its own.
      expect(runner.invocations, isEmpty);
    });
  });

  group('what the subprocess is given', () {
    test(
      'no secret reaches argv, and nothing is added to the environment',
      () async {
        final FakeProcessRunner runner = FakeProcessRunner.always(
          () => FakeProcess(stdout: <String>[copilotAnswer(validIntent)]),
        );

        await copilot(runner).parseIntent('cria uma tarefa', context);

        final ProcessInvocation call = runner.invocations.single;
        // The sprint's rule, asserted the only way it can be: nothing in the
        // command line looks like a credential, and the app contributes no
        // environment variables of its own — both CLIs hold their own login.
        expect(call.environment, isEmpty);
        for (final String argument in call.arguments) {
          expect(
            argument,
            isNot(matches(RegExp(r'gh[opsu]_|sk-ant-|github_pat_'))),
          );
        }
      },
    );

    test('the pinned model is passed, and its absence is not', () async {
      final FakeProcessRunner pinned = FakeProcessRunner.always(
        () => FakeProcess(stdout: <String>[copilotAnswer(validIntent)]),
      );
      await copilot(pinned, model: 'gpt-5-mini').parseIntent('cria', context);
      expect(
        pinned.invocations.single.arguments,
        containsAll(<String>['--model', 'gpt-5-mini']),
      );

      final FakeProcessRunner auto = FakeProcessRunner.always(
        () => FakeProcess(stdout: <String>[copilotAnswer(validIntent)]),
      );
      await copilot(auto).parseIntent('cria', context);
      expect(auto.invocations.single.arguments, isNot(contains('--model')));
    });

    test('Claude Code receives its prompt on stdin, Copilot in argv', () async {
      final FakeProcessRunner claudeCode = FakeProcessRunner.always(
        () => FakeProcess(
          // `jsonEncode`, not interpolation: the answer is a JSON *string*
          // holding JSON, and interpolating would nest it as an object — which
          // the codec cannot read and which no real CLI produces.
          stdout: <String>[
            jsonEncode(<String, Object?>{
              'type': 'result',
              'result': validIntent,
            }),
          ],
        ),
      );
      await ClaudeCodeCliEngine(
        runner: claudeCode,
        clock: FakeClock(DateTime.utc(2026, 8, 10, 12)),
        isWindows: true,
      ).parseIntent('cria uma tarefa', context);

      // The difference that decides how long a meeting can be: stdin has no
      // command-line ceiling and argv does.
      expect(claudeCode.invocations.single.stdin, contains('cria uma tarefa'));

      final FakeProcessRunner copilotRunner = FakeProcessRunner.always(
        () => FakeProcess(stdout: <String>[copilotAnswer(validIntent)]),
      );
      await copilot(copilotRunner).parseIntent('cria uma tarefa', context);
      expect(copilotRunner.invocations.single.stdin, isNull);
      expect(
        copilotRunner.invocations.single.arguments.last,
        contains('cria uma tarefa'),
      );
    });

    test(
      'an argv-delivered prompt over the ceiling is refused, not truncated',
      () async {
        final FakeProcessRunner runner = FakeProcessRunner.always(
          () => FakeProcess(stdout: <String>[copilotAnswer(validIntent)]),
        );

        await expectLater(
          copilot(
            runner,
          ).parseIntent('x' * (CliAiEngine.maxPromptChars + 1), context),
          throwsA(isA<ValidationFailure>()),
        );
        // Refusing means refusing. Starting the process and letting Windows cut
        // the command line is the failure mode this guard exists to prevent.
        expect(runner.invocations, isEmpty);
      },
    );
  });

  group('stderr is logged, and redacted first', () {
    test('a token in the CLI output never reaches the log', () async {
      final List<String> log = <String>[];
      final FakeProcessRunner runner = FakeProcessRunner.always(
        () => FakeProcess(
          stdout: <String>[copilotAnswer(validIntent)],
          stderr: const <String>[
            'auth failed for gho_ABCDEFGHIJKLMNOPQRSTUVWXYZ012345',
            'GITHUB_TOKEN=supersecretvalue',
          ],
        ),
      );

      await CopilotCliEngine(
        runner: runner,
        clock: FakeClock(DateTime.utc(2026, 8, 10, 12)),
        isWindows: true,
        log: log.add,
      ).parseIntent('cria uma tarefa', context);

      final String written = log.join('\n');
      expect(written, isNot(contains('gho_ABCDEFGHIJKLMNOPQRSTUVWXYZ012345')));
      expect(written, isNot(contains('supersecretvalue')));
      // The variable's *name* survives, because a log that cannot say which
      // credential leaked is no use for fixing it.
      expect(written, contains('GITHUB_TOKEN=<redacted>'));
    });
  });

  group('capabilities', () {
    test('isLocal is false on both CLI engines (DEC-037)', () {
      final FakeProcessRunner runner = FakeProcessRunner.always(
        FakeProcess.new,
      );
      final FakeClock clock = FakeClock(DateTime.utc(2026, 8, 10, 12));

      // The architecture document said `true`, on the grounds that a local
      // subprocess keeps data on the machine. It does not: the CLI is a client
      // for a server-side model. BR-07's redactor relaxation hangs off this
      // one boolean, so it is asserted rather than left to a comment.
      expect(
        CopilotCliEngine(
          runner: runner,
          clock: clock,
          isWindows: true,
        ).capabilities.isLocal,
        isFalse,
      );
      expect(
        ClaudeCodeCliEngine(
          runner: runner,
          clock: clock,
          isWindows: true,
        ).capabilities.isLocal,
        isFalse,
      );
    });

    test('primeCache does nothing and never throws', () async {
      final FakeProcessRunner runner = FakeProcessRunner.always(
        FakeProcess.new,
      );
      await copilot(runner).primeCache();
      // Spending a billed request to warm a cache that does not exist would be
      // worse than doing nothing, which is what the port permits.
      expect(runner.invocations, isEmpty);
    });
  });
}
