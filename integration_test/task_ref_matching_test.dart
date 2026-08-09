import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/infrastructure/persistence/drift_outbox_repository.dart';
import 'package:norte/infrastructure/persistence/drift_reminder_repository.dart';
import 'package:norte/infrastructure/persistence/drift_task_repository.dart';
import 'package:norte/infrastructure/persistence/drift_voice_settings_store.dart';
import 'package:norte/infrastructure/persistence/norte_database.dart';
import 'package:norte/infrastructure/persistence/norte_database_factory.dart';
import 'package:norte/l10n/generated/app_localizations.dart';
import 'package:norte/presentation/app/norte_app.dart';
import 'package:norte/presentation/app/norte_router.dart';
import 'package:norte/presentation/jira/jira_providers.dart';
import 'package:norte/presentation/meetings/meeting_providers.dart';
import 'package:norte/presentation/tasks/task_providers.dart';
import 'package:norte/presentation/voice/voice_button.dart';
import 'package:norte/presentation/voice/voice_providers.dart';
import 'package:norte/presentation/voice/widgets/confirm_sheet.dart';
import 'package:norte/presentation/voice/widgets/voice_overlay.dart';

import '../test/fakes/fake_ai_engine.dart';
import '../test/fakes/fake_clock.dart';
import '../test/fakes/fake_jira_gateway.dart';
import '../test/fakes/fake_microphone.dart';
import '../test/fakes/fake_realtime_transcription.dart';

/// S05b-E2E-01..02 — the Developer's session of 2026-08-09, through the real
/// app.
///
/// The defect this sprint exists for was found by a person speaking into the
/// real thing, and it survived a suite of unit tests because every one of them
/// used a `taskRef` spelled the way the fixture spelled the title. These two
/// run the whole composition root — the Drift database, the real router, the
/// real screens — with only the microphone and the two engines replaced.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final DateTime t0 = DateTime.utc(2026, 8, 9, 9, 30);

  late NorteDatabase database;
  late DriftTaskRepository tasks;
  late DriftOutboxRepository outbox;
  late DriftReminderRepository reminders;
  late DriftVoiceSettingsStore voiceSettings;
  late FakeAiEngine ai;
  late FakeRealtimeTranscription realtime;
  late FakeMicrophone microphone;
  late FakeJiraGateway jira;

  setUp(() {
    database = openInMemoryNorteDatabase();
    tasks = DriftTaskRepository(database);
    outbox = DriftOutboxRepository(database);
    reminders = DriftReminderRepository(database);
    voiceSettings = DriftVoiceSettingsStore(database);

    ai = FakeAiEngine(generatedAt: t0);
    realtime = FakeRealtimeTranscription()..autoplay = false;
    microphone = FakeMicrophone();
    jira = FakeJiraGateway.fromFixture();
  });

  tearDown(() async {
    await realtime.stop();
    await database.close();
  });

  Future<void> bootApp(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = <Locale>[const Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          taskRepositoryProvider.overrideWithValue(tasks),
          outboxRepositoryProvider.overrideWithValue(outbox),
          jiraGatewayProvider.overrideWithValue(jira),
          aiEngineProvider.overrideWithValue(ai),
          microphoneProvider.overrideWithValue(microphone),
          realtimeTranscriptionProvider.overrideWithValue(realtime),
          reminderRepositoryProvider.overrideWithValue(reminders),
          voiceSettingsStoreProvider.overrideWithValue(voiceSettings),
          clockProvider.overrideWithValue(FakeClock(t0)),
        ],
        child: NorteApp(
          router: buildNorteRouter(initialLocation: NorteRoutes.tasks),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> speakStart(WidgetTester tester) async {
    await tester.tap(find.byType(VoiceButton));
    await tester.pumpAndSettle();
  }

  Future<void> speak(
    WidgetTester tester,
    String partial,
    String committed,
  ) async {
    realtime.emitPartial(partial);
    await tester.pumpAndSettle();
    realtime.emitCommitted(committed);
    await tester.pumpAndSettle();
  }

  AppLocalizations l10nOf(WidgetTester tester) => AppLocalizations.of(
    tester.element(
      find.byType(ConfirmSheet).evaluate().isEmpty
          ? find.byType(VoiceOverlay).first
          : find.byType(ConfirmSheet).first,
    ),
  );

  /// The chamado as the tracker writes it, in progress, as it was on the day.
  Future<void> seedTheChamado() => tasks.save(
    Task(
      id: 'task-hero',
      title: 'HEROBRAZIL-762',
      status: TaskStatus.inProgress,
      createdAt: t0,
      updatedAt: t0,
    ),
  );

  group('S05b-E2E-01: the Developer\'s session, end to end', () {
    testWidgets(
      'S05b-E2E-01: "coloca a atividade Hero Brazil-762 para o status de '
      'pronto" closes HEROBRAZIL-762',
      (WidgetTester tester) async {
        // The parse was never the problem: Scribe heard the sentence and the
        // model read it correctly. What failed was the lookup, so the fake
        // returns exactly what the real model returned that day — the
        // reference spelled with the space a person says out loud.
        ai.alwaysParseAs(
          '{"intent":"updateTask","slots":{"taskRef":"Hero Brazil-762",'
          '"status":"done"},"confidence":0.94}',
        );
        await seedTheChamado();
        await bootApp(tester);
        await speakStart(tester);
        await speak(
          tester,
          'coloca a atividade Hero Brazil',
          'coloca a atividade Hero Brazil-762 para o status de pronto',
        );

        // What the app said on 2026-08-09 was "No task called 'Hero
        // Brazil-762'". What it says now names the row it changed.
        final AppLocalizations l10n = l10nOf(tester);
        expect(
          find.text(l10n.voiceTaskNotFound('Hero Brazil-762')),
          findsNothing,
        );
        expect(
          find.text(l10n.voiceDoneTaskUpdated('HEROBRAZIL-762')),
          findsOneWidget,
        );

        expect((await tasks.listAll()).single.status, TaskStatus.done);

        // And the card on the list agrees, which is where the user checks it.
        await tester.tap(find.byKey(VoiceOverlay.stopButtonKey));
        await tester.pumpAndSettle();
        expect(find.text('HEROBRAZIL-762'), findsOneWidget);
        // The badge shouts its status in caps (`docs/design-system.md` §4).
        expect(find.text(l10n.statusDone.toUpperCase()), findsWidgets);
      },
    );
  });

  group('S05b-E2E-02: deletion by an approximate reference still asks', () {
    testWidgets('S05b-E2E-02: the sheet appears at 0.98, names the title, and '
        'cancelling leaves the task', (WidgetTester tester) async {
      // "Brasil" for `BRAZIL` — a genuine transcription difference, so this
      // one resolves through tier 4. BR-04's threshold is a floor for a
      // deletion, not a gate: 0.98 asks exactly as 0.40 would.
      ai.alwaysParseAs(
        '{"intent":"deleteTask","slots":{"taskRef":"Hero Brasil-762"},'
        '"confidence":0.98}',
      );
      await seedTheChamado();
      await bootApp(tester);
      await speakStart(tester);
      await speak(
        tester,
        'apaga a atividade',
        'apaga a atividade Hero Brasil-762',
      );

      expect(find.byType(ConfirmSheet), findsOneWidget);
      expect(
        find.text(l10nOf(tester).voiceReasonDeletion),
        findsOneWidget,
        reason: 'the reason is irreversibility, not a doubtful parse',
      );
      // The title, not the phrase. An approximate resolution is precisely
      // when the user needs to see which row the app picked, and "Delete
      // Hero Brasil-762" would echo their own words back at them.
      expect(find.text('Delete HEROBRAZIL-762'), findsOneWidget);
      expect(find.text('Delete Hero Brasil-762'), findsNothing);

      await tester.tap(find.byKey(ConfirmSheet.cancelButtonKey));
      await tester.pumpAndSettle();

      final Task survivor = (await tasks.listAll()).single;
      expect(survivor.title, 'HEROBRAZIL-762');
      expect(survivor.status, TaskStatus.inProgress);
    });
  });
}
