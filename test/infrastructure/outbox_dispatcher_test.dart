import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/entities/jira_link.dart';
import 'package:norte/domain/entities/outbox_operation.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/infrastructure/jira/outbox_dispatcher.dart';
import 'package:norte/infrastructure/persistence/drift_outbox_repository.dart';
import 'package:norte/infrastructure/persistence/drift_task_repository.dart';
import 'package:norte/infrastructure/persistence/norte_database.dart';
import 'package:norte/infrastructure/persistence/norte_database_factory.dart';

import '../fakes/fakes.dart';

void main() {
  final DateTime t0 = DateTime.utc(2026, 1, 1, 9);

  late NorteDatabase database;
  late DriftOutboxRepository outbox;
  late DriftTaskRepository tasks;
  late FakeJiraGateway jira;
  late FakeClock clock;
  late OutboxDispatcher dispatcher;

  /// Builds an operation with the fields a test does not care about filled in.
  OutboxOperation operation({
    required String operationId,
    OutboxOperationKind kind = OutboxOperationKind.transition,
    String issueKey = 'PROJ-123',
    String payload = 'Done',
    String? taskId,
  }) => OutboxOperation(
    operationId: operationId,
    kind: kind,
    issueKey: issueKey,
    payload: payload,
    taskId: taskId,
    createdAt: t0,
  );

  setUp(() {
    database = openInMemoryNorteDatabase();
    outbox = DriftOutboxRepository(database);
    tasks = DriftTaskRepository(database);
    jira = FakeJiraGateway.fromFixture();
    clock = FakeClock(t0);
    dispatcher = OutboxDispatcher(
      outbox: outbox,
      gateway: jira,
      tasks: tasks,
      clock: clock,
    );
  });

  tearDown(() => database.close());

  test('S02-IT-01: a lost response does not apply the operation twice', () async {
    await outbox.enqueue(operation(operationId: 'op-1'));

    // First dispatch: the site applies the transition and then the connection
    // drops before the answer arrives. From here it is indistinguishable from
    // the operation never having run.
    jira.failAfterApply = const TimeoutFailure();
    expect(await dispatcher.dispatch(), 0);

    final OutboxOperation afterLoss = (await outbox.findById('op-1'))!;
    expect(afterLoss.state, OutboxOperationState.pending);
    expect(afterLoss.attempts, 1);
    // The site did apply it, even though we could not know that.
    expect(jira.writesFor('PROJ-123'), hasLength(1));

    // Second dispatch: same operationId, so the site recognises the replay.
    jira.failAfterApply = null;
    clock.advance(const Duration(seconds: 2));
    expect(await dispatcher.dispatch(), 1);

    // Applied exactly once (BR-05).
    expect(jira.writesFor('PROJ-123'), hasLength(1));
    expect(jira.writesFor('PROJ-123').single.operationId, 'op-1');
    expect(jira.issues['PROJ-123']!.status, 'Done');

    // And the queue holds one settled row, not two.
    final OutboxOperation settled = (await outbox.findById('op-1'))!;
    expect(settled.state, OutboxOperationState.completed);
    expect(await outbox.unsettled(), isEmpty);
    expect(
      (await outbox.pending(t0.add(const Duration(days: 1)))),
      isEmpty,
    );
  });

  test(
    'S02-IT-02: five attempts at 0s/2s/4s/8s/16s, then failed',
    () async {
      // A site that is throttling and never stops.
      jira.failWith = const RateLimitFailure();
      await outbox.enqueue(operation(operationId: 'op-1'));

      /// Every attempt, as the offset from the previous one.
      final List<Duration> offsets = <Duration>[];
      Duration elapsed = Duration.zero;
      Duration lastAttemptAt = Duration.zero;
      int attemptsSeen = 0;

      // Walk a whole minute one second at a time and let the dispatcher take
      // whatever it is entitled to. Nothing here waits on real time: the clock
      // is the fake, and `pending` gates on it.
      for (int second = 0; second <= 60; second++) {
        await dispatcher.dispatch();
        final OutboxOperation current = (await outbox.findById('op-1'))!;
        if (current.attempts > attemptsSeen) {
          attemptsSeen = current.attempts;
          offsets.add(elapsed - lastAttemptAt);
          lastAttemptAt = elapsed;
        }
        clock.advance(const Duration(seconds: 1));
        elapsed += const Duration(seconds: 1);
      }

      expect(offsets, <Duration>[
        Duration.zero,
        const Duration(seconds: 2),
        const Duration(seconds: 4),
        const Duration(seconds: 8),
        const Duration(seconds: 16),
      ]);
      expect(offsets, hasLength(OutboxDispatcher.maxAttempts));

      final OutboxOperation done = (await outbox.findById('op-1'))!;
      expect(done.attempts, OutboxDispatcher.maxAttempts);
      expect(done.state, OutboxOperationState.failed);
      expect(done.nextAttemptAt, isNull);
      expect(done.lastError, isNotNull);

      // No sixth attempt, however long we wait.
      clock.advance(const Duration(hours: 1));
      await dispatcher.dispatch();
      expect((await outbox.findById('op-1'))!.attempts, 5);
    },
  );

  test('S02-IT-02: a manual retry puts a failed operation back', () async {
    jira.failWith = const RateLimitFailure();
    await outbox.enqueue(operation(operationId: 'op-1'));
    for (int i = 0; i < 5; i++) {
      await dispatcher.dispatch();
      clock.advance(const Duration(seconds: 20));
    }
    expect((await outbox.findById('op-1'))!.state, OutboxOperationState.failed);

    jira.failWith = null;
    await dispatcher.retry('op-1');

    final OutboxOperation requeued = (await outbox.findById('op-1'))!;
    expect(requeued.state, OutboxOperationState.pending);
    expect(requeued.attempts, 0);
    expect(requeued.lastError, isNull);

    expect(await dispatcher.dispatch(), 1);
    expect(jira.writesFor('PROJ-123'), hasLength(1));
  });

  test('S02-IT-03: two writes to one issue leave in the order made', () async {
    await outbox.enqueue(operation(operationId: 'op-1', payload: 'Done'));
    await outbox.enqueue(
      operation(
        operationId: 'op-2',
        kind: OutboxOperationKind.comment,
        payload: 'and here is why',
      ),
    );

    expect(await dispatcher.dispatch(), 2);

    expect(
      jira.writesFor('PROJ-123').map((JiraWrite w) => w.kind),
      <String>['transition', 'comment'],
    );
    expect(
      jira.writesFor('PROJ-123').map((JiraWrite w) => w.operationId),
      <String>['op-1', 'op-2'],
    );
  });

  test('S02-IT-03: order holds even within the same millisecond', () async {
    // Both rows carry the same `createdAt`, so only `sequence` can order them.
    for (int i = 1; i <= 5; i++) {
      await outbox.enqueue(
        operation(
          operationId: 'op-$i',
          kind: OutboxOperationKind.comment,
          payload: 'comment $i',
        ),
      );
    }

    await dispatcher.dispatch();

    expect(
      jira.writesFor('PROJ-123').map((JiraWrite w) => w.value),
      <String>['comment 1', 'comment 2', 'comment 3', 'comment 4', 'comment 5'],
    );
  });

  test('a failure time cannot fix does not burn five attempts', () async {
    // The issue does not exist: retrying changes nothing, and the user has to
    // hear about it now rather than in half a minute.
    await outbox.enqueue(operation(operationId: 'op-1', issueKey: 'GONE-9'));

    await dispatcher.dispatch();

    final OutboxOperation failed = (await outbox.findById('op-1'))!;
    expect(failed.state, OutboxOperationState.failed);
    expect(failed.attempts, 1);
  });

  test('a created issue is linked back onto its task', () async {
    final Task task = Task(
      id: 'task-1',
      title: 'Review the connector PR',
      createdAt: t0,
      updatedAt: t0,
    );
    await tasks.save(task);
    await outbox.enqueue(
      operation(
        operationId: 'op-1',
        kind: OutboxOperationKind.createIssue,
        issueKey: 'NEW',
        payload: task.title,
        taskId: 'task-1',
      ),
    );

    expect(await dispatcher.dispatch(), 1);

    final Task linked = (await tasks.findById('task-1'))!;
    expect(linked.jiraLink, isNotNull);
    expect(linked.jiraLink!.issueKey, 'NEW-1');
    expect(linked.jiraLink!.lastKnownStatus, 'To Do');
    expect(linked.jiraLink!.lastSyncedAt, t0);
    // BR-01 — the task is otherwise exactly what it was.
    expect(linked.copyWith(jiraLink: null), task);
  });

  test('a task deleted while its creation was queued is not an error', () async {
    await outbox.enqueue(
      operation(
        operationId: 'op-1',
        kind: OutboxOperationKind.createIssue,
        issueKey: 'NEW',
        payload: 'orphan',
        taskId: 'ghost',
      ),
    );

    expect(await dispatcher.dispatch(), 1);
    expect((await outbox.findById('op-1'))!.state,
        OutboxOperationState.completed);
  });

  test('an operation still in its backoff window is left alone', () async {
    jira.failWith = const NetworkFailure();
    await outbox.enqueue(operation(operationId: 'op-1'));
    await dispatcher.dispatch();

    jira.failWith = null;
    // One second short of the two-second window.
    clock.advance(const Duration(seconds: 1));
    expect(await dispatcher.dispatch(), 0);
    expect(jira.writes, isEmpty);

    clock.advance(const Duration(seconds: 1));
    expect(await dispatcher.dispatch(), 1);
  });

  test('a completed operation is never dispatched again', () async {
    await outbox.enqueue(operation(operationId: 'op-1'));
    await dispatcher.dispatch();

    clock.advance(const Duration(hours: 1));
    expect(await dispatcher.dispatch(), 0);
    expect(jira.writesFor('PROJ-123'), hasLength(1));
  });

  test('retrying an operation that is not failed does nothing', () async {
    await outbox.enqueue(operation(operationId: 'op-1'));

    await dispatcher.retry('op-1');
    await dispatcher.retry('nobody');

    expect((await outbox.findById('op-1'))!.attempts, 0);
  });

  group('the queue survives what a queue has to survive', () {
    test('a comment on an unlinked-away issue fails, others still go', () async {
      await outbox.enqueue(operation(operationId: 'op-1', issueKey: 'GONE-9'));
      await outbox.enqueue(operation(operationId: 'op-2'));

      expect(await dispatcher.dispatch(), 1);

      expect((await outbox.findById('op-1'))!.state,
          OutboxOperationState.failed);
      expect((await outbox.findById('op-2'))!.state,
          OutboxOperationState.completed);
    });

    test('completed rows are purgeable, unsettled ones are not', () async {
      await outbox.enqueue(operation(operationId: 'op-1'));
      await outbox.enqueue(operation(operationId: 'op-2', issueKey: 'GONE-9'));
      await dispatcher.dispatch();

      await outbox.purgeCompleted(t0.add(const Duration(days: 1)));

      expect(await outbox.findById('op-1'), isNull);
      expect(await outbox.findById('op-2'), isNotNull);
    });
  });

  test('the unsettled stream reports what is still owed', () async {
    final List<int> counts = <int>[];
    final subscription = outbox.watchUnsettled().listen(
      (List<OutboxOperation> operations) => counts.add(operations.length),
    );
    addTearDown(subscription.cancel);

    await outbox.enqueue(operation(operationId: 'op-1'));
    await dispatcher.dispatch();
    await pumpEventQueue();

    // One queued, then none left owing. (Drift coalesces emissions, so the
    // initial empty one may be folded into the insert — what matters is that
    // the stream reported the operation and then reported it settled.)
    expect(counts, contains(1));
    expect(counts.last, 0);
  });

  test('a task with a link keeps it when another creation completes', () async {
    final Task task = Task(
      id: 'task-1',
      title: 'already linked',
      createdAt: t0,
      updatedAt: t0,
      jiraLink: const JiraLink(
        issueKey: 'PROJ-123',
        siteUrl: 'https://example.atlassian.net',
      ),
    );
    await tasks.save(task);
    await outbox.enqueue(
      operation(
        operationId: 'op-1',
        kind: OutboxOperationKind.createIssue,
        issueKey: 'NEW',
        payload: task.title,
        taskId: 'task-1',
      ),
    );

    await dispatcher.dispatch();

    expect((await tasks.findById('task-1'))!.jiraLink!.issueKey, 'PROJ-123');
  });
}
