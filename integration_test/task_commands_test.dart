import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:norte/domain/entities/jira_link.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/domain/entities/task_comment.dart';
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

/// S05a-E2E-01..02 — the local task commands, through the real UI.
///
/// The real composition root with the microphone, the realtime engine and the
/// AI engine replaced (`docs/testing-strategy.md` §4.2). The database, the
/// outbox and the router are the app's own — which is what lets S05a-E2E-02
/// assert that a spoken note left the outbox empty on a task that *is* linked
/// to Jira.
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

  /// The localizations, read from whichever voice panel is on screen.
  ///
  /// The overlay and the confirmation sheet never coexist — a pending
  /// confirmation replaces the overlay — so looking only for the overlay threw
  /// exactly where the deletion test needed the wording.
  AppLocalizations l10nOf(WidgetTester tester) => AppLocalizations.of(
    tester.element(
      find.byType(ConfirmSheet).evaluate().isEmpty
          ? find.byType(VoiceOverlay).first
          : find.byType(ConfirmSheet).first,
    ),
  );

  Future<Task> only(WidgetTester tester) async =>
      (await tasks.listAll()).single;

  group('S05a-E2E-01: "cria a atividade Ligar para Samara…"', () {
    const String utterance =
        'cria a atividade Ligar para Samara, com a descrição confirmar o '
        'orçamento, em status em progresso, de prioridade crítica';

    testWidgets(
      'S05a-E2E-01: one utterance creates a task with all four attributes, '
      'and no sheet',
      (WidgetTester tester) async {
        ai.alwaysParseAs(
          '{"intent":"createTask","slots":{"title":"Ligar para Samara",'
          '"description":"confirmar o orçamento","status":"inProgress",'
          '"priority":"urgent"},"confidence":0.95}',
        );
        await bootApp(tester);
        await speakStart(tester);
        await speak(tester, 'cria a atividade Ligar', utterance);

        // A local intent at 0.95 is the user's own row: the Jira rule does not
        // reach it, and BR-04's threshold is comfortably clear.
        expect(find.byType(ConfirmSheet), findsNothing);
        expect(find.text(l10nOf(tester).voiceDoneTask), findsOneWidget);

        final Task created = await only(tester);
        expect(created.title, 'Ligar para Samara');
        expect(created.description, 'confirmar o orçamento');
        expect(created.status, TaskStatus.inProgress);
        expect(created.priority, Priority.urgent);

        // All four visible on the list, which is where the user checks them.
        await tester.tap(find.byKey(VoiceOverlay.stopButtonKey));
        await tester.pumpAndSettle();
        expect(find.text('Ligar para Samara'), findsOneWidget);
        expect(find.text('confirmar o orçamento'), findsOneWidget);
      },
    );
  });

  group('S05a-E2E-02: change, comment, then delete — one session', () {
    /// The three commands, in order, as the model would read them.
    void scriptTheSession() {
      ai
        ..scriptedIntents.add(
          '{"intent":"updateTask","slots":{"taskRef":"Ligar para Samara",'
          '"status":"done"},"confidence":0.93}',
        )
        ..scriptedIntents.add(
          '{"intent":"commentTask","slots":{"taskRef":"Ligar para Samara",'
          '"comment":"cliente retornou"},"confidence":0.91}',
        )
        ..scriptedIntents.add(
          '{"intent":"deleteTask","slots":{"taskRef":"Ligar para Samara"},'
          '"confidence":0.97}',
        );
    }

    Future<void> createTheTask(WidgetTester tester) async {
      await tasks.save(
        Task(
          id: 'task-samara',
          title: 'Ligar para Samara',
          createdAt: t0,
          updatedAt: t0,
        ),
      );
    }

    testWidgets(
      'S05a-E2E-02: status changed, note attached, deletion confirmed — '
      'without pressing the button again',
      (WidgetTester tester) async {
        scriptTheSession();
        await createTheTask(tester);
        await bootApp(tester);
        await speakStart(tester);

        // 1 — the change. DEC-031: the microphone stays open throughout.
        await speak(
          tester,
          'marca a tarefa',
          'marca a tarefa Ligar para Samara como concluída',
        );
        expect((await only(tester)).status, TaskStatus.done);
        // Sprint 05b: the outcome names the row it acted on.
        expect(
          find.text(l10nOf(tester).voiceDoneTaskUpdated('Ligar para Samara')),
          findsOneWidget,
        );
        expect(microphone.closes, 0);

        // 2 — the note. It lands on the user's own row and nowhere else.
        await speak(
          tester,
          'comenta na tarefa',
          'comenta na tarefa Ligar para Samara: cliente retornou',
        );
        final Task commented = await only(tester);
        expect(commented.comments.map((TaskComment c) => c.body), <String>[
          'cliente retornou',
        ]);
        expect(
          find.text(l10nOf(tester).voiceDoneTaskCommented('Ligar para Samara')),
          findsOneWidget,
        );
        expect(microphone.opens, 1, reason: 'one session, three commands');

        // 3 — the deletion, which asks even at 0.97.
        await speak(
          tester,
          'apaga a tarefa',
          'apaga a tarefa Ligar para Samara',
        );
        expect(find.byType(ConfirmSheet), findsOneWidget);
        expect(
          find.text(l10nOf(tester).voiceReasonDeletion),
          findsOneWidget,
          reason: 'the reason is irreversibility, not a doubtful parse',
        );
        // The sheet names the row, not the phrase.
        expect(find.text('Delete Ligar para Samara'), findsOneWidget);
        expect(await tasks.listAll(), hasLength(1));

        await tester.tap(find.byKey(ConfirmSheet.confirmButtonKey));
        await tester.pumpAndSettle();

        expect(await tasks.listAll(), isEmpty);
      },
    );

    testWidgets(
      'S05a-E2E-02 (B): cancelling the deletion leaves the task, its status '
      'and its note',
      (WidgetTester tester) async {
        scriptTheSession();
        await createTheTask(tester);
        await bootApp(tester);
        await speakStart(tester);

        await speak(tester, 'marca', 'marca a tarefa Ligar para Samara');
        await speak(tester, 'comenta', 'comenta na tarefa Ligar para Samara');
        await speak(tester, 'apaga', 'apaga a tarefa Ligar para Samara');

        await tester.tap(find.byKey(ConfirmSheet.cancelButtonKey));
        await tester.pumpAndSettle();

        // Nothing ran, so there is nothing to undo — and the two commands that
        // did run before it are untouched.
        final Task survivor = await only(tester);
        expect(survivor.status, TaskStatus.done);
        expect(survivor.comments.single.body, 'cliente retornou');
      },
    );

    testWidgets(
      'S05a-E2E-02 (C): the note stays local even on a task linked to Jira',
      (WidgetTester tester) async {
        // BR-01, end to end. The task is linked, so a router that conflated
        // `commentTask` with `addComment` would have queued something here —
        // and the whole team would read a note the user meant for themselves.
        ai.alwaysParseAs(
          '{"intent":"commentTask","slots":{"taskRef":"conector",'
          '"comment":"revisar amanhã"},"confidence":0.9}',
        );
        await tasks.save(
          Task(
            id: 'task-linked',
            title: 'revisar o conector',
            createdAt: t0,
            updatedAt: t0,
            jiraLink: const JiraLink(
              issueKey: 'PROJ-123',
              siteUrl: 'https://example.atlassian.net',
            ),
          ),
        );
        await bootApp(tester);
        await speakStart(tester);
        await speak(
          tester,
          'comenta na tarefa',
          'comenta na tarefa do conector: revisar amanhã',
        );

        expect((await only(tester)).comments.single.body, 'revisar amanhã');
        expect(await outbox.pending(t0), isEmpty);
        expect(jira.writes, isEmpty);
      },
    );
  });
}
