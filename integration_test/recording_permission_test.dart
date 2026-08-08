import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:norte/domain/entities/transcript.dart';
import 'package:norte/domain/ports/audio_recorder.dart';
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
import 'package:norte/presentation/meetings/record_meeting_screen.dart';
import 'package:norte/presentation/meetings/summary_screen.dart';
import 'package:norte/presentation/tasks/task_providers.dart';

import '../test/fakes/fake_ai_engine.dart';
import '../test/fakes/fake_audio_recorder.dart';
import '../test/fakes/fake_audio_store.dart';
import '../test/fakes/fake_batch_transcription.dart';
import '../test/fakes/fake_clock.dart';
import '../test/support/meeting_fixtures.dart';

/// S04-E2E-02 — the microphone permission UX.
///
/// The scenario is not "an error appears". It is that a refusal produces an
/// **explanation and a route out**, that nothing crashes, and — the part that
/// is easy to break and easy to miss — that the paste flow still works
/// afterwards. A user who cannot record must not be left with an app that
/// cannot summarize either.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final DateTime t0 = DateTime.utc(2026, 8, 8, 9, 30);

  late NorteDatabase database;
  late DriftTaskRepository tasks;
  late DriftMeetingRepository meetings;
  late DriftMeetingTemplateRepository templates;
  late FakeAiEngine ai;
  late FakeBatchTranscription transcription;
  late FakeAudioStore store;
  late FakeAudioRecorder recorder;

  setUp(() async {
    database = openInMemoryNorteDatabase();
    tasks = DriftTaskRepository(database);
    meetings = DriftMeetingRepository(database);
    templates = DriftMeetingTemplateRepository(database);
    await templates.seedDefaults();

    ai = FakeAiEngine(generatedAt: t0)
      ..alwaysAnswer(summaryFixture('retro.json'));
    transcription = FakeBatchTranscription(transcripts: <String, Transcript>{});
    store = FakeAudioStore();
    // The switch this whole suite turns on.
    recorder = FakeAudioRecorder(permissionStatus: MicrophonePermission.denied);
  });

  tearDown(() async {
    await transcription.dispose();
    await recorder.dispose();
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
          meetingRepositoryProvider.overrideWithValue(meetings),
          meetingTemplateRepositoryProvider.overrideWithValue(templates),
          aiEngineProvider.overrideWithValue(ai),
          batchTranscriptionProvider.overrideWithValue(transcription),
          audioStoreProvider.overrideWithValue(store),
          audioRecorderProvider.overrideWithValue(recorder),
          clockProvider.overrideWithValue(FakeClock(t0)),
        ],
        child: NorteApp(
          router: buildNorteRouter(initialLocation: NorteRoutes.meetings),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openRecorder(WidgetTester tester) async {
    await tester.tap(find.byKey(MeetingsScreen.newMeetingButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('meeting.template.builtin.retro')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(NewMeetingScreen.recordButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NewMeetingScreen.recordButtonKey));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'S04-E2E-02: a denied microphone explains itself and offers settings',
    (WidgetTester tester) async {
      await bootApp(tester);
      await openRecorder(tester);

      await tester.tap(find.byKey(RecordMeetingScreen.startKey));
      await tester.pumpAndSettle();

      // No crash, and an explanation rather than a raw failure message.
      expect(tester.takeException(), isNull);
      expect(find.text('Microphone access is off'), findsOneWidget);
      expect(find.textContaining('needs the microphone'), findsOneWidget);

      // Both routes are offered while the platform will still prompt.
      expect(
        find.byKey(RecordMeetingScreen.permissionAllowKey),
        findsOneWidget,
      );
      expect(
        find.byKey(RecordMeetingScreen.permissionSettingsKey),
        findsOneWidget,
      );

      // The action really opens the settings.
      await tester.tap(find.byKey(RecordMeetingScreen.permissionSettingsKey));
      await tester.pumpAndSettle();
      expect(recorder.settingsOpened, isTrue);

      // Nothing was recorded and nothing was left behind.
      expect(await store.list(), isEmpty);
    },
  );

  testWidgets(
    'S04-E2E-02: a permanently denied microphone drops the allow button',
    (WidgetTester tester) async {
      recorder.permissionStatus = MicrophonePermission.permanentlyDenied;

      await bootApp(tester);
      await openRecorder(tester);

      await tester.tap(find.byKey(RecordMeetingScreen.startKey));
      await tester.pumpAndSettle();

      expect(find.textContaining('will not appear again'), findsOneWidget);
      // A button that would produce no prompt is not rendered at all.
      expect(find.byKey(RecordMeetingScreen.permissionAllowKey), findsNothing);
      expect(
        find.byKey(RecordMeetingScreen.permissionSettingsKey),
        findsOneWidget,
      );
    },
  );

  testWidgets('S04-E2E-02: granting it afterwards starts the recording', (
    WidgetTester tester,
  ) async {
    await bootApp(tester);
    await openRecorder(tester);

    await tester.tap(find.byKey(RecordMeetingScreen.startKey));
    await tester.pumpAndSettle();
    expect(find.text('Microphone access is off'), findsOneWidget);

    // The user grants it in the system settings and comes back.
    recorder.permissionStatus = MicrophonePermission.granted;
    await tester.tap(find.byKey(RecordMeetingScreen.permissionAllowKey));
    await tester.pumpAndSettle();

    expect(find.text('Recording'), findsOneWidget);
    expect(recorder.startedPath, isNotNull);
  });

  testWidgets(
    'S04-E2E-02: going back and pasting still works — a refused microphone '
    'does not break the other flow',
    (WidgetTester tester) async {
      await bootApp(tester);
      await openRecorder(tester);

      await tester.tap(find.byKey(RecordMeetingScreen.startKey));
      await tester.pumpAndSettle();
      expect(find.text('Microphone access is off'), findsOneWidget);

      // --- back to the paste flow -----------------------------------------
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(NewMeetingScreen), findsOneWidget);

      await tester.enterText(
        find.byKey(NewMeetingScreen.titleFieldKey),
        'Sprint 12 retro',
      );
      await tester.enterText(
        find.byKey(NewMeetingScreen.transcriptFieldKey),
        retroTranscript,
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(NewMeetingScreen.processButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(NewMeetingScreen.processButtonKey));
      await tester.pumpAndSettle();

      // The pasted flow is entirely unaffected by the microphone.
      expect(find.byType(SummaryScreen), findsOneWidget);
      expect(find.text('What went well'), findsOneWidget);
      expect(ai.calls, hasLength(1));
    },
  );
}
