import 'package:flutter_test/flutter_test.dart';
import 'package:norte/application/usecases/link_task_to_jira.dart';
import 'package:norte/application/usecases/unlink_task.dart';
import 'package:norte/domain/entities/jira_link.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/failures/result.dart';

import '../fakes/fakes.dart';
import '../support/task_fixtures.dart';

void main() {
  /// When the task was created.
  final DateTime t0 = DateTime.utc(2026, 1, 1, 9);

  /// When the link is made — strictly after [t0], so a preserved `createdAt`
  /// is distinguishable from a rewritten one.
  final DateTime t1 = DateTime.utc(2026, 1, 1, 14, 30);

  late FakeTaskRepository repository;
  late FakeJiraGateway jira;
  late FakeOutboxRepository outbox;
  late FakeClock clock;
  late LinkTaskToJira link;
  late UnlinkTask unlink;
  late Task existing;

  setUp(() async {
    existing = Task(
      id: 'task-1',
      title: 'Review the connector PR',
      description: 'Second pass on the retry logic.',
      status: TaskStatus.inProgress,
      priority: Priority.urgent,
      dueDate: DateTime.utc(2026, 1, 5, 18),
      tags: const <String>['api', 'urgent'],
      createdAt: t0,
      updatedAt: t0,
    );

    repository = FakeTaskRepository(<Task>[existing]);
    jira = FakeJiraGateway.fromFixture();
    outbox = FakeOutboxRepository();
    clock = FakeClock(t1);
    link = LinkTaskToJira(
      repository: repository,
      gateway: jira,
      clock: clock,
    );
    unlink = UnlinkTask(repository: repository, clock: clock);
  });

  tearDown(() async {
    await repository.dispose();
    await outbox.dispose();
  });

  test(
    'S02-UT-01: linking then unlinking leaves the task otherwise untouched',
    () async {
      final Result<Task> linked = await link(
        taskId: 'task-1',
        issueKey: 'PROJ-123',
      );

      // Linked: the reference is there, and it holds only the four fields
      // BR-09 allows.
      final Task withLink = (linked as Ok<Task>).value;
      expect(withLink.jiraLink, isNotNull);
      expect(withLink.jiraLink!.issueKey, 'PROJ-123');
      expect(withLink.jiraLink!.siteUrl, 'https://example.atlassian.net');
      expect(withLink.jiraLink!.lastKnownStatus, 'In Progress');
      expect(withLink.jiraLink!.lastSyncedAt, t1);

      // BR-01 — everything the task was is still what it is.
      expect(withLink.id, existing.id);
      expect(withLink.title, existing.title);
      expect(withLink.description, existing.description);
      expect(withLink.status, existing.status);
      expect(withLink.priority, existing.priority);
      expect(withLink.dueDate, existing.dueDate);
      expect(withLink.tags, existing.tags);
      expect(withLink.createdAt, t0);
      expect(await repository.findById('task-1'), withLink);

      final Result<Task> unlinked = await unlink(taskId: 'task-1');

      // Unlinked: the link is gone and the task is still a task.
      final Task withoutLink = (unlinked as Ok<Task>).value;
      expect(withoutLink.jiraLink, isNull);
      expect(withoutLink.id, existing.id);
      expect(withoutLink.title, existing.title);
      expect(withoutLink.status, existing.status);
      expect(withoutLink.priority, existing.priority);
      expect(withoutLink.dueDate, existing.dueDate);
      expect(withoutLink.tags, existing.tags);
      expect(withoutLink.createdAt, t0);
      expect(await repository.findById('task-1'), withoutLink);
    },
  );

  test('S02-UT-02: linking a key the site does not have', () async {
    final Result<Task> result = await link(
      taskId: 'task-1',
      issueKey: 'NOPE-1',
    );

    expect(result, isA<Err<Task>>());
    expect(
      (result as Err<Task>).failure,
      isA<JiraIssueNotFoundFailure>().having(
        (JiraIssueNotFoundFailure f) => f.issueKey,
        'issueKey',
        'NOPE-1',
      ),
    );

    // The task is untouched…
    final Task? stored = await repository.findById('task-1');
    expect(stored!.jiraLink, isNull);
    expect(stored, existing);
    expect(repository.savedIds, isEmpty);

    // …and nothing was queued: linking is not a write, so a failed link has
    // nothing to retry later (`sprint-02` validation rules).
    expect(outbox.operations, isEmpty);
  });

  test(
    'S02-UT-02: with no network the link is refused, never queued',
    () async {
      jira.failWith = const NetworkFailure();

      final Result<Task> result = await link(
        taskId: 'task-1',
        issueKey: 'PROJ-123',
      );

      expect((result as Err<Task>).failure, isA<NetworkFailure>());
      expect((await repository.findById('task-1'))!.jiraLink, isNull);
      expect(outbox.operations, isEmpty);
    },
  );

  test('S02-UT-02: a blank key never reaches the site', () async {
    final Result<Task> result = await link(taskId: 'task-1', issueKey: '   ');

    expect(
      (result as Err<Task>).failure,
      isA<ValidationFailure>().having(
        (ValidationFailure f) => f.field,
        'field',
        'issueKey',
      ),
    );
    expect(jira.reads, isEmpty);
  });

  test('the key is normalised before it is looked up', () async {
    final Result<Task> result = await link(
      taskId: 'task-1',
      issueKey: '  proj-123 ',
    );

    expect(result, isA<Ok<Task>>());
    expect(jira.reads, <String>['PROJ-123']);
  });

  test('linking an unknown task fails before the site is asked', () async {
    final Result<Task> result = await link(
      taskId: 'ghost',
      issueKey: 'PROJ-123',
    );

    expect((result as Err<Task>).failure, isA<NotFoundFailure>());
    expect(jira.reads, isEmpty);
  });

  test('unlinking a task that has no link is not an error', () async {
    final Result<Task> result = await unlink(taskId: 'task-1');

    expect((result as Ok<Task>).value.jiraLink, isNull);
  });

  test('unlinking an unknown task fails', () async {
    final Result<Task> result = await unlink(taskId: 'ghost');

    expect((result as Err<Task>).failure, isA<NotFoundFailure>());
  });

  test('unlinking never touches the site', () async {
    await link(taskId: 'task-1', issueKey: 'PROJ-123');
    jira.reset();

    await unlink(taskId: 'task-1');

    expect(jira.writes, isEmpty);
    expect(jira.reads, isEmpty);
  });

  test('a rejected credential is passed through as it came', () async {
    jira.failWith = const AuthFailure();

    final Result<Task> result = await link(
      taskId: 'task-1',
      issueKey: 'PROJ-123',
    );

    expect((result as Err<Task>).failure, isA<AuthFailure>());
  });

  test('linking replaces a link the task already had', () async {
    await repository.save(
      existing.copyWith(
        jiraLink: const JiraLink(
          issueKey: 'OLD-1',
          siteUrl: 'https://example.atlassian.net',
        ),
      ),
    );

    final Result<Task> result = await link(
      taskId: 'task-1',
      issueKey: 'NORTE-2',
    );

    expect((result as Ok<Task>).value.jiraLink!.issueKey, 'NORTE-2');
  });
}
