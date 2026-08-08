import '../../domain/entities/jira_link.dart';
import '../../domain/entities/task.dart';
import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/clock.dart';
import '../../domain/ports/task_repository.dart';
import 'create_task.dart' show normalizeTags;

/// Marker for "leave this optional field as it is".
///
/// `null` is a meaningful value for `description`, `dueDate` and `jiraLink` —
/// clearing a due date is not the same as not touching it — so the named
/// parameters cannot use `null` for both meanings. Wrapping the new value in
/// [Patch] separates them: omit the argument to keep, pass `Patch(null)` to
/// clear.
class Patch<T> {
  const Patch(this.value);

  final T value;
}

/// Applies changes to an existing task.
///
/// The entity is immutable: this produces a new instance through `copyWith`
/// and refreshes [Task.updatedAt] from the injected [Clock].
/// [Task.createdAt] is never rewritten (S01-UT-03).
class UpdateTask {
  const UpdateTask({required this.repository, required this.clock});

  final TaskRepository repository;
  final Clock clock;

  /// Updates the task with [id] and returns the stored result.
  ///
  /// Returns [ValidationFailure] for a blank [title], and [NotFoundFailure]
  /// when no task carries [id] — in both cases nothing is written.
  Future<Result<Task>> call({
    required String id,
    String? title,
    Patch<String?>? description,
    TaskStatus? status,
    Priority? priority,
    Patch<DateTime?>? dueDate,
    Patch<JiraLink?>? jiraLink,
    List<String>? tags,
  }) async {
    String? trimmedTitle;
    if (title != null) {
      trimmedTitle = title.trim();
      if (trimmedTitle.isEmpty) {
        return const Err<Task>(
          ValidationFailure('task title must not be empty', 'title'),
        );
      }
    }

    final Task? current = await repository.findById(id);
    if (current == null) {
      return Err<Task>(NotFoundFailure('no task with id $id'));
    }

    final Task updated = current.copyWith(
      title: trimmedTitle ?? current.title,
      description: description == null
          ? current.description
          : description.value,
      status: status ?? current.status,
      priority: priority ?? current.priority,
      dueDate: dueDate == null ? current.dueDate : dueDate.value,
      jiraLink: jiraLink == null ? current.jiraLink : jiraLink.value,
      tags: tags == null ? current.tags : normalizeTags(tags),
      updatedAt: clock.now().toUtc(),
    );

    await repository.save(updated);
    return Ok<Task>(updated);
  }
}
