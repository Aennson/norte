import '../../domain/entities/jira_link.dart';
import '../../domain/entities/outbox_operation.dart';
import '../../domain/entities/task.dart';
import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/clock.dart';
import '../../domain/ports/id_generator.dart';
import '../../domain/ports/outbox_repository.dart';

/// Posts a comment on a linked task's issue.
///
/// **BR-05** — queued, never sent from here. See [UpdateJiraStatus] for why.
///
/// Ordering matters for comments more than for anything else: a comment that
/// explains a transition is useless if it lands first. The outbox preserves
/// the order operations were created in (S02-IT-03).
class AddJiraComment {
  const AddJiraComment({
    required this.outbox,
    required this.clock,
    required this.idGenerator,
  });

  final OutboxRepository outbox;
  final Clock clock;
  final IdGenerator idGenerator;

  /// Queues [body] as a comment on [task]'s issue.
  ///
  /// Returns [NotLinkedFailure] when [task] carries no link, and
  /// [ValidationFailure] for a blank [body].
  Future<Result<OutboxOperation>> call({
    required Task task,
    required String body,
  }) async {
    final JiraLink? link = task.jiraLink;
    if (link == null) {
      return const Err<OutboxOperation>(NotLinkedFailure());
    }
    final String text = body.trim();
    if (text.isEmpty) {
      return const Err<OutboxOperation>(
        ValidationFailure('comment must not be empty', 'body'),
      );
    }

    final OutboxOperation queued = await outbox.enqueue(
      OutboxOperation(
        operationId: idGenerator.newId(),
        kind: OutboxOperationKind.comment,
        issueKey: link.issueKey,
        payload: text,
        taskId: task.id,
        createdAt: clock.now().toUtc(),
      ),
    );
    return Ok<OutboxOperation>(queued);
  }
}
