import '../entities/task.dart';

/// Local storage for [Task]s.
///
/// The only port the task use cases need. The adapter that implements it lives
/// in `infrastructure/persistence/` and is the sole place allowed to touch
/// Drift (`sprint-01` validation rules).
///
/// **Contract**
/// * [watchAll] emits the full task list immediately on subscription and again
///   after every mutation — the UI never polls. Ordering is unspecified;
///   `ListTasks` sorts.
/// * [save] is an upsert keyed by [Task.id]: it inserts when the id is new and
///   replaces the row otherwise. It never stamps `createdAt`/`updatedAt` —
///   the use case owns those. `Task.comments` is part of the task: saving
///   replaces the stored set with the one given, in the order given, and
///   reading returns them in that order (S05a-IT-01).
/// * [delete] is idempotent: deleting an unknown id succeeds and touches no
///   other row. It takes the task's comments with it and **only** its own.
/// * A storage error surfaces as a thrown `StorageFailure`; nothing else
///   escapes the adapter.
abstract interface class TaskRepository {
  /// Reactive view of every stored task.
  Stream<List<Task>> watchAll();

  /// One-shot read of every stored task.
  Future<List<Task>> listAll();

  /// The task with [id], or `null` when there is none.
  Future<Task?> findById(String id);

  /// Inserts or replaces [task].
  Future<void> save(Task task);

  /// Removes the task with [id], if present.
  Future<void> delete(String id);
}
