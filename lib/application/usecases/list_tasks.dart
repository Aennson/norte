import '../../domain/entities/task.dart';
import '../../domain/ports/task_repository.dart';

/// How a task list is ordered.
enum TaskSort {
  /// Most urgent first; ties by due date ascending with undated tasks last.
  priority,

  /// Soonest deadline first, undated tasks last; ties by priority descending.
  dueDate,
}

/// Filter and ordering applied to the task list.
///
/// A query with no [statuses] and no [tag] matches every task.
class TaskQuery {
  const TaskQuery({
    this.statuses = const <TaskStatus>{},
    this.tag,
    this.sort = TaskSort.priority,
  });

  /// Statuses to keep. Empty means "every status".
  final Set<TaskStatus> statuses;

  /// Keeps only tasks carrying this tag. `null` means "any tag".
  final String? tag;

  final TaskSort sort;

  /// `true` when the query narrows nothing — used by the UI to tell an empty
  /// database apart from a filter that matched nothing.
  bool get isUnfiltered => statuses.isEmpty && tag == null;
}

/// Lists tasks, filtered and sorted.
///
/// Reads through [TaskRepository.watchAll], so the result is a stream that
/// re-emits after every mutation — the UI never polls (`sprint-01` validation
/// rules).
class ListTasks {
  const ListTasks({required this.repository});

  final TaskRepository repository;

  /// Reactive, filtered, sorted view of the stored tasks.
  Stream<List<Task>> call([TaskQuery query = const TaskQuery()]) {
    return repository.watchAll().map((List<Task> tasks) => apply(tasks, query));
  }

  /// The pure part: filters and sorts [tasks] according to [query].
  ///
  /// Exposed so the rules can be exercised without a stream, and reused by any
  /// caller that already holds a list.
  static List<Task> apply(List<Task> tasks, TaskQuery query) {
    final List<Task> result = tasks.where((Task task) {
      if (query.statuses.isNotEmpty && !query.statuses.contains(task.status)) {
        return false;
      }
      if (query.tag != null && !task.tags.contains(query.tag)) return false;
      return true;
    }).toList();

    result.sort(switch (query.sort) {
      TaskSort.priority => _byPriority,
      TaskSort.dueDate => _byDueDate,
    });
    return List<Task>.unmodifiable(result);
  }
}

/// Priority descending, then due date ascending with `null` last, then
/// creation order — the last step only keeps the sort deterministic.
int _byPriority(Task a, Task b) {
  final int byPriority = b.priority.index.compareTo(a.priority.index);
  if (byPriority != 0) return byPriority;
  final int byDueDate = _compareDueDates(a.dueDate, b.dueDate);
  if (byDueDate != 0) return byDueDate;
  return a.createdAt.compareTo(b.createdAt);
}

/// Due date ascending with `null` last, then priority descending, then
/// creation order.
int _byDueDate(Task a, Task b) {
  final int byDueDate = _compareDueDates(a.dueDate, b.dueDate);
  if (byDueDate != 0) return byDueDate;
  final int byPriority = b.priority.index.compareTo(a.priority.index);
  if (byPriority != 0) return byPriority;
  return a.createdAt.compareTo(b.createdAt);
}

/// Ascending, with an absent date sorting after every present one.
int _compareDueDates(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}
