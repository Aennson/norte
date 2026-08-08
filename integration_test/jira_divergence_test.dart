import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:norte/domain/entities/jira_issue_snapshot.dart';
import 'package:norte/domain/entities/jira_link.dart';
import 'package:norte/domain/entities/outbox_operation.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/infrastructure/jira/outbox_dispatcher.dart';
import 'package:norte/infrastructure/persistence/drift_outbox_repository.dart';
import 'package:norte/infrastructure/persistence/drift_task_repository.dart';
import 'package:norte/infrastructure/persistence/norte_database.dart';
import 'package:norte/infrastructure/persistence/norte_database_factory.dart';
import 'package:norte/presentation/app/norte_app.dart';
import 'package:norte/presentation/jira/jira_providers.dart';
import 'package:norte/presentation/jira/jira_task_actions.dart';
import 'package:norte/presentation/jira/widgets/divergence_banner.dart';
import 'package:norte/presentation/tasks/task_providers.dart';

import '../test/fakes/fake_clock.dart';
import '../test/fakes/fake_jira_credential_store.dart';
import '../test/fakes/fake_jira_gateway.dart';

/// S02-E2E-02 — the two ways a user can settle a local×Jira disagreement.
///
/// **BR-02 end to end.** The app finds the conflict, shows it, and waits. Both
/// scenarios assert the same thing first — that *before* the choice nothing
/// has moved — because that is the rule; what follows only checks that the
/// decision the user made is the one that happened.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final DateTime t0 = DateTime.utc(2026, 1, 1, 9);

  late NorteDatabase database;
  late DriftTaskRepository tasks;
  late DriftOutboxRepository outbox;
  late FakeJiraGateway jira;
  late OutboxDispatcher dispatcher;
  late FakeClock clock;

  setUp(() async {
    database = openInMemoryNorteDatabase();
    tasks = DriftTaskRepository(database);
    outbox = DriftOutboxRepository(database);
    clock = FakeClock(t0);

    // The site has the issue open; the user finished it here.
    jira = FakeJiraGateway.fromFixture('test/fixtures/jira_issues.json');
    jira.issues['PROJ-123'] = const JiraIssueSnapshot(
      issueKey: 'PROJ-123',
      siteUrl: 'https://example.atlassian.net',
      status: 'In Progress',
    );

    dispatcher = OutboxDispatcher(
      outbox: outbox,
      gateway: jira,
      tasks: tasks,
      clock: clock,
    );

    await tasks.save(
      Task(
        id: 'task-1',
        title: 'Review the connector PR',
        status: TaskStatus.done,
        createdAt: t0,
        updatedAt: t0,
        jiraLink: JiraLink(
          issueKey: 'PROJ-123',
          siteUrl: 'https://example.atlassian.net',
          // Agrees with the local status, so no banner is showing yet — the
          // divergence has to be discovered by the refresh.
          lastKnownStatus: 'Done',
          lastSyncedAt: t0,
        ),
      ),
    );
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
          outboxRepositoryProvider.overrideWithValue(outbox),
          jiraGatewayProvider.overrideWithValue(jira),
          jiraCredentialStoreProvider.overrideWithValue(
            FakeJiraCredentialStore.configured(),
          ),
          outboxDispatchProvider.overrideWithValue(dispatcher.dispatch),
          outboxRetryProvider.overrideWithValue(dispatcher.retry),
        ],
        child: const NorteApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Refreshes task-1 through the UI and returns once the banner is up.
  Future<void> refreshThroughUi(WidgetTester tester) async {
    expect(find.byType(DivergenceBanner), findsNothing);

    await tester.tap(find.byKey(const Key('task-jira-menu-task-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(JiraTaskActions.menuRefreshKey));
    await tester.pumpAndSettle();

    // The conflict is on screen, naming both sides.
    expect(find.byType(DivergenceBanner), findsOneWidget);
    expect(find.textContaining('In Progress'), findsWidgets);
    expect(find.text('Keep local'), findsOneWidget);
    expect(find.text('Adopt from Jira'), findsOneWidget);

    // And nothing has been decided: the local status is untouched, the cache
    // holds what the site said, and nothing has been queued or sent.
    final Task stored = (await tasks.findById('task-1'))!;
    expect(stored.status, TaskStatus.done);
    expect(stored.jiraLink!.lastKnownStatus, 'In Progress');
    expect(await outbox.unsettled(), isEmpty);
    expect(jira.writes, isEmpty);
  }

  testWidgets('S02-E2E-02: adopting Jira moves the local status', (
    WidgetTester tester,
  ) async {
    await bootApp(tester);
    await refreshThroughUi(tester);

    await tester.tap(find.text('Adopt from Jira'));
    await tester.pumpAndSettle();

    // The local task now says what Jira said…
    final Task stored = (await tasks.findById('task-1'))!;
    expect(stored.status, TaskStatus.inProgress);
    expect(stored.jiraLink!.issueKey, 'PROJ-123');

    // …the two agree, so the banner is gone…
    expect(find.byType(DivergenceBanner), findsNothing);

    // …and nothing was sent to the site: the user agreed with it, they did
    // not instruct it.
    expect(await outbox.unsettled(), isEmpty);
    expect(jira.writes, isEmpty);
    expect(jira.issues['PROJ-123']!.status, 'In Progress');
  });

  testWidgets('S02-E2E-02: keeping local queues a transition instead', (
    WidgetTester tester,
  ) async {
    await bootApp(tester);
    await refreshThroughUi(tester);

    await tester.tap(find.text('Keep local'));
    await tester.pumpAndSettle();

    // The local status is exactly what it was…
    expect((await tasks.findById('task-1'))!.status, TaskStatus.done);

    // …and a transition is queued rather than sent (BR-05).
    final List<OutboxOperation> queued = await outbox.unsettled();
    expect(queued, hasLength(1));
    expect(queued.single.kind, OutboxOperationKind.transition);
    expect(queued.single.issueKey, 'PROJ-123');
    expect(queued.single.payload, 'Done');
    expect(jira.writes, isEmpty);

    // Once it goes out, the site agrees and the banner has nothing to say.
    await dispatcher.dispatch();
    expect(jira.issues['PROJ-123']!.status, 'Done');

    await tester.tap(find.byKey(const Key('task-jira-menu-task-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(JiraTaskActions.menuRefreshKey));
    await tester.pumpAndSettle();

    expect((await tasks.findById('task-1'))!.jiraLink!.lastKnownStatus, 'Done');
    expect(find.byType(DivergenceBanner), findsNothing);
  });

  testWidgets('S02-E2E-02: the banner survives a rebuild until decided', (
    WidgetTester tester,
  ) async {
    await bootApp(tester);
    await refreshThroughUi(tester);

    // A rebuild is not a decision. The banner is derived from stored state,
    // so it comes back exactly as it was.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await bootApp(tester);

    expect(find.byType(DivergenceBanner), findsOneWidget);
    expect((await tasks.findById('task-1'))!.status, TaskStatus.done);
  });
}
