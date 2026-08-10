// Sprint 07's manual pass, made repeatable.
//
// The Definition of Done asks for three things against the **real** GitHub
// Copilot CLI on Windows: one summary, one intent parse, and one forced
// fallback. Every automated suite in this sprint replaces the child process
// with `FakeProcessRunner`; what no fake can answer is whether a real
// `Process.start` on a real machine behaves the way the fake says it does —
// whether the flags are accepted, whether the JSON is shaped as parsed, and
// whether a missing executable fails the way the chain expects.
//
// Run it from the repository root:
//
//     dart run tool/copilot_manual_pass.dart
//
// **It spends real Copilot requests** — three of them, two of which reach a
// model. That is the point, and it is why this is a script the Developer runs
// deliberately rather than a test CI runs on every push.
//
// **The transcript is the synthetic fixture** (`docs/testing-strategy.md` §3):
// invented people, invented complaints, no personal data. Nothing a real user
// wrote is sent anywhere by this file.
//
// The forced fallback uses a profile pointing at an executable that does not
// exist, rather than renaming the one that does. `Process.start` cannot tell
// the difference — both raise `ProcessException` before a child exists — and
// renaming a tool the Developer installed is a side effect a verification
// script has no business having.

import 'dart:io';

import 'package:norte/application/ai/ai_engine_selection.dart';
import 'package:norte/application/ai/fallback_ai_engine.dart';
import 'package:norte/domain/entities/intent_context.dart';
import 'package:norte/domain/entities/meeting.dart';
import 'package:norte/domain/entities/meeting_template.dart';
import 'package:norte/domain/entities/voice_intent.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/ai_engine.dart';
import 'package:norte/domain/ports/clock.dart';
import 'package:norte/infrastructure/ai/cli_ai_engine.dart';
import 'package:norte/infrastructure/ai/copilot_cli_engine.dart';
import 'package:norte/infrastructure/ai/process_runner.dart';

/// The retro transcript from `test/support/meeting_fixtures.dart`, repeated
/// here because `tool/` may not import from `test/`.
const String _transcript = '''
Ana: the outbox went out on Tuesday and nothing broke. Pairing on the
dispatcher is why the retry logic was right first time.
Bruno: agreed. My complaint is review latency — PR 41 sat for three days.
Ana: that is a staffing problem, not a notification problem.
Bruno: I do not think we agree on that. Leaving it open.
Ana: I will update the runbook.
Bruno: I will set up a review reminder in Slack before the fifteenth.
''';

Future<void> main() async {
  if (!Platform.isWindows) {
    stderr.writeln('This pass is Windows-only — the CLI engines are (§7.2).');
    exitCode = 1;
    return;
  }

  final MeetingTemplate retro = defaultMeetingTemplates.firstWhere(
    (MeetingTemplate template) => template.type == MeetingType.retro,
  );

  int failures = 0;
  void report(String step, bool ok, String detail) {
    stdout.writeln('${ok ? 'PASS' : 'FAIL'}  $step');
    stdout.writeln('      $detail');
    if (!ok) failures++;
  }

  final List<String> log = <String>[];
  CliAiEngine copilot({Duration? timeout}) => CopilotCliEngine(
    runner: const SystemProcessRunner(),
    clock: const _SystemClock(),
    isWindows: true,
    timeout: timeout ?? CliAiEngine.defaultTimeout,
    log: log.add,
  );

  // --- 1. one summary -------------------------------------------------
  try {
    final Stopwatch clock = Stopwatch()..start();
    final MeetingSummary summary = await copilot(
      // A real model reading a real prompt is slower than the 30s the app
      // allows for an intent; the summary is the one call worth waiting for.
      timeout: const Duration(minutes: 3),
    ).summarize(_transcript, retro);
    clock.stop();

    final bool shaped =
        summary.sections.keys.toList().toString() ==
        retro.sectionTitles.toString();
    report(
      'summary',
      shaped,
      '${clock.elapsed.inSeconds}s · sections '
          '${summary.sections.keys.join(', ')} · '
          '${summary.actionItems.length} action items · engine ${summary.engineId}',
    );
    for (final ActionItem item in summary.actionItems) {
      stdout.writeln('        - ${item.description}');
    }
  } on Failure catch (failure) {
    report('summary', false, '${failure.runtimeType}: ${failure.message}');
  }

  // --- 2. one intent parse --------------------------------------------
  try {
    final VoiceIntent intent =
        await copilot(timeout: const Duration(minutes: 2)).parseIntent(
          'cria tarefa revisar o PR do conector',
          const IntentContext(locale: 'pt-BR'),
        );
    // **The pass condition is the transport, not the model's diligence.** What
    // the DoD asks is that a real CLI produces an intent this app can read:
    // a type in the enum, a confidence in range, and a schema-valid object.
    //
    // Whether the *title slot* comes back filled is the model's business and
    // it varies — measured at roughly one run in three across three
    // consecutive passes, on identical input, with an identical confidence of
    // 0.95 each time. Copilot routes per request and does not say which model
    // answered an intent. An empty slot is a case the app already handles:
    // `IntentParser` asks the user for what is missing (S05-UT-05), which is
    // the whole reason `missingSlots` exists. Failing the manual pass on it
    // would be failing it for behaving as designed.
    report(
      'intent',
      intent.type == IntentType.createTask &&
          IntentType.values.contains(intent.type) &&
          intent.confidence >= 0 &&
          intent.confidence <= 1,
      '${intent.type.name} · slots ${intent.slots} · '
          'confidence ${intent.confidence} · '
          'missing ${intent.missingSlots.isEmpty ? 'none' : intent.missingSlots}',
    );
  } on Failure catch (failure) {
    report('intent', false, '${failure.runtimeType}: ${failure.message}');
  }

  // --- 3. the forced fallback -----------------------------------------
  //
  // The primary is a Copilot engine whose executable is not there. What is
  // being confirmed is that a real `Process.start` failure produces the same
  // `AiProcessFailure` the fake produces, that BR-10 then tries it exactly
  // twice, and that the switch is logged with its reason.
  log.clear();
  final _StubEngine stub = _StubEngine();
  final FallbackAiEngine chain = FallbackAiEngine(
    primary: NamedEngine(
      id: AiEngineSelection.copilotCliId,
      label: 'GitHub Copilot CLI',
      engine: CliAiEngine(
        runner: const SystemProcessRunner(),
        profile: _missingProfile,
        clock: const _SystemClock(),
        isWindows: true,
        log: log.add,
      ),
    ),
    fallback: NamedEngine(
      id: AiEngineSelection.claudeApiId,
      label: 'Claude API',
      engine: stub,
    ),
    fallbackEnabled: true,
    log: log.add,
  );

  try {
    await chain.parseIntent('cria tarefa qualquer', const IntentContext());
    final bool switched = log.any(
      (String line) =>
          line.contains('switching ${AiEngineSelection.copilotCliId}'),
    );
    report(
      'forced fallback',
      switched && stub.calls == 1,
      'primary attempts ${_attempts(log)} · fallback calls ${stub.calls} · '
          'switch logged: $switched',
    );
  } on Failure catch (failure) {
    report(
      'forced fallback',
      false,
      'the chain gave up: ${failure.runtimeType}: ${failure.message}',
    );
  }
  for (final String line in log) {
    stdout.writeln('        $line');
  }

  stdout.writeln(
    failures == 0 ? '\nAll three steps passed.' : '\n$failures failed.',
  );
  exitCode = failures == 0 ? 0 : 1;
}

/// How many times the primary was asked, read back out of the log.
int _attempts(List<String> log) =>
    log.where((String line) => line.contains('attempt')).length;

/// Copilot's profile, pointing at nothing.
const CliEngineProfile _missingProfile = CliEngineProfile(
  id: 'copilot-cli',
  label: 'GitHub Copilot CLI',
  executables: <String>['copilot-that-is-not-installed.cmd'],
  baseArguments: <String>[],
  promptFlag: '-p',
  modelFlag: '--model',
  knownModels: <String>[],
);

/// Stands in for the remote engine, which this script has no key for and no
/// business spending money on. It answers; that is all the chain needs.
class _StubEngine implements AiEngine {
  int calls = 0;

  @override
  AiCapabilities get capabilities => const AiCapabilities(
    isLocal: false,
    supportsStreaming: false,
    supportsPromptCache: false,
    maxTokens: 8192,
  );

  @override
  Future<MeetingSummary> summarize(String t, MeetingTemplate template) async {
    throw UnimplementedError('the fallback step only parses an intent');
  }

  @override
  Future<VoiceIntent> parseIntent(String u, IntentContext context) async {
    calls++;
    return const VoiceIntent(
      type: IntentType.createTask,
      slots: <String, dynamic>{'title': 'qualquer'},
      confidence: 0.9,
    );
  }

  @override
  Future<void> primeCache() async {}
}

class _SystemClock implements Clock {
  const _SystemClock();

  @override
  DateTime now() => DateTime.now();
}
