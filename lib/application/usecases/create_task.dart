import '../../domain/entities/jira_link.dart';
import '../../domain/entities/task.dart';
import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/clock.dart';
import '../../domain/ports/id_generator.dart';
import '../../domain/ports/task_repository.dart';

/// Creates a local task.
///
/// **BR-01** — the task is born independent of Jira. [jiraLink] is accepted
/// for completeness but defaults to `null`, and nothing here contacts Jira.
///
/// The id comes from [IdGenerator] and both timestamps from [Clock], so the
/// entity never reaches for `DateTime.now()` and the test can pin either
/// (`sprint-01` validation rules).
class CreateTask {
  const CreateTask({
    required this.repository,
    required this.clock,
    required this.idGenerator,
  });

  final TaskRepository repository;
  final Clock clock;
  final IdGenerator idGenerator;

  /// Persists a new task and returns it.
  ///
  /// [title] is trimmed; a blank one returns [ValidationFailure] **without
  /// touching the repository** (S01-UT-02). Blank tags are dropped, the rest
  /// keep the caller's order.
  Future<Result<Task>> call({
    required String title,
    String? description,
    TaskStatus status = TaskStatus.todo,
    Priority priority = Priority.medium,
    DateTime? dueDate,
    JiraLink? jiraLink,
    List<String> tags = const <String>[],
  }) async {
    final String trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      return const Err<Task>(
        ValidationFailure('task title must not be empty', 'title'),
      );
    }

    final DateTime now = clock.now().toUtc();
    final Task task = Task(
      id: idGenerator.newId(),
      title: trimmedTitle,
      description: description,
      status: status,
      priority: priority,
      dueDate: dueDate,
      jiraLink: jiraLink,
      tags: normalizeTags(tags),
      createdAt: now,
      updatedAt: now,
    );

    await repository.save(task);
    return Ok<Task>(task);
  }
}

/// Trims each tag and drops the blank ones, preserving order and rejecting
/// duplicates. Shared by [CreateTask] and `UpdateTask` so both normalize the
/// same way.
List<String> normalizeTags(List<String> tags) {
  final List<String> normalized = <String>[];
  for (final String tag in tags) {
    final String trimmed = tag.trim();
    if (trimmed.isEmpty || normalized.contains(trimmed)) continue;
    normalized.add(trimmed);
  }
  return List<String>.unmodifiable(normalized);
}
