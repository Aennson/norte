import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:norte/domain/entities/meeting.dart';
import 'package:norte/domain/entities/task.dart';
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
import 'package:norte/presentation/shared/widgets/norte_screen.dart';
import 'package:norte/presentation/tasks/task_providers.dart';

import '../test/fakes/fake_ai_engine.dart';
import '../test/fakes/fake_clock.dart';
import '../test/support/meeting_fixtures.dart';

/// S03-E2E-01 — paste → summarize → convert, through the UI.
///
/// The complete Pillar 2 pipeline, driven the way a user drives it: the real
/// composition root with only the database and the AI engine replaced
/// (`docs/testing-strategy.md` §4.2). Every step asserts both what the user
/// sees and what the system did — including, at the end, what BR-03 left in
/// the database.
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

    engine = FakeAiEngine(generatedAt: t0)
      ..alwaysAnswer(summaryFixture('retro.json'));
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

  testWidgets('S03-E2E-01: a pasted retro becomes a summary and a task', (
    WidgetTester tester,
  ) async {
    await bootApp(tester);

    // --- new meeting --------------------------------------------------
    expect(find.byType(MeetingsScreen), findsOneWidget);
    await tester.tap(find.byKey(MeetingsScreen.newMeetingButtonKey));
    await tester.pumpAndSettle();
    expect(find.byType(NewMeetingScreen), findsOneWidget);

    // --- choose the retro template and paste the transcript ------------
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

    // --- process ------------------------------------------------------
    await tester.tap(find.byKey(NewMeetingScreen.processButtonKey));
    await tester.pumpAndSettle();

    // The engine was asked exactly once, with the retro template.
    expect(engine.calls, hasLength(1));
    expect(engine.calls.single.template.type, MeetingType.retro);

    // --- review: the retro's three sections are on screen --------------
    expect(find.byType(SummaryScreen), findsOneWidget);
    expect(find.text('What went well'), findsOneWidget);
    expect(find.text('What to improve'), findsOneWidget);
    expect(
      find.text('Action items'),
      findsOneWidget,
      reason: 'the retro template section, now unambiguous',
    );
    expect(find.textContaining('shipped the outbox'), findsOneWidget);

    // --- convert one action item, not both -----------------------------
    expect(find.text('Update the runbook'), findsOneWidget);
    await tester.ensureVisible(find.byKey(SummaryScreen.convertKey('item-0')));

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(SummaryScreen.convertKey('item-0')));
    await tester.pumpAndSettle();

    expect(find.text('Task created.'), findsOneWidget);
    // Let the toast expire before the next one, or the second queues behind
    // it and never renders.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    // The converted one is marked; its neighbour still offers the button.
    expect(find.text('Converted'), findsOneWidget);
    expect(find.byKey(SummaryScreen.convertKey('item-0')), findsNothing);
    expect(find.byKey(SummaryScreen.convertKey('item-1')), findsOneWidget);

    // The task really exists, with the title, status and tag S03-UT-05 names.
    final List<Task> stored = await tasks.listAll();
    expect(stored, hasLength(1));
    expect(stored.single.title, 'Update the runbook');
    expect(stored.single.status, TaskStatus.todo);
    expect(stored.single.tags, contains(meetingTag));

    // --- save the summary ----------------------------------------------
    await tester.ensureVisible(find.byKey(SummaryScreen.saveButtonKey));

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(SummaryScreen.saveButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('Summary saved.'), findsOneWidget);

    // --- back to the list ----------------------------------------------
    await tester.tap(find.byKey(NorteScreen.backButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NorteScreen.backButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(MeetingsScreen), findsOneWidget);
    expect(find.text('Sprint 12 retro'), findsOneWidget);

    // --- BR-03, verified in the database -------------------------------
    final List<Meeting> savedMeetings = await meetings.listAll();
    expect(savedMeetings, hasLength(1));
    final Meeting saved = savedMeetings.single;
    expect(saved.title, 'Sprint 12 retro');
    expect(saved.summary!.sections, hasLength(3));
    // The summary survived; the transcript did not, because the user never
    // asked for it to be kept.
    expect(saved.rawTranscript, isEmpty);
    expect(saved.retention, RetentionPolicy.ephemeral);

    // --- the task is on the tasks tab ----------------------------------
    await tester.tap(find.text('Tasks').last);
    await tester.pumpAndSettle();
    expect(find.text('Update the runbook'), findsOneWidget);
    // The card draws a tag as `#meeting` (`docs/design-system.md` §1.4).
    expect(find.text('#meeting'), findsOneWidget);
  });

  testWidgets('S03-E2E-01: opting in keeps the transcript', (
    WidgetTester tester,
  ) async {
    // The other half of BR-03: the choice is a real choice, and it is made
    // before the text is processed.
    await bootApp(tester);
    await tester.tap(find.byKey(MeetingsScreen.newMeetingButtonKey));
    await tester.pumpAndSettle();
    // The fixture is a retro summary, so the retro template is what its
    // sections have to be keyed by.
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
    await tester.tap(find.byKey(NewMeetingScreen.saveTranscriptKey));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(NewMeetingScreen.processButtonKey));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(SummaryScreen.saveButtonKey));

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(SummaryScreen.saveButtonKey));
    await tester.pumpAndSettle();

    final Meeting saved = (await meetings.listAll()).single;
    expect(saved.retention, RetentionPolicy.persisted);
    expect(saved.rawTranscript, contains('the outbox went out on Tuesday'));
  });

  testWidgets('S03-E2E-01: leaving without saving stores nothing at all', (
    WidgetTester tester,
  ) async {
    await bootApp(tester);
    await tester.tap(find.byKey(MeetingsScreen.newMeetingButtonKey));
    await tester.pumpAndSettle();
    // The fixture is a retro summary, so the retro template is what its
    // sections have to be keyed by.
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
    await tester.tap(find.byKey(NewMeetingScreen.processButtonKey));
    await tester.pumpAndSettle();
    expect(find.byType(SummaryScreen), findsOneWidget);

    // Walk away.
    await tester.tap(find.byKey(NorteScreen.backButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NorteScreen.backButtonKey));
    await tester.pumpAndSettle();

    // Nothing was written — not the summary, and certainly not the text.
    expect(await meetings.listAll(), isEmpty);
    expect(find.byType(MeetingsScreen), findsOneWidget);
  });
}
