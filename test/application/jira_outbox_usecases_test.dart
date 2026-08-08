import 'package:flutter_test/flutter_test.dart';
import 'package:norte/application/usecases/add_jira_comment.dart';
import 'package:norte/application/usecases/create_jira_issue_from_task.dart';
import 'package:norte/application/usecases/update_jira_status.dart';
import 'package:norte/domain/entities/jira_link.dart';
import 'package:norte/domain/entities/outbox_operation.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/failures/result.dart';

import '../fakes/fakes.dart';

void main() {
  final DateTime t0 = DateTime.utc(2026, 1, 1, 9);

  late FakeOutboxRepository outbox;
  late FakeJiraGateway jira;
  late FakeClock clock;
  late FakeIdGenerator ids;
  late UpdateJiraStatus updateStatus;
  late AddJiraComment addComment;
  late CreateJiraIssueFromTask createIssue;
  late Task linked;
  late Task unlinked;

  setUp(() {
    unlinked = Task(
      id: 'task-1',
      title: 'Review the connector PR',
      status: TaskStatus.inProgress,
      createdAt: t0,
      updatedAt: t0,
    );
    linked = unlinked.copyWith(
      jiraLink: const JiraLink(
        issueKey: 'PROJ-123',
        siteUrl: 'https://example.atlassian.net',
        lastKnownStatus: 'In Progress',
      ),
    );

    outbox = FakeOutboxRepository();
    jira = FakeJiraGateway.fromFixture();
    clock = FakeClock(t0);
    ids = FakeIdGenerator.sequence(<String>['op-1', 'op-2', 'op-3']);
    updateStatus = UpdateJiraStatus(
      outbox: outbox,
      clock: clock,
      idGenerator: ids,
    );
    addComment = AddJiraComment(outbox: outbox, clock: clock, idGenerator: ids);
    createIssue = CreateJiraIssueFromTask(
      outbox: outbox,
      clock: clock,
      idGenerator: ids,
    );
  });

  tearDown(() => outbox.dispose());

  test('S02-UT-03: a status change is queued, never sent (BR-05)', () async {
    final Result<OutboxOperation> result = await updateStatus(
      task: linked,
      status: 'Done',
    );

    // Exactly one pending operation, carrying what the dispatcher will need.
    expect(outbox.pendingOperations, hasLength(1));
    final OutboxOperation queued = outbox.pendingOperations.single;
    expect(queued.operationId, 'op-1');
    expect(queued.kind, OutboxOperationKind.transition);
    expect(queued.issueKey, 'PROJ-123');
    expect(queued.payload, 'Done');
    expect(queued.taskId, 'task-1');
    expect(queued.state, OutboxOperationState.pending);
    expect(queued.attempts, 0);
    expect(queued.nextAttemptAt, isNull);
    expect(queued.createdAt, t0);
    expect((result as Ok<OutboxOperation>).value, queued);

    // And the gateway heard nothing at all — no read, no write. This is the
    // assertion BR-05 lives or dies on.
    expect(jira.writes, isEmpty);
    expect(jira.reads, isEmpty);
  });

  test('S02-UT-03: a comment is queued, never sent (BR-05)', () async {
    await addComment(task: linked, body: 'deployed to staging');

    final OutboxOperation queued = outbox.pendingOperations.single;
    expect(queued.kind, OutboxOperationKind.comment);
    expect(queued.issueKey, 'PROJ-123');
    expect(queued.payload, 'deployed to staging');
    expect(jira.writes, isEmpty);
  });

  test('S02-UT-03: an issue creation is queued, never sent (BR-05)', () async {
    await createIssue(task: unlinked, projectKey: 'proj');

    final OutboxOperation queued = outbox.pendingOperations.single;
    expect(queued.kind, OutboxOperationKind.createIssue);
    // The project key, not an issue key — there is no issue yet.
    expect(queued.issueKey, 'PROJ');
    expect(queued.payload, unlinked.title);
    expect(queued.taskId, 'task-1');
    expect(jira.writes, isEmpty);
  });

  test('operations keep the order they were created in', () async {
    await updateStatus(task: linked, status: 'Done');
    await addComment(task: linked, body: 'and here is why');

    expect(
      outbox.operations.map((OutboxOperation o) => o.kind),
      <OutboxOperationKind>[
        OutboxOperationKind.transition,
        OutboxOperationKind.comment,
      ],
    );
    expect(outbox.operations.map((OutboxOperation o) => o.sequence), <int>[
      1,
      2,
    ]);
  });

  test('each operation gets its own idempotency key', () async {
    await updateStatus(task: linked, status: 'Done');
    await updateStatus(task: linked, status: 'Done');

    expect(
      outbox.operations.map((OutboxOperation o) => o.operationId),
      <String>['op-1', 'op-2'],
    );
  });

  group('an unlinked task cannot be written to', () {
    test('status', () async {
      final Result<OutboxOperation> result = await updateStatus(
        task: unlinked,
        status: 'Done',
      );

      expect((result as Err<OutboxOperation>).failure, isA<NotLinkedFailure>());
      expect(outbox.operations, isEmpty);
    });

    test('comment', () async {
      final Result<OutboxOperation> result = await addComment(
        task: unlinked,
        body: 'hello',
      );

      expect((result as Err<OutboxOperation>).failure, isA<NotLinkedFailure>());
      expect(outbox.operations, isEmpty);
    });
  });

  group('empty input is rejected before the queue is touched', () {
    test('status', () async {
      final Result<OutboxOperation> result = await updateStatus(
        task: linked,
        status: '  ',
      );

      expect(
        (result as Err<OutboxOperation>).failure,
        isA<ValidationFailure>().having(
          (ValidationFailure f) => f.field,
          'field',
          'status',
        ),
      );
      expect(outbox.operations, isEmpty);
    });

    test('comment', () async {
      final Result<OutboxOperation> result = await addComment(
        task: linked,
        body: '\n ',
      );

      expect(
        (result as Err<OutboxOperation>).failure,
        isA<ValidationFailure>().having(
          (ValidationFailure f) => f.field,
          'field',
          'body',
        ),
      );
      expect(outbox.operations, isEmpty);
    });

    test('project key', () async {
      final Result<OutboxOperation> result = await createIssue(
        task: unlinked,
        projectKey: '',
      );

      expect(
        (result as Err<OutboxOperation>).failure,
        isA<ValidationFailure>().having(
          (ValidationFailure f) => f.field,
          'field',
          'projectKey',
        ),
      );
      expect(outbox.operations, isEmpty);
    });
  });

  test('a task that already has an issue cannot create a second one', () async {
    final Result<OutboxOperation> result = await createIssue(
      task: linked,
      projectKey: 'PROJ',
    );

    expect(
      (result as Err<OutboxOperation>).failure,
      isA<ValidationFailure>().having(
        (ValidationFailure f) => f.field,
        'field',
        'jiraLink',
      ),
    );
    expect(outbox.operations, isEmpty);
  });

  test('a comment is trimmed before it is queued', () async {
    await addComment(task: linked, body: '  shipped  ');

    expect(outbox.operations.single.payload, 'shipped');
  });
}
