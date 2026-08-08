import '../../domain/entities/jira_link.dart';
import '../../domain/entities/outbox_operation.dart';
import '../../domain/entities/task.dart';
import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/clock.dart';
import '../../domain/ports/id_generator.dart';
import '../../domain/ports/outbox_repository.dart';

/// Asks Jira to move a linked task's issue to another status.
///
/// **BR-05** — this use case does not talk to Jira. It appends one operation
/// to the outbox and returns; `OutboxDispatcher` is the only thing that ever
/// calls the gateway. Nothing here depends on there being a network, which is
/// the whole point: the user's decision is recorded the moment they make it.
///
/// The local [Task.status] is deliberately left alone. Pushing a status to
/// Jira and changing the local one are two decisions, and conflating them
/// would make it impossible to express "keep my local status, but tell Jira"
/// — which is exactly what the divergence banner's *Keep local* button does
/// (BR-02, S02-E2E-02).
class UpdateJiraStatus {
  const UpdateJiraStatus({
    required this.outbox,
    required this.clock,
    required this.idGenerator,
  });

  final OutboxRepository outbox;
  final Clock clock;
  final IdGenerator idGenerator;

  /// Queues a transition of [task]'s issue to [status], a Jira status name.
  ///
  /// Returns [NotLinkedFailure] when [task] carries no link, and
  /// [ValidationFailure] for a blank [status]. In both cases the queue is
  /// untouched.
  Future<Result<OutboxOperation>> call({
    required Task task,
    required String status,
  }) async {
    final JiraLink? link = task.jiraLink;
    if (link == null) {
      return const Err<OutboxOperation>(NotLinkedFailure());
    }
    final String target = status.trim();
    if (target.isEmpty) {
      return const Err<OutboxOperation>(
        ValidationFailure('target status must not be empty', 'status'),
      );
    }

    final OutboxOperation queued;
    try {
      queued = await outbox.enqueue(
        OutboxOperation(
          operationId: idGenerator.newId(),
          kind: OutboxOperationKind.transition,
          issueKey: link.issueKey,
          payload: target,
          taskId: task.id,
          createdAt: clock.now().toUtc(),
        ),
      );
    } on Failure catch (failure) {
      // The queue is the durability guarantee (BR-05); if it could
      // not accept the operation, the user has to be told rather
      // than left believing their action is safely waiting.
      return Err<OutboxOperation>(failure);
    }

    return Ok<OutboxOperation>(queued);
  }
}
