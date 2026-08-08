import '../../domain/entities/task.dart';
import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/clock.dart';
import '../../domain/ports/task_repository.dart';

/// Removes the Jira reference from a task.
///
/// **BR-01** — a link is removable at any moment and its removal costs the
/// task nothing: everything the user typed stays, and the task goes on being
/// a perfectly ordinary local task.
///
/// Nothing is sent to Jira. Unlinking is a statement about *this app*, not
/// about the ticket — the issue keeps existing, and a user who wanted it
/// closed would have said so.
class UnlinkTask {
  const UnlinkTask({required this.repository, required this.clock});

  final TaskRepository repository;
  final Clock clock;

  /// Clears the link on the task with [taskId].
  ///
  /// Returns [NotFoundFailure] when there is no such task. Unlinking a task
  /// that has no link succeeds and changes nothing but `updatedAt`.
  Future<Result<Task>> call({required String taskId}) async {
    final Task? task = await repository.findById(taskId);
    if (task == null) {
      return Err<Task>(NotFoundFailure('no task with id $taskId'));
    }

    final Task unlinked = task.copyWith(
      jiraLink: null,
      updatedAt: clock.now().toUtc(),
    );
    await repository.save(unlinked);
    return Ok<Task>(unlinked);
  }
}
