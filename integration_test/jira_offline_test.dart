import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:norte/domain/entities/jira_link.dart';
import 'package:norte/domain/entities/outbox_operation.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/infrastructure/jira/outbox_dispatcher.dart';
import 'package:norte/infrastructure/persistence/drift_outbox_repository.dart';
import 'package:norte/infrastructure/persistence/drift_task_repository.dart';
import 'package:norte/infrastructure/persistence/norte_database.dart';
import 'package:norte/infrastructure/persistence/norte_database_factory.dart';
import 'package:norte/presentation/app/norte_app.dart';
import 'package:norte/presentation/jira/jira_providers.dart';
import 'package:norte/presentation/jira/jira_task_actions.dart';
import 'package:norte/presentation/tasks/task_providers.dart';

import '../test/fakes/fake_clock.dart';
import '../test/fakes/fake_jira_credential_store.dart';
import '../test/fakes/fake_jira_gateway.dart';

/// S02-E2E-01 — a Jira write made offline, settled when the network returns.
///
/// This is the scenario the outbox exists for, driven the way a user would
/// drive it: the app boots from the real composition root with only the
/// database and the gateway replaced (`docs/testing-strategy.md` §4.2), and
/// every step checks both what the user sees and what the system did.
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
    jira = FakeJiraGateway.fromFixture('test/fixtures/jira_issues.json');
    // A pinned clock, so the backoff window between attempts is something the
    // test moves through rather than something it waits out.
    clock = FakeClock(t0);
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
        createdAt: t0,
        updatedAt: t0,
        jiraLink: JiraLink(
          issueKey: 'PROJ-123',
          siteUrl: 'https://example.atlassian.net',
          lastKnownStatus: 'In Progress',
          lastSyncedAt: t0,
        ),
      ),
    );
  });

  tearDown(() => database.close());

  Future<void> bootApp(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = <Locale>[const Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.view.physicalSize = const Size(1280, 900);
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

  testWidgets('S02-E2E-01: a status pushed offline reaches Jira later', (
    WidgetTester tester,
  ) async {
    await bootApp(tester);
    expect(find.text('PROJ-123'), findsOneWidget);

    // --- the network is down ------------------------------------------
    jira.failWith = const NetworkFailure();

    await tester.tap(find.byKey(const Key('task-jira-menu-task-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(JiraTaskActions.menuPushStatusKey));
    await tester.pumpAndSettle();

    // The user is told it is queued, not that it failed…
    expect(
      find.text(
        'Queued — it will reach Jira as soon as there is a '
        'connection.',
      ),
      findsOneWidget,
    );

    // …the indicator says something is waiting…
    expect(find.text('1 change waiting to sync'), findsOneWidget);

    // …the operation is really in the queue, carrying its idempotency key…
    List<OutboxOperation> queued = await outbox.unsettled();
    expect(queued, hasLength(1));
    expect(queued.single.kind, OutboxOperationKind.transition);
    expect(queued.single.issueKey, 'PROJ-123');
    expect(queued.single.payload, 'To Do');
    expect(queued.single.operationId, isNotEmpty);

    // …and nothing at all reached the site (BR-05).
    expect(jira.writes, isEmpty);

    // A dispatch while the network is down changes nothing but the attempt
    // count — the user's action is not lost.
    await dispatcher.dispatch();
    expect(jira.writes, isEmpty);
    expect((await outbox.unsettled()).single.attempts, 1);

    // --- the network comes back ---------------------------------------
    jira.failWith = null;
    // Past the two-second backoff window the failed attempt opened.
    clock.advance(const Duration(seconds: 3));
    await dispatcher.dispatch();
    await tester.pumpAndSettle();

    // Applied exactly once…
    expect(jira.writesFor('PROJ-123'), hasLength(1));
    expect(jira.writesFor('PROJ-123').single.kind, 'transition');
    expect(jira.issues['PROJ-123']!.status, 'To Do');

    // …the queue is settled…
    queued = await outbox.unsettled();
    expect(queued, isEmpty);

    // …and the indicator is gone from the screen.
    expect(find.textContaining('waiting to sync'), findsNothing);

    // A refresh now brings the cache in line with what was sent.
    await tester.tap(find.byKey(const Key('task-jira-menu-task-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(JiraTaskActions.menuRefreshKey));
    await tester.pumpAndSettle();

    expect(
      (await tasks.findById('task-1'))!.jiraLink!.lastKnownStatus,
      'To Do',
    );
  });

  testWidgets('S02-E2E-01: a queued comment survives to the next dispatch', (
    WidgetTester tester,
  ) async {
    await bootApp(tester);
    jira.failWith = const NetworkFailure();

    await tester.tap(find.byKey(const Key('task-jira-menu-task-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(JiraTaskActions.menuCommentKey));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byKey(JiraTaskActions.commentFieldKey),
        matching: find.byType(TextField),
      ),
      'staging is green',
    );
    await tester.tap(find.byKey(JiraTaskActions.confirmButtonKey));
    await tester.pumpAndSettle();

    expect((await outbox.unsettled()).single.payload, 'staging is green');
    expect(jira.writes, isEmpty);

    jira.failWith = null;
    await dispatcher.dispatch();

    expect(jira.writesFor('PROJ-123').single.value, 'staging is green');
    expect(await outbox.unsettled(), isEmpty);
  });

  testWidgets(
    'S02-E2E-01: an operation out of attempts offers a manual retry',
    (WidgetTester tester) async {
      await bootApp(tester);

      // A rejected credential is not worth retrying on a schedule, so the
      // first attempt settles it as failed.
      jira.failWith = const AuthFailure();
      await tester.tap(find.byKey(const Key('task-jira-menu-task-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(JiraTaskActions.menuPushStatusKey));
      await tester.pumpAndSettle();

      await dispatcher.dispatch();
      await tester.pumpAndSettle();

      expect(find.text('1 change could not be sent'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // The user fixes the credentials and retries by hand.
      jira.failWith = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(jira.writesFor('PROJ-123'), hasLength(1));
      expect(await outbox.unsettled(), isEmpty);
      expect(find.textContaining('could not be sent'), findsNothing);
    },
  );
}
