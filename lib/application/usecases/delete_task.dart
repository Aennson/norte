import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/task_repository.dart';

/// Removes a task permanently.
///
/// Idempotent, like the port it calls: deleting an id that is already gone
/// succeeds. The confirmation the user sees before this runs is a UI concern
/// (`sprint-01` validation rules), not a second check here.
class DeleteTask {
  const DeleteTask({required this.repository});

  final TaskRepository repository;

  /// Deletes the task with [id].
  ///
  /// Returns [ValidationFailure] for a blank id without touching the
  /// repository.
  Future<Result<void>> call(String id) async {
    if (id.trim().isEmpty) {
      return const Err<void>(
        ValidationFailure('task id must not be empty', 'id'),
      );
    }
    await repository.delete(id);
    return const Ok<void>(null);
  }
}
