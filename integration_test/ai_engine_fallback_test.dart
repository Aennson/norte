import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:norte/application/ai/ai_engine_selection.dart';
import 'package:norte/domain/entities/ai_engine_settings.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/ai_engine.dart';
import 'package:norte/infrastructure/ai/copilot_cli_engine.dart';
import 'package:norte/infrastructure/persistence/drift_meeting_repository.dart';
import 'package:norte/infrastructure/persistence/drift_meeting_template_repository.dart';
import 'package:norte/infrastructure/persistence/drift_task_repository.dart';
import 'package:norte/infrastructure/persistence/norte_database.dart';
import 'package:norte/infrastructure/persistence/norte_database_factory.dart';
import 'package:norte/presentation/app/norte_app.dart';
import 'package:norte/presentation/app/norte_router.dart';
import 'package:norte/presentation/meetings/meeting_providers.dart';
import 'package:norte/presentation/meetings/meetings_screen.dart';
import 'package:norte/presentation/meetings/new_meeting_screen.dart';
import 'package:norte/presentation/meetings/summary_screen.dart';
import 'package:norte/presentation/settings/ai_engine_providers.dart';
import 'package:norte/presentation/tasks/task_providers.dart';

import '../test/fakes/fake_ai_engine.dart';
import '../test/fakes/fake_ai_engine_settings_store.dart';
import '../test/fakes/fake_clock.dart';
import '../test/support/cli_fixtures.dart';
import '../test/support/fake_process_runner.dart';
import '../test/support/meeting_fixtures.dart';

/// S07-E2E-01 and S07-E2E-02 — BR-10 as the user meets it.
///
/// **Nothing here overrides `aiEngineProvider`.** Every other E2E suite hands
/// the app one finished engine, which is the right shape when the engine is not
/// what is under test. Here it is: the chain is the subject, so the overrides
/// stop at the pieces the composition root overrides — the platform, the
/// settings store, the remote engine and the two CLI builders — and
/// `AiEngineSelection.resolve` assembles the same `FallbackAiEngine` production
/// assembles. An E2E that injected a pre-built chain would prove the chain works
/// and say nothing about whether the app builds it.
///
/// **The CLI engine is real; only its child process is fake.** The primary in
/// E2E-01 is an actual `CopilotCliEngine` over a `FakeProcessRunner` whose
/// process never exits, so what ends the first two attempts is the real
/// watchdog — the same code path a CLI stuck on a login prompt takes on a user's
/// machine.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final DateTime t0 = DateTime.utc(2026, 8, 10, 9, 30);

  late NorteDatabase database;
  late DriftTaskRepository tasks;
  late DriftMeetingRepository meetings;
  late DriftMeetingTemplateRepository templates;
  late FakeAiEngineSettingsStore store;
  late FakeAiEngine remote;
  late FakeProcessRunner cliRunner;
  late List<String> log;

  setUp(() async {
    database = openInMemoryNorteDatabase();
    tasks = DriftTaskRepository(database);
    meetings = DriftMeetingRepository(database);
    templates = DriftMeetingTemplateRepository(database);
    await templates.seedDefaults();

    remote = FakeAiEngine(generatedAt: t0);
    log = <String>[];
    store = FakeAiEngineSettingsStore(
      // The configuration the scenario names: a CLI engine chosen, and the
      // fallback the user has left on.
      const AiEngineSettings(engine: EnginePref.copilotCli),
    );
  });

  tearDown(() => database.close());

  /// Boots the app with the engine chain assembled the way the root assembles
  /// it. [cliProcess] is what the CLI's child process does.
  Future<void> bootApp(
    WidgetTester tester, {
    required FakeProcess Function() cliProcess,
  }) async {
    tester.platformDispatcher.localesTestValue = <Locale>[const Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    cliRunner = FakeProcessRunner.always(cliProcess);

    AiEngine buildCli(String? model) => CopilotCliEngine(
      runner: cliRunner,
      clock: FakeClock(t0),
      isWindows: true,
      model: model,
      // Short, because the assertion is that the deadline is enforced, not how
      // long it is. Thirty real seconds twice over would be a minute added to
      // every CI run for ever, and S07-UT-03 already pins the real value.
      timeout: const Duration(milliseconds: 80),
      log: log.add,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          taskRepositoryProvider.overrideWithValue(tasks),
          meetingRepositoryProvider.overrideWithValue(meetings),
          meetingTemplateRepositoryProvider.overrideWithValue(templates),
          clockProvider.overrideWithValue(FakeClock(t0)),
          // The app "as Windows" — the one place the platform is decided.
          isWindowsProvider.overrideWithValue(true),
          aiEngineSettingsStoreProvider.overrideWithValue(store),
          remoteAiEngineProvider.overrideWithValue(remote),
          copilotCliBuilderProvider.overrideWithValue(buildCli),
          claudeCodeCliBuilderProvider.overrideWithValue(buildCli),
          aiEngineLogProvider.overrideWithValue(log.add),
        ],
        child: NorteApp(
          router: buildNorteRouter(initialLocation: NorteRoutes.meetings),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Opens the composer and fills it in, without processing.
  Future<void> fillForm(WidgetTester tester) async {
    await tester.tap(find.byKey(MeetingsScreen.newMeetingButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('meeting.template.builtin.retro')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(NewMeetingScreen.titleFieldKey),
      'Sprint 12 retro',
    );
    await tester.enterText(
      find.byKey(NewMeetingScreen.transcriptFieldKey),
      retroTranscript,
    );
    await tester.pumpAndSettle();
  }

  String transcriptInField(WidgetTester tester) => tester
      .widget<TextField>(
        find.descendant(
          of: find.byKey(NewMeetingScreen.transcriptFieldKey),
          matching: find.byType(TextField),
        ),
      )
      .controller!
      .text;

  testWidgets(
    'S07-E2E-01: the chosen engine hangs, the summary arrives anyway',
    (WidgetTester tester) async {
      // The Copilot CLI never answers — what a tool stuck on an expired login
      // does — and the remote engine is fine.
      remote.alwaysAnswer(summaryFixture('retro.json'));
      await bootApp(tester, cliProcess: () => FakeProcess(neverExits: true));
      await fillForm(tester);

      await tester.tap(find.byKey(NewMeetingScreen.processButtonKey));
      await tester.pumpAndSettle();

      // **The summary appears, and nothing apologises for it.** This is the
      // whole design goal of BR-10: the user asked for a summary and got one.
      expect(find.byType(SummaryScreen), findsOneWidget);
      expect(find.text('What went well'), findsOneWidget);
      expect(find.byKey(NewMeetingScreen.retryButtonKey), findsNothing);
      expect(
        find.text(
          'No AI engine could answer. '
          'Check the AI engine section in Settings.',
        ),
        findsNothing,
      );
      expect(find.text('Summarizing failed. Try again.'), findsNothing);

      // The exact sequence BR-10 specifies: the primary twice, then the
      // fallback once.
      expect(cliRunner.invocations, hasLength(2));
      expect(remote.calls, hasLength(1));
      // And the watchdog, not a lucky exit, is what ended each attempt.
      expect(
        cliRunner.started.every((FakeProcess process) => process.killed),
        isTrue,
      );

      // **The switch is in the log, with its reason.** The sprint's validation
      // rule, and the only way a user can discover that the engine they picked
      // is not the one that replied — since the point above is that they
      // cannot tell from the screen.
      final String written = log.join('\n');
      expect(
        written,
        contains(
          'switching ${AiEngineSelection.copilotCliId} → '
          '${AiEngineSelection.claudeApiId}',
        ),
      );
      expect(written, contains('AiTimeoutFailure'));

      // **The counter moved on the engine that answered, not the one chosen.**
      // A counter that credited the preference would make the fallback
      // invisible in the one place it is meant to be visible.
      expect(store.recorded, <String>[AiEngineSelection.claudeApiId]);
      expect(store.usage.of(AiEngineSelection.claudeApiId), 1);
      expect(store.usage.of(AiEngineSelection.copilotCliId), isZero);
    },
  );

  testWidgets('S07-E2E-01: a CLI that answers is never fallen back from', (
    WidgetTester tester,
  ) async {
    // The control for the scenario above. If the chain fell back whenever a
    // CLI engine was chosen, every assertion in the first test would still
    // pass and the feature would be broken.
    await bootApp(
      tester,
      cliProcess: () => FakeProcess(
        stdout: <String>[
          ...copilotNoise,
          copilotAnswer(summaryFixture('retro.json')),
          copilotResult,
        ],
      ),
    );
    await fillForm(tester);

    await tester.tap(find.byKey(NewMeetingScreen.processButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(SummaryScreen), findsOneWidget);
    expect(cliRunner.invocations, hasLength(1));
    expect(remote.calls, isEmpty);
    expect(store.recorded, <String>[AiEngineSelection.copilotCliId]);
    expect(log.join('\n'), isNot(contains('switching')));
  });

  testWidgets('S07-E2E-02: both engines down says so, and keeps the paste', (
    WidgetTester tester,
  ) async {
    // The CLI will not start at all — the shape of a renamed or uninstalled
    // executable, which is how the sprint's manual pass forces this path — and
    // the remote engine has no key.
    remote.failWith = const MissingApiKeyFailure();
    await bootApp(tester, cliProcess: () => throw const ProcessException());
    await fillForm(tester);

    await tester.tap(find.byKey(NewMeetingScreen.processButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(SummaryScreen), findsNothing);
    expect(find.byType(NewMeetingScreen), findsOneWidget);

    // **Actionable, and specific to the situation.** Until Sprint 07 wired
    // `AiUnavailableFailure` up, this fell through to "Summarizing failed. Try
    // again." — advice that cannot work, because by this point the app has
    // already tried everything it has.
    expect(
      find.text(
        'No AI engine could answer. '
        'Check the AI engine section in Settings.',
      ),
      findsOneWidget,
    );
    expect(find.text('Summarizing failed. Try again.'), findsNothing);

    // Both were tried, in the BR-10 sequence, and both are named in the log.
    expect(cliRunner.invocations, hasLength(2));
    expect(remote.calls, hasLength(1));
    expect(
      log.join('\n'),
      contains('${AiEngineSelection.claudeApiId} failed too'),
    );

    // **The transcript is still in the field, and retry is one tap.** The same
    // assertion S03-E2E-02 makes, and it has to survive a failure that now
    // arrives from two engines deep in a chain.
    expect(transcriptInField(tester), retroTranscript);
    expect(find.byKey(NewMeetingScreen.retryButtonKey), findsOneWidget);

    // Nothing was persisted by a run that failed (BR-03).
    expect(await meetings.listAll(), isEmpty);
    // And nothing was counted. The counter records answers, not attempts.
    expect(store.recorded, isEmpty);

    // --- try again, with the remote engine working ----------------------
    remote
      ..failWith = null
      ..alwaysAnswer(summaryFixture('retro.json'));
    await tester.tap(find.byKey(NewMeetingScreen.retryButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(SummaryScreen), findsOneWidget);
    expect(find.text('What went well'), findsOneWidget);
    expect(store.recorded, <String>[AiEngineSelection.claudeApiId]);
  });

  testWidgets('S07-E2E-02: with the fallback off, the failure is the CLI\'s', (
    WidgetTester tester,
  ) async {
    // The user who turned the fallback off did so to be told when their engine
    // fails. BR-10 scenario D, seen from the screen: the remote engine is
    // healthy and is still never asked.
    store.settings = const AiEngineSettings(
      engine: EnginePref.copilotCli,
      fallbackEnabled: false,
    );
    remote.alwaysAnswer(summaryFixture('retro.json'));
    await bootApp(tester, cliProcess: () => throw const ProcessException());
    await fillForm(tester);

    await tester.tap(find.byKey(NewMeetingScreen.processButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(SummaryScreen), findsNothing);
    expect(
      find.text(
        'No AI engine could answer. '
        'Check the AI engine section in Settings.',
      ),
      findsOneWidget,
    );
    // Untouched, not merely unsuccessful. An engine that is asked and fails has
    // still spent the user's money.
    expect(remote.calls, isEmpty);
    expect(log.join('\n'), contains('disabled by the user'));
    expect(transcriptInField(tester), retroTranscript);
  });
}
