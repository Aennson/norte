import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/entities/jira_link.dart';
import 'package:norte/domain/entities/outbox_operation.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/l10n/generated/app_localizations.dart';
import 'package:norte/presentation/jira/jira_failure_text.dart';
import 'package:norte/presentation/jira/jira_providers.dart';
import 'package:norte/presentation/jira/jira_task_actions.dart';
import 'package:norte/presentation/jira/widgets/divergence_banner.dart';
import 'package:norte/presentation/jira/widgets/sync_indicator.dart';
import 'package:norte/presentation/shared/theme/norte_theme.dart';
import 'package:norte/presentation/tasks/task_providers.dart';
import 'package:norte/presentation/tasks/tasks_screen.dart';

import '../fakes/fakes.dart';
import '../support/task_fixtures.dart';

/// Widget-level cover for the Jira actions and indicators.
///
/// The E2E suite proves these flows end to end against a real database; this
/// runs the same surfaces against fakes, where a failure can be provoked on
/// demand — a rate limit, a rejected credential, a site that is not
/// configured at all.
void main() {
  final DateTime t0 = DateTime.utc(2026, 1, 1, 9);

  late FakeTaskRepository tasks;
  late FakeOutboxRepository outbox;
  late FakeJiraGateway jira;
  late FakeJiraCredentialStore credentials;
  late List<String> dispatched;
  late List<String> retried;
  late Task linked;

  setUp(() {
    linked = Task(
      id: 'task-1',
      title: 'Review the connector PR',
      status: TaskStatus.inProgress,
      createdAt: t0,
      updatedAt: t0,
      jiraLink: JiraLink(
        issueKey: 'PROJ-123',
        siteUrl: 'https://example.atlassian.net',
        lastKnownStatus: 'In Progress',
        lastSyncedAt: t0,
      ),
    );

    tasks = FakeTaskRepository(<Task>[linked]);
    outbox = FakeOutboxRepository();
    jira = FakeJiraGateway.fromFixture();
    credentials = FakeJiraCredentialStore.configured();
    dispatched = <String>[];
    retried = <String>[];
  });

  tearDown(() async {
    await tasks.dispose();
    await outbox.dispose();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          taskRepositoryProvider.overrideWithValue(tasks),
          clockProvider.overrideWithValue(FakeClock(t0)),
          idGeneratorProvider.overrideWithValue(
            FakeIdGenerator.sequence(<String>['op-1', 'op-2']),
          ),
          outboxRepositoryProvider.overrideWithValue(outbox),
          jiraGatewayProvider.overrideWithValue(jira),
          jiraCredentialStoreProvider.overrideWithValue(credentials),
          outboxDispatchProvider.overrideWithValue(() async {
            dispatched.add('dispatch');
          }),
          outboxRetryProvider.overrideWithValue((String id) async {
            retried.add(id);
          }),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: NorteTheme.dark,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: TasksScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester, [String id = 'task-1']) async {
    await tester.tap(find.byKey(Key('task-jira-menu-$id')));
    await tester.pumpAndSettle();
  }

  Future<void> typeAndConfirm(
    WidgetTester tester,
    Key field,
    String text,
  ) async {
    await tester.enterText(
      find.descendant(of: find.byKey(field), matching: find.byType(TextField)),
      text,
    );
    await tester.tap(find.byKey(JiraTaskActions.confirmButtonKey));
    await tester.pumpAndSettle();
  }

  group('the action sheet', () {
    testWidgets('offers the linked actions on a linked task', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await openMenu(tester);

      expect(find.byKey(JiraTaskActions.menuRefreshKey), findsOneWidget);
      expect(find.byKey(JiraTaskActions.menuPushStatusKey), findsOneWidget);
      expect(find.byKey(JiraTaskActions.menuCommentKey), findsOneWidget);
      expect(find.byKey(JiraTaskActions.menuUnlinkKey), findsOneWidget);
      // Nothing that would make a second issue for a task that has one.
      expect(find.byKey(JiraTaskActions.menuLinkKey), findsNothing);
      expect(find.byKey(JiraTaskActions.menuCreateIssueKey), findsNothing);
    });

    testWidgets('offers the unlinked actions on a plain task', (
      WidgetTester tester,
    ) async {
      await tasks.save(linked.copyWith(jiraLink: null));
      await pump(tester);
      await openMenu(tester);

      expect(find.byKey(JiraTaskActions.menuLinkKey), findsOneWidget);
      expect(find.byKey(JiraTaskActions.menuCreateIssueKey), findsOneWidget);
      expect(find.byKey(JiraTaskActions.menuRefreshKey), findsNothing);
    });

    testWidgets('refuses to open when Jira is not configured', (
      WidgetTester tester,
    ) async {
      credentials = FakeJiraCredentialStore();
      await pump(tester);
      await openMenu(tester);

      expect(
        find.text('Connect a Jira site in Settings first.'),
        findsOneWidget,
      );
      expect(find.byKey(JiraTaskActions.menuRefreshKey), findsNothing);
    });

    testWidgets('dismissing it does nothing at all', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await openMenu(tester);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(outbox.operations, isEmpty);
      expect(jira.writes, isEmpty);
      expect(jira.reads, isEmpty);
    });
  });

  group('linking', () {
    testWidgets('a valid key attaches the issue', (WidgetTester tester) async {
      await tasks.save(linked.copyWith(jiraLink: null));
      await pump(tester);
      await openMenu(tester);
      await tester.tap(find.byKey(JiraTaskActions.menuLinkKey));
      await tester.pumpAndSettle();

      await typeAndConfirm(tester, JiraTaskActions.issueKeyFieldKey, 'NORTE-1');

      expect((await tasks.findById('task-1'))!.jiraLink!.issueKey, 'NORTE-1');
      expect(find.text('NORTE-1'), findsOneWidget);
    });

    testWidgets('a key the site does not have is reported', (
      WidgetTester tester,
    ) async {
      await tasks.save(linked.copyWith(jiraLink: null));
      await pump(tester);
      await openMenu(tester);
      await tester.tap(find.byKey(JiraTaskActions.menuLinkKey));
      await tester.pumpAndSettle();

      await typeAndConfirm(tester, JiraTaskActions.issueKeyFieldKey, 'NOPE-1');

      expect(find.text('This site has no issue NOPE-1.'), findsOneWidget);
      expect((await tasks.findById('task-1'))!.jiraLink, isNull);
    });

    testWidgets('an empty key cancels rather than linking', (
      WidgetTester tester,
    ) async {
      await tasks.save(linked.copyWith(jiraLink: null));
      await pump(tester);
      await openMenu(tester);
      await tester.tap(find.byKey(JiraTaskActions.menuLinkKey));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(JiraTaskActions.confirmButtonKey));
      await tester.pumpAndSettle();

      expect((await tasks.findById('task-1'))!.jiraLink, isNull);
      expect(jira.reads, isEmpty);
    });

    testWidgets('cancelling the dialog links nothing', (
      WidgetTester tester,
    ) async {
      await tasks.save(linked.copyWith(jiraLink: null));
      await pump(tester);
      await openMenu(tester);
      await tester.tap(find.byKey(JiraTaskActions.menuLinkKey));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect((await tasks.findById('task-1'))!.jiraLink, isNull);
    });
  });

  group('unlinking', () {
    testWidgets('removes the reference and leaves the task', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await openMenu(tester);
      await tester.tap(find.byKey(JiraTaskActions.menuUnlinkKey));
      await tester.pumpAndSettle();

      final Task stored = (await tasks.findById('task-1'))!;
      expect(stored.jiraLink, isNull);
      expect(stored.title, linked.title);
      expect(find.text('PROJ-123'), findsNothing);
      expect(find.text(linked.title), findsOneWidget);
    });
  });

  group('queued writes', () {
    testWidgets('pushing the status queues a transition', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await openMenu(tester);
      await tester.tap(find.byKey(JiraTaskActions.menuPushStatusKey));
      await tester.pumpAndSettle();

      expect(outbox.operations.single.kind, OutboxOperationKind.transition);
      expect(outbox.operations.single.payload, 'In Progress');
      expect(jira.writes, isEmpty);
      expect(find.textContaining('Queued'), findsOneWidget);
    });

    testWidgets('commenting queues the text that was typed', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await openMenu(tester);
      await tester.tap(find.byKey(JiraTaskActions.menuCommentKey));
      await tester.pumpAndSettle();

      await typeAndConfirm(
        tester,
        JiraTaskActions.commentFieldKey,
        'staging is green',
      );

      expect(outbox.operations.single.kind, OutboxOperationKind.comment);
      expect(outbox.operations.single.payload, 'staging is green');
      expect(jira.writes, isEmpty);
    });

    testWidgets('creating an issue queues it against the project', (
      WidgetTester tester,
    ) async {
      await tasks.save(linked.copyWith(jiraLink: null));
      await pump(tester);
      await openMenu(tester);
      await tester.tap(find.byKey(JiraTaskActions.menuCreateIssueKey));
      await tester.pumpAndSettle();

      await typeAndConfirm(tester, JiraTaskActions.projectKeyFieldKey, 'proj');

      expect(outbox.operations.single.kind, OutboxOperationKind.createIssue);
      expect(outbox.operations.single.issueKey, 'PROJ');
      expect(jira.writes, isEmpty);
    });

    testWidgets('a rejected enqueue is reported, not swallowed', (
      WidgetTester tester,
    ) async {
      outbox.failWith = const StorageFailure();
      await pump(tester);
      await openMenu(tester);

      await tester.tap(find.byKey(JiraTaskActions.menuPushStatusKey));
      await tester.pumpAndSettle();

      expect(find.text('Jira could not be reached.'), findsOneWidget);
    });
  });

  group('refreshing', () {
    testWidgets('a failure reaches the user', (WidgetTester tester) async {
      jira.failWith = const RateLimitFailure();
      await pump(tester);
      await openMenu(tester);

      await tester.tap(find.byKey(JiraTaskActions.menuRefreshKey));
      await tester.pumpAndSettle();

      expect(
        find.text('Jira is throttling requests. Try again shortly.'),
        findsOneWidget,
      );
    });

    testWidgets('a divergence found by a refresh raises the banner', (
      WidgetTester tester,
    ) async {
      // Local and cached agree, so nothing is showing yet — the disagreement
      // has to be discovered by the refresh.
      await tasks.save(
        linked.copyWith(
          status: TaskStatus.done,
          jiraLink: linked.jiraLink!.copyWith(lastKnownStatus: 'Done'),
        ),
      );
      await pump(tester);
      expect(find.byType(DivergenceBanner), findsNothing);

      await openMenu(tester);
      await tester.tap(find.byKey(JiraTaskActions.menuRefreshKey));
      await tester.pumpAndSettle();

      expect(find.byType(DivergenceBanner), findsOneWidget);
      // Nothing decided (BR-02).
      expect((await tasks.findById('task-1'))!.status, TaskStatus.done);
      expect(outbox.operations, isEmpty);
    });
  });

  group('the divergence decisions', () {
    setUp(() async {
      await tasks.save(
        linked.copyWith(
          status: TaskStatus.done,
          jiraLink: linked.jiraLink!.copyWith(lastKnownStatus: 'To Do'),
        ),
      );
    });

    testWidgets('keep local queues a transition and moves nothing', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      expect(find.byType(DivergenceBanner), findsOneWidget);

      await tester.tap(find.text('Keep local'));
      await tester.pumpAndSettle();

      expect((await tasks.findById('task-1'))!.status, TaskStatus.done);
      expect(outbox.operations.single.payload, 'Done');
      expect(jira.writes, isEmpty);
    });

    testWidgets('adopt from Jira moves the task and queues nothing', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Adopt from Jira'));
      await tester.pumpAndSettle();

      expect((await tasks.findById('task-1'))!.status, TaskStatus.todo);
      expect(outbox.operations, isEmpty);
      expect(find.byType(DivergenceBanner), findsNothing);
    });

    testWidgets('a status the app cannot read raises no banner', (
      WidgetTester tester,
    ) async {
      await tasks.save(
        linked.copyWith(
          status: TaskStatus.done,
          jiraLink: linked.jiraLink!.copyWith(
            lastKnownStatus: 'Awaiting Legal Review',
          ),
        ),
      );
      await pump(tester);

      expect(find.byType(DivergenceBanner), findsNothing);
    });
  });

  group('SyncIndicator', () {
    testWidgets('says nothing when the queue is empty', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      expect(find.byType(SyncIndicator), findsOneWidget);
      expect(find.textContaining('sync'), findsNothing);
    });

    testWidgets('counts what is waiting, in the singular and the plural', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await openMenu(tester);
      await tester.tap(find.byKey(JiraTaskActions.menuPushStatusKey));
      await tester.pumpAndSettle();

      expect(find.text('1 change waiting to sync'), findsOneWidget);

      await openMenu(tester);
      await tester.tap(find.byKey(JiraTaskActions.menuPushStatusKey));
      await tester.pumpAndSettle();

      expect(find.text('2 changes waiting to sync'), findsOneWidget);
    });

    testWidgets('a failed operation offers the manual retry', (
      WidgetTester tester,
    ) async {
      await outbox.enqueue(
        OutboxOperation(
          operationId: 'op-9',
          kind: OutboxOperationKind.transition,
          issueKey: 'PROJ-123',
          payload: 'Done',
          createdAt: t0,
          state: OutboxOperationState.failed,
          attempts: 5,
          lastError: 'rate limited',
        ),
      );
      await pump(tester);

      expect(find.text('1 change could not be sent'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(retried, <String>['op-9']);
      expect(dispatched, <String>['dispatch']);
    });
  });

  group('jiraFailureText', () {
    testWidgets('names something the user can act on for each failure', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(TasksScreen)),
      );

      expect(
        jiraFailureText(l10n, const JiraIssueNotFoundFailure('PROJ-9')),
        contains('PROJ-9'),
      );
      expect(
        jiraFailureText(l10n, const NetworkFailure()),
        l10n.jiraErrorOffline,
      );
      expect(
        jiraFailureText(l10n, const TimeoutFailure()),
        l10n.jiraErrorOffline,
      );
      expect(jiraFailureText(l10n, const AuthFailure()), l10n.jiraErrorAuth);
      expect(
        jiraFailureText(l10n, const RateLimitFailure()),
        l10n.jiraErrorRateLimited,
      );
      expect(
        jiraFailureText(l10n, const StorageFailure()),
        l10n.jiraErrorGeneric,
      );
    });
  });
}
