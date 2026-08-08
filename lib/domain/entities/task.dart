import 'package:freezed_annotation/freezed_annotation.dart';

import 'jira_link.dart';

part 'task.freezed.dart';

/// Lifecycle state of a [Task] (`docs/architecture.md` §3.1).
enum TaskStatus {
  /// Created, not started.
  todo,

  /// Being worked on.
  inProgress,

  /// Finished.
  done,

  /// Waiting on something outside the developer's control.
  blocked;

  /// `true` for the single terminal state — used by listing and by the
  /// completion toggle in the UI.
  bool get isTerminal => this == TaskStatus.done;
}

/// How urgent a [Task] is.
///
/// Declared from least to most urgent so [Enum.index] *is* the ranking:
/// listing sorts by `index` descending (`ListTasks`).
enum Priority { low, medium, high, urgent }

/// A unit of work owned by the user.
///
/// **BR-01** — a task exists independently of Jira. [jiraLink] is optional and
/// can be attached or removed at any time without affecting the rest of the
/// entity.
///
/// The entity is immutable: every change produces a new instance through
/// `copyWith`. It never stamps [updatedAt] itself — that is the use case's
/// responsibility, so the clock stays injectable and the tests stay
/// deterministic (`sprint-01` validation rules).
@freezed
abstract class Task with _$Task {
  const factory Task({
    /// Locally generated UUID v4. Stable for the life of the task, and
    /// unrelated to any Jira identifier.
    required String id,

    /// Non-empty, already trimmed by the use case.
    required String title,

    /// When the task was created. Never changes after creation.
    required DateTime createdAt,

    /// When the task last changed. Refreshed by the use cases, never by the
    /// entity.
    required DateTime updatedAt,

    /// Free-form detail. `null` and empty are distinct: `null` means the user
    /// never wrote one.
    String? description,

    @Default(TaskStatus.todo) TaskStatus status,
    @Default(Priority.medium) Priority priority,

    /// Optional deadline. Tasks without one sort last.
    DateTime? dueDate,

    /// Optional Jira reference (BR-01).
    JiraLink? jiraLink,

    /// User labels, kept in the order the user entered them.
    @Default(<String>[]) List<String> tags,
  }) = _Task;
}
