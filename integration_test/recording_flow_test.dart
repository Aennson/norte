import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:norte/domain/entities/meeting.dart';
import 'package:norte/domain/entities/transcript.dart';
import 'package:norte/domain/failures/failure.dart';
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

/// S04-E2E-01 — record → transcribe → summarize, through the UI.
///
/// The complete second input flow, driven the way a user drives it: the real
/// composition root with the database, the audio capture, the transcription
/// engine and the AI engine replaced (`docs/testing-strategy.md` §4.2).
///
/// The assertion the scenario exists for is the last one: at the end of a
/// successful run **the audio file is not in the store**. Everything before it
/// could pass while the app quietly kept an hour of recorded meeting on disk.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final DateTime t0 = DateTime.utc(2026, 8, 8, 9, 30);

  const String audioPath = '/tmp/norte_recordings/meeting_1.m4a';
  const String spoken =
      'Ana: shipped the outbox yesterday. Today the dispatcher. No blockers.';

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
      ..alwaysAnswer(summaryFixture('daily.json'));
    transcription = FakeBatchTranscription(
      transcripts: <String, Transcript>{
        audioPath: const Transcript(text: spoken, language: 'pt'),
      },
    );
    store = FakeAudioStore();
    recorder = FakeAudioRecorder();
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

  /// Walks from the meetings tab to the recording screen, picking the daily
  /// template on the way — the template belongs to the composer, and the
  /// recording flow reads it from there.
  Future<void> openRecorder(WidgetTester tester) async {
    await tester.tap(find.byKey(MeetingsScreen.newMeetingButtonKey));
    await tester.pumpAndSettle();
    expect(find.byType(NewMeetingScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('meeting.template.builtin.daily')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(NewMeetingScreen.recordButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NewMeetingScreen.recordButtonKey));
    await tester.pumpAndSettle();
    expect(find.byType(RecordMeetingScreen), findsOneWidget);
  }

  testWidgets('S04-E2E-01: a recorded daily becomes a saved summary', (
    WidgetTester tester,
  ) async {
    await bootApp(tester);
    await openRecorder(tester);

    // --- record -------------------------------------------------------
    await tester.tap(find.byKey(RecordMeetingScreen.startKey));
    await tester.pumpAndSettle();

    expect(find.text('Recording'), findsOneWidget);
    expect(recorder.startedPath, audioPath);
    // The configurable ceiling, defaulting to ninety minutes.
    expect(recorder.startedLimit, const Duration(minutes: 90));

    // The store now holds the file the recorder wrote.
    store.add(audioPath);

    // --- stop ---------------------------------------------------------
    await tester.tap(find.byKey(RecordMeetingScreen.stopKey));
    await tester.pumpAndSettle();

    // Recorded, not yet transcribed: the point at which the audio exists and
    // the user can still throw it away.
    expect(find.byKey(RecordMeetingScreen.transcribeKey), findsOneWidget);
    expect(find.byKey(RecordMeetingScreen.discardKey), findsOneWidget);

    // --- transcribe and summarize --------------------------------------
    await tester.tap(find.byKey(RecordMeetingScreen.transcribeKey));
    await tester.pumpAndSettle();

    // The engine got the file, and the summarizer got the engine's transcript
    // — through the Sprint 03 use case, not a copy of it.
    expect(transcription.requestedFiles, <String>[audioPath]);
    expect(ai.calls, hasLength(1));
    expect(ai.lastTranscript, spoken);
    expect(ai.calls.single.template.type, MeetingType.daily);

    // --- review: the daily's sections are on screen ---------------------
    expect(find.byType(SummaryScreen), findsOneWidget);
    expect(find.text('Done since yesterday'), findsOneWidget);
    expect(find.text('Planned for today'), findsOneWidget);
    expect(find.text('Blockers'), findsOneWidget);
    expect(
      find.textContaining('finished the credential store'),
      findsOneWidget,
    );

    // --- save ------------------------------------------------------------
    await tester.ensureVisible(find.byKey(SummaryScreen.saveButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SummaryScreen.saveButtonKey));
    await tester.pumpAndSettle();

    final List<Meeting> stored = await meetings.listAll();
    expect(stored, hasLength(1));
    expect(stored.single.type, MeetingType.daily);
    // BR-03: the generated transcript is governed exactly as a pasted one is,
    // and the default is still ephemeral.
    expect(stored.single.rawTranscript, isEmpty);

    // --- the assertion the scenario exists for --------------------------
    expect(
      await store.list(),
      isEmpty,
      reason: 'the audio must be gone once the transcription succeeded',
    );
    expect(store.deleted, <String>[audioPath]);
  });

  testWidgets('S04-E2E-01: pausing and resuming keeps one take', (
    WidgetTester tester,
  ) async {
    await bootApp(tester);
    await openRecorder(tester);

    await tester.tap(find.byKey(RecordMeetingScreen.startKey));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(RecordMeetingScreen.pauseKey));
    await tester.pumpAndSettle();
    expect(find.text('Paused'), findsOneWidget);

    await tester.tap(find.byKey(RecordMeetingScreen.resumeKey));
    await tester.pumpAndSettle();
    expect(find.text('Recording'), findsOneWidget);

    // One take, one file: pausing must not start a second recording.
    expect(recorder.startedPath, audioPath);
    expect(store.deleted, isEmpty);
  });

  testWidgets(
    'S04-E2E-01: discarding before transcribing deletes the audio and '
    'uploads nothing',
    (WidgetTester tester) async {
      await bootApp(tester);
      await openRecorder(tester);

      await tester.tap(find.byKey(RecordMeetingScreen.startKey));
      await tester.pumpAndSettle();
      store.add(audioPath);

      await tester.tap(find.byKey(RecordMeetingScreen.stopKey));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(RecordMeetingScreen.discardKey));
      await tester.pumpAndSettle();

      expect(await store.list(), isEmpty);
      expect(store.deleted, <String>[audioPath]);
      // Discarding is not a silent transcription the user still pays for.
      expect(transcription.requestedFiles, isEmpty);
      expect(ai.calls, isEmpty);
    },
  );

  testWidgets(
    'S04-E2E-01: a transcription failure keeps the audio and the retry '
    'recovers it',
    (WidgetTester tester) async {
      await bootApp(tester);
      await openRecorder(tester);

      await tester.tap(find.byKey(RecordMeetingScreen.startKey));
      await tester.pumpAndSettle();
      store.add(audioPath);

      await tester.tap(find.byKey(RecordMeetingScreen.stopKey));
      await tester.pumpAndSettle();

      transcription.failWith = const TranscriptionFailure();
      await tester.tap(find.byKey(RecordMeetingScreen.transcribeKey));
      await tester.pumpAndSettle();

      // The error, and the promise the rule is really about.
      expect(find.textContaining('could not be transcribed'), findsOneWidget);
      expect(find.textContaining('recording is kept'), findsOneWidget);
      expect(await store.list(), <String>[audioPath]);

      // --- retry, without re-recording -----------------------------------
      transcription.failWith = null;
      await tester.tap(find.byKey(RecordMeetingScreen.retryKey));
      await tester.pumpAndSettle();

      expect(find.byType(SummaryScreen), findsOneWidget);
      // The same file, twice — the second attempt recorded nothing new.
      expect(transcription.requestedFiles, <String>[audioPath, audioPath]);
      expect(await store.list(), isEmpty);
    },
  );
}
