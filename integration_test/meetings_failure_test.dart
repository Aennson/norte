import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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
import 'package:norte/presentation/meetings/summary_screen.dart';
import 'package:norte/presentation/tasks/task_providers.dart';

import '../test/fakes/fake_ai_engine.dart';
import '../test/fakes/fake_clock.dart';
import '../test/support/meeting_fixtures.dart';

/// S03-E2E-02 — an AI failure, and the recovery from it.
///
/// The error UX of the pipeline. What is being proved is not that an error
/// appears — it is that the user's twenty minutes of pasted meeting is still
/// in the field when it does, so "Try again" is one tap rather than a hunt
/// through their clipboard history.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final DateTime t0 = DateTime.utc(2026, 8, 8, 9, 30);

  late NorteDatabase database;
  late DriftTaskRepository tasks;
  late DriftMeetingRepository meetings;
  late DriftMeetingTemplateRepository templates;
  late FakeAiEngine engine;

  setUp(() async {
    database = openInMemoryNorteDatabase();
    tasks = DriftTaskRepository(database);
    meetings = DriftMeetingRepository(database);
    templates = DriftMeetingTemplateRepository(database);
    await templates.seedDefaults();
    engine = FakeAiEngine(generatedAt: t0);
  });

  tearDown(() => database.close());

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
          aiEngineProvider.overrideWithValue(engine),
          clockProvider.overrideWithValue(FakeClock(t0)),
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
    // The recovery fixture is a retro summary, so the retro template is what
    // its sections have to be keyed by.
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

  testWidgets('S03-E2E-02: an unreadable answer offers a retry that works', (
    WidgetTester tester,
  ) async {
    await bootApp(tester);
    await fillForm(tester);

    // The engine answers with prose twice — the use case's one retry is
    // spent, and it gives up.
    engine.scriptedAnswers
      ..add(summaryFixture('malformed.txt'))
      ..add(summaryFixture('malformed.txt'));

    await tester.tap(find.byKey(NewMeetingScreen.processButtonKey));
    await tester.pumpAndSettle();

    // No crash, and the summary screen was never reached.
    expect(find.byType(SummaryScreen), findsNothing);
    expect(find.byType(NewMeetingScreen), findsOneWidget);
    expect(
      find.text(
        'Claude answered with something this app could not read. '
        'Try again.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(NewMeetingScreen.retryButtonKey), findsOneWidget);
    expect(engine.calls, hasLength(2));

    // **The transcript is still in the field.** This is the assertion the
    // whole scenario exists for.
    final TextField transcript = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(NewMeetingScreen.transcriptFieldKey),
        matching: find.byType(TextField),
      ),
    );
    expect(transcript.controller!.text, retroTranscript);

    // --- try again, and this time the engine behaves -------------------
    engine.alwaysAnswer(summaryFixture('retro.json'));
    await tester.tap(find.byKey(NewMeetingScreen.retryButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(SummaryScreen), findsOneWidget);
    expect(find.text('What went well'), findsOneWidget);
    expect(find.textContaining('shipped the outbox'), findsOneWidget);
  });

  testWidgets('S03-E2E-02: a missing API key points at Settings', (
    WidgetTester tester,
  ) async {
    // The failure a new user actually meets first. It must not read as a
    // generic error, because the fix is somewhere specific.
    await bootApp(tester);
    await fillForm(tester);
    engine.failWith = const MissingApiKeyFailure();

    await tester.tap(find.byKey(NewMeetingScreen.processButtonKey));
    await tester.pumpAndSettle();

    expect(
      find.text('Add your Claude API key in Settings to summarize meetings.'),
      findsOneWidget,
    );
    // Not retried — a key that is absent stays absent.
    expect(engine.calls, hasLength(1));
    expect(await meetings.listAll(), isEmpty);
  });

  testWidgets('S03-E2E-02: no network says so, and keeps the transcript', (
    WidgetTester tester,
  ) async {
    await bootApp(tester);
    await fillForm(tester);
    engine.failWith = const NetworkFailure();

    await tester.tap(find.byKey(NewMeetingScreen.processButtonKey));
    await tester.pumpAndSettle();

    expect(
      find.text('Cannot reach Claude. Check your connection.'),
      findsOneWidget,
    );
    final TextField transcript = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(NewMeetingScreen.transcriptFieldKey),
        matching: find.byType(TextField),
      ),
    );
    expect(transcript.controller!.text, retroTranscript);
  });

  testWidgets('S03-E2E-02: an empty transcript is refused before the engine', (
    WidgetTester tester,
  ) async {
    await bootApp(tester);
    await tester.tap(find.byKey(MeetingsScreen.newMeetingButtonKey));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(NewMeetingScreen.processButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('Paste a transcript first.'), findsOneWidget);
    // Nothing was spent on a request that could not have worked.
    expect(engine.calls, isEmpty);
  });
}
