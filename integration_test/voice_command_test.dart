import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:norte/domain/entities/jira_link.dart';
import 'package:norte/domain/entities/outbox_operation.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/domain/entities/voice_settings.dart';
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

/// S05-E2E-01..03 — voice commands, through the real UI.
///
/// The complete third pillar driven the way a user drives it: the real
/// composition root with the microphone, the realtime engine and the AI engine
/// replaced (`docs/testing-strategy.md` §4.2). The database, the outbox and
/// the router are the app's own.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final DateTime t0 = DateTime.utc(2026, 8, 8, 9, 30);

  late NorteDatabase database;
  late DriftTaskRepository tasks;
  late DriftOutboxRepository outbox;
  late DriftReminderRepository reminders;
  late DriftVoiceSettingsStore voiceSettings;
  late FakeAiEngine ai;
  late FakeRealtimeTranscription realtime;
  late FakeMicrophone microphone;
  late FakeJiraGateway jira;

  /// The linked task every Jira scenario needs.
  final Task linked = Task(
    id: 'task-1',
    title: 'revisar o conector',
    createdAt: t0,
    updatedAt: t0,
    jiraLink: const JiraLink(
      issueKey: 'PROJ-123',
      siteUrl: 'https://example.atlassian.net',
    ),
  );

  setUp(() async {
    database = openInMemoryNorteDatabase();
    tasks = DriftTaskRepository(database);
    outbox = DriftOutboxRepository(database);
    reminders = DriftReminderRepository(database);
    voiceSettings = DriftVoiceSettingsStore(database);
    await tasks.save(linked);

    ai = FakeAiEngine(generatedAt: t0);
    // Driven event by event: speech has to arrive while the app is on screen,
    // not before the first frame is built.
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

  /// Presses the voice button and lets the session open.
  ///
  /// By type rather than by position: at this viewport the shell is in its
  /// desktop layout and the button lives on the navigation rail, not in a
  /// floating action button.
  Future<void> speakStart(WidgetTester tester) async {
    await tester.tap(find.byType(VoiceButton));
    await tester.pumpAndSettle();
  }

  /// Plays a partial then a committed segment, as VAD would.
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

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(VoiceOverlay).first));

  group('S05-E2E-01: "muda o PROJ-123 para concluído"', () {
    const String utterance = 'muda o PROJ-123 para concluído';

    void scriptTransition() {
      ai.alwaysParseAs(
        '{"intent":"updateJira","slots":{"issueKey":"PROJ-123",'
        '"transition":"Done"},"confidence":0.92}',
      );
    }

    testWidgets(
      'S05-E2E-01: the overlay shows the partial, then the committed segment, '
      'and confirming queues the transition',
      (WidgetTester tester) async {
        scriptTransition();
        await bootApp(tester);
        await speakStart(tester);

        // The overlay is up and the microphone is open.
        expect(find.byType(VoiceOverlay), findsOneWidget);
        expect(microphone.opens, 1);

        realtime.emitPartial('muda o PROJ');
        await tester.pumpAndSettle();
        expect(find.textContaining('muda o PROJ'), findsWidgets);

        realtime.emitCommitted(utterance);
        await tester.pumpAndSettle();

        // Confidence is 0.92 — well over BR-04's threshold — and the sheet is
        // here anyway, because it writes to Jira and the setting is on.
        expect(find.byType(ConfirmSheet), findsOneWidget);
        expect(find.text('PROJ-123 → Done'), findsOneWidget);
        // The microphone stays open (DEC-031): the session listens until the
        // user stops it. What protects the user while a mutation is one tap
        // away is not a closed microphone but the guard that ignores anything
        // said while a confirmation is up — asserted below.
        expect(microphone.closes, 0);
        // And nothing has been queued yet.
        expect(await outbox.pending(t0), isEmpty);

        // Speaking while the sheet is up is the user reading aloud, not a
        // second command.
        realtime.emitCommitted('cria tarefa outra coisa');
        await tester.pumpAndSettle();
        expect(find.byType(ConfirmSheet), findsOneWidget);
        expect(await outbox.pending(t0), isEmpty);

        await tester.tap(find.byKey(ConfirmSheet.confirmButtonKey));
        await tester.pumpAndSettle();

        // BR-05: the transition is in the outbox, not on the wire.
        final List<OutboxOperation> queued = await outbox.pending(t0);
        expect(queued, hasLength(1));
        expect(queued.single.kind, OutboxOperationKind.transition);
        expect(queued.single.issueKey, 'PROJ-123');
        expect(queued.single.payload, 'Done');
        expect(
          jira.writes,
          isEmpty,
          reason: 'the dispatcher sends to Jira, never the router',
        );
      },
    );

    testWidgets('S05-E2E-01 (B): cancelling leaves the outbox empty', (
      WidgetTester tester,
    ) async {
      scriptTransition();
      await bootApp(tester);
      await speakStart(tester);
      await speak(tester, 'muda o PROJ', utterance);

      await tester.tap(find.byKey(ConfirmSheet.cancelButtonKey));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmSheet), findsNothing);
      expect(find.byType(VoiceOverlay), findsNothing);
      // Nothing ran, so there is nothing to undo.
      expect(await outbox.pending(t0), isEmpty);
    });

    testWidgets(
      'S05-E2E-01 (C): with the always-confirm setting off, it queues without '
      'a sheet',
      (WidgetTester tester) async {
        scriptTransition();
        await voiceSettings.write(
          const VoiceSettings(alwaysConfirmJiraWrites: false),
        );
        await bootApp(tester);
        await speakStart(tester);
        await speak(tester, 'muda o PROJ', utterance);

        expect(find.byType(ConfirmSheet), findsNothing);
        expect(await outbox.pending(t0), hasLength(1));
        // BR-05 in the wording as well: queued, not sent.
        expect(find.text(l10nOf(tester).voiceDoneQueued), findsOneWidget);
      },
    );
  });

  group('S05-E2E-02: "cria tarefa revisar PR do conector"', () {
    testWidgets(
      'S05-E2E-02: a confident local intent runs with no sheet and the task '
      'appears in the list',
      (WidgetTester tester) async {
        ai.alwaysParseAs(
          '{"intent":"createTask","slots":{"title":"revisar PR do conector"},'
          '"confidence":0.95}',
        );
        await bootApp(tester);
        await speakStart(tester);
        await speak(
          tester,
          'cria tarefa revisar',
          'cria tarefa revisar PR do conector',
        );

        // No confirmation: a local task at 0.95 is the user's own row, and
        // the Jira rule does not reach it.
        expect(find.byType(ConfirmSheet), findsNothing);
        expect(find.text(l10nOf(tester).voiceDoneTask), findsOneWidget);

        final List<Task> stored = await tasks.listAll();
        expect(
          stored.map((Task t) => t.title),
          contains('revisar PR do conector'),
        );

        // And it is on screen once the overlay is dismissed.
        await tester.tap(find.byKey(VoiceOverlay.stopButtonKey));
        await tester.pumpAndSettle();
        expect(find.text('revisar PR do conector'), findsOneWidget);
      },
    );
  });

  group('S05-E2E-03: "faz aquilo lá que combinamos"', () {
    testWidgets(
      'S05-E2E-03: an ambiguous utterance asks the user to rephrase and '
      'changes nothing',
      (WidgetTester tester) async {
        ai.alwaysParseAs('{"intent":"unknown","slots":{},"confidence":0.2}');
        await bootApp(tester);
        await speakStart(tester);
        await speak(tester, 'faz aquilo', 'faz aquilo lá que combinamos');

        expect(find.byType(ConfirmSheet), findsNothing);
        expect(find.text(l10nOf(tester).voiceNotUnderstood), findsOneWidget);

        // Nothing anywhere: no task, no queued write, no reminder.
        expect(await tasks.listAll(), hasLength(1));
        expect(await outbox.pending(t0), isEmpty);
        expect(await reminders.listAll(), isEmpty);
      },
    );

    testWidgets('S05-E2E-03 (B): a subsequent command still works', (
      WidgetTester tester,
    ) async {
      ai.alwaysParseAs('{"intent":"unknown","slots":{},"confidence":0.2}');
      await bootApp(tester);
      await speakStart(tester);
      await speak(tester, 'faz aquilo', 'faz aquilo lá que combinamos');

      await tester.tap(find.byKey(VoiceOverlay.stopButtonKey));
      await tester.pumpAndSettle();

      // A refusal must not leave the pipeline wedged — the whole point of
      // "try saying it another way" is that trying again works.
      ai.alwaysParseAs(
        '{"intent":"createTask","slots":{"title":"limpar as branches"},'
        '"confidence":0.95}',
      );
      await speakStart(tester);
      await speak(tester, 'cria tarefa', 'cria tarefa limpar as branches');

      final List<Task> stored = await tasks.listAll();
      expect(stored.map((Task t) => t.title), contains('limpar as branches'));
    });
  });

  group('S05-E2E: the missing-slot exchange', () {
    testWidgets(
      'the app asks only for the ticket, and the answer completes the command',
      (WidgetTester tester) async {
        // First pass: everything but the issue key.
        ai
          ..scriptedIntents.add(
            '{"intent":"updateJira","slots":{"transition":"Done"},'
            '"confidence":0.9}',
          )
          // Second pass: the answer, with the established slot echoed back.
          ..scriptedIntents.add(
            '{"intent":"updateJira","slots":{"issueKey":"PROJ-123",'
            '"transition":"Done"},"confidence":0.9}',
          );
        await voiceSettings.write(
          const VoiceSettings(alwaysConfirmJiraWrites: false),
        );
        await bootApp(tester);
        await speakStart(tester);
        await speak(tester, 'muda pra', 'muda pra concluído');

        // The targeted question, and only that one.
        expect(find.text(l10nOf(tester).voiceAskIssueKey), findsOneWidget);
        expect(await outbox.pending(t0), isEmpty);

        realtime.emitCommitted('PROJ-123');
        await tester.pumpAndSettle();

        // The second parse carried the first intent as context, so "PROJ-123"
        // completed the transition instead of being read as a new command.
        expect(ai.intentCalls.last.context.pendingIntent, isNotNull);
        expect(await outbox.pending(t0), hasLength(1));
      },
    );
  });
}
