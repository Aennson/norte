import 'package:flutter_test/flutter_test.dart';
import 'package:norte/application/usecases/refresh_jira_status.dart';
import 'package:norte/application/usecases/sync_linked_tasks.dart';
import 'package:norte/domain/entities/jira_issue_snapshot.dart';
import 'package:norte/domain/entities/jira_link.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/failures/result.dart';

import '../fakes/fakes.dart';
import '../support/task_fixtures.dart';

void main() {
  final DateTime t0 = DateTime.utc(2026, 1, 1, 9);

  /// When the refresh runs.
  final DateTime t1 = DateTime.utc(2026, 1, 1, 16);

  late FakeTaskRepository repository;
  late FakeJiraGateway jira;
  late FakeClock clock;
  late RefreshJiraStatus refresh;
  late Task divergent;

  setUp(() {
    // Local status `done`, cache says "In Progress", the site will say
    // "To Do" — three different values, so the test can tell which one each
    // assertion is really about.
    divergent = Task(
      id: 'task-1',
      title: 'Review the connector PR',
      status: TaskStatus.done,
      createdAt: t0,
      updatedAt: t0,
      jiraLink: JiraLink(
        issueKey: 'PROJ-123',
        siteUrl: 'https://example.atlassian.net',
        lastKnownStatus: 'In Progress',
        lastSyncedAt: t0,
      ),
    );

    repository = FakeTaskRepository(<Task>[divergent]);
    jira = FakeJiraGateway.fromFixture();
    jira.issues['PROJ-123'] = const JiraIssueSnapshot(
      issueKey: 'PROJ-123',
      siteUrl: 'https://example.atlassian.net',
      status: 'To Do',
    );
    clock = FakeClock(t1);
    refresh = RefreshJiraStatus(
      repository: repository,
      gateway: jira,
      clock: clock,
    );
  });

  tearDown(() => repository.dispose());

  test('S02-UT-04: a divergence is reported, never resolved (BR-02)', () async {
    final Result<JiraRefresh> result = await refresh(divergent);

    final JiraRefresh found = (result as Ok<JiraRefresh>).value;
    expect(found.hasDivergence, isTrue);
    expect(found.remoteStatus, 'To Do');

    // The local status is exactly what it was. This is the assertion BR-02
    // lives or dies on: the app saw a conflict and changed nothing.
    expect(found.task.status, TaskStatus.done);

    // The display cache moved, because that is all it is (BR-09).
    expect(found.task.jiraLink!.lastKnownStatus, 'To Do');
    expect(found.task.jiraLink!.lastSyncedAt, t1);

    // …and the same thing is what got stored.
    final Task stored = (await repository.findById('task-1'))!;
    expect(stored.status, TaskStatus.done);
    expect(stored.jiraLink!.lastKnownStatus, 'To Do');
    expect(stored.jiraLink!.lastSyncedAt, t1);

    // Nothing was pushed back to the site either.
    expect(jira.writes, isEmpty);
  });

  test('S02-UT-04: agreement is not a divergence', () async {
    jira.issues['PROJ-123'] = const JiraIssueSnapshot(
      issueKey: 'PROJ-123',
      siteUrl: 'https://example.atlassian.net',
      status: 'Done',
    );

    final Result<JiraRefresh> result = await refresh(divergent);

    final JiraRefresh found = (result as Ok<JiraRefresh>).value;
    expect(found.hasDivergence, isFalse);
    expect(found.task.jiraLink!.lastKnownStatus, 'Done');
    expect(found.task.status, TaskStatus.done);
  });

  test('a status this app cannot read is not called a divergence', () async {
    jira.issues['PROJ-123'] = const JiraIssueSnapshot(
      issueKey: 'PROJ-123',
      siteUrl: 'https://example.atlassian.net',
      status: 'Awaiting Legal Review',
    );

    final Result<JiraRefresh> result = await refresh(divergent);

    final JiraRefresh found = (result as Ok<JiraRefresh>).value;
    // Reported and cached, so the user can see it…
    expect(found.remoteStatus, 'Awaiting Legal Review');
    expect(found.task.jiraLink!.lastKnownStatus, 'Awaiting Legal Review');
    // …but not turned into a decision nobody could reason about.
    expect(found.hasDivergence, isFalse);
  });

  test('refreshing an unlinked task fails without a call', () async {
    final Result<JiraRefresh> result = await refresh(
      divergent.copyWith(jiraLink: null),
    );

    expect((result as Err<JiraRefresh>).failure, isA<NotLinkedFailure>());
    expect(jira.reads, isEmpty);
  });

  test('a transport failure leaves the previous cache standing', () async {
    jira.failWith = const NetworkFailure();

    final Result<JiraRefresh> result = await refresh(divergent);

    expect((result as Err<JiraRefresh>).failure, isA<NetworkFailure>());
    final Task stored = (await repository.findById('task-1'))!;
    expect(stored.jiraLink!.lastKnownStatus, 'In Progress');
    expect(stored.jiraLink!.lastSyncedAt, t0);
  });

  test('an issue deleted in Jira reads as a missing key', () async {
    jira.issues.remove('PROJ-123');

    final Result<JiraRefresh> result = await refresh(divergent);

    expect(
      (result as Err<JiraRefresh>).failure,
      isA<JiraIssueNotFoundFailure>(),
    );
  });

  group('SyncLinkedTasks', () {
    test('asks only about linked, unfinished tasks', () async {
      final Task open = divergent.copyWith(
        id: 'task-open',
        status: TaskStatus.inProgress,
        jiraLink: const JiraLink(
          issueKey: 'NORTE-2',
          siteUrl: 'https://example.atlassian.net',
        ),
      );
      final Task plain = Task(
        id: 'task-plain',
        title: 'no ticket here',
        createdAt: t0,
        updatedAt: t0,
      );
      await repository.save(open);
      await repository.save(plain);

      final List<JiraRefresh> divergences = await SyncLinkedTasks(
        repository: repository,
        refresh: refresh,
      )();

      // `divergent` is done and `plain` has no link, so only the open linked
      // task was worth a request — and NORTE-2 is "In Progress" on the site,
      // which is where the task is locally, so there is nothing to decide.
      expect(jira.reads, <String>['NORTE-2']);
      expect(divergences, isEmpty);
    });

    test('collects the divergences it finds', () async {
      await repository.save(divergent.copyWith(status: TaskStatus.inProgress));

      final List<JiraRefresh> divergences = await SyncLinkedTasks(
        repository: repository,
        refresh: refresh,
      )();

      expect(divergences, hasLength(1));
      expect(divergences.single.remoteStatus, 'To Do');
      // Still nothing resolved (BR-02).
      expect(
        (await repository.findById('task-1'))!.status,
        TaskStatus.inProgress,
      );
    });

    test('one unreachable issue does not abort the pass', () async {
      await repository.save(divergent.copyWith(status: TaskStatus.inProgress));
      await repository.save(
        divergent.copyWith(
          id: 'task-2',
          status: TaskStatus.inProgress,
          jiraLink: const JiraLink(
            issueKey: 'GONE-9',
            siteUrl: 'https://example.atlassian.net',
          ),
        ),
      );

      final List<JiraRefresh> divergences = await SyncLinkedTasks(
        repository: repository,
        refresh: refresh,
      )();

      expect(jira.reads, containsAll(<String>['PROJ-123', 'GONE-9']));
      expect(divergences, hasLength(1));
    });
  });
}
