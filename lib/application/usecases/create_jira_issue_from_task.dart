import '../../domain/entities/outbox_operation.dart';
import '../../domain/entities/task.dart';
import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/clock.dart';
import '../../domain/ports/id_generator.dart';
import '../../domain/ports/outbox_repository.dart';

/// Creates a Jira issue from a local task and links the two.
///
/// **BR-05** — like every other Jira write, this is queued. The issue key
/// does not exist until the dispatcher has been to the site, so the link is
/// attached by the dispatcher on success, not here.
///
/// **BR-01 holds throughout.** The task is fully usable in the meantime: it
/// simply has no link yet, exactly as it had none a moment ago. If the
/// operation ends up failing for good, the task is no worse off.
class CreateJiraIssueFromTask {
  const CreateJiraIssueFromTask({
    required this.outbox,
    required this.clock,
    required this.idGenerator,
  });

  final OutboxRepository outbox;
  final Clock clock;
  final IdGenerator idGenerator;

  /// Queues the creation of an issue in [projectKey] from [task].
  ///
  /// Returns [ValidationFailure] when [projectKey] is blank or [task] is
  /// already linked — a task references one issue, and creating a second one
  /// from it would leave the first orphaned.
  Future<Result<OutboxOperation>> call({
    required Task task,
    required String projectKey,
  }) async {
    final String project = projectKey.trim().toUpperCase();
    if (project.isEmpty) {
      return const Err<OutboxOperation>(
        ValidationFailure('project key must not be empty', 'projectKey'),
      );
    }
    if (task.jiraLink != null) {
      return const Err<OutboxOperation>(
        ValidationFailure('task is already linked to an issue', 'jiraLink'),
      );
    }

    final OutboxOperation queued;
    try {
      queued = await outbox.enqueue(
        OutboxOperation(
          operationId: idGenerator.newId(),
          kind: OutboxOperationKind.createIssue,
          issueKey: project,
          payload: task.title,
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
