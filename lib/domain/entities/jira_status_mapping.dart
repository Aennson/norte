import 'task.dart';

/// Translation between Jira's free-text status names and [TaskStatus].
///
/// Jira statuses are workflow-defined strings, so the mapping is a best
/// effort over the names of the default Jira Cloud workflow. It exists for
/// exactly two purposes:
///
/// * **detecting** a divergence — comparing a remote status to the local one
///   requires putting them in the same vocabulary;
/// * **naming** the transition the user asked for, when a local status has to
///   be pushed to Jira.
///
/// It never *resolves* anything. A divergence is always a question for the
/// user (BR-02); this class only makes the question askable.
abstract final class JiraStatusMapping {
  static const Map<String, TaskStatus> _remoteToLocal = <String, TaskStatus>{
    'to do': TaskStatus.todo,
    'todo': TaskStatus.todo,
    'open': TaskStatus.todo,
    'backlog': TaskStatus.todo,
    'in progress': TaskStatus.inProgress,
    'in review': TaskStatus.inProgress,
    'done': TaskStatus.done,
    'closed': TaskStatus.done,
    'resolved': TaskStatus.done,
    'blocked': TaskStatus.blocked,
    'impediment': TaskStatus.blocked,
  };

  static const Map<TaskStatus, String> _localToRemote = <TaskStatus, String>{
    TaskStatus.todo: 'To Do',
    TaskStatus.inProgress: 'In Progress',
    TaskStatus.done: 'Done',
    TaskStatus.blocked: 'Blocked',
  };

  /// The [TaskStatus] [remoteStatus] corresponds to, or `null` when the
  /// workflow uses a name this mapping does not know.
  ///
  /// `null` is not a failure: an unrecognised remote status simply cannot be
  /// compared, so it never produces a divergence the user would have no way
  /// to reason about.
  static TaskStatus? toLocal(String remoteStatus) =>
      _remoteToLocal[remoteStatus.trim().toLowerCase()];

  /// The Jira status name to request when pushing [status] to the ticket.
  static String toRemote(TaskStatus status) => _localToRemote[status]!;

  /// Whether [localStatus] and [remoteStatus] describe different states.
  ///
  /// `false` when [remoteStatus] is unmappable — see [toLocal].
  static bool diverges(TaskStatus localStatus, String remoteStatus) {
    final TaskStatus? mapped = toLocal(remoteStatus);
    return mapped != null && mapped != localStatus;
  }
}
