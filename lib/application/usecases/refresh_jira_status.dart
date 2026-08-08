import '../../domain/entities/jira_link.dart';
import '../../domain/entities/jira_status_mapping.dart';
import '../../domain/entities/task.dart';
import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/clock.dart';
import '../../domain/ports/jira_gateway.dart';
import '../../domain/ports/task_repository.dart';

/// What a refresh found.
class JiraRefresh {
  const JiraRefresh({
    required this.task,
    required this.remoteStatus,
    required this.hasDivergence,
  });

  /// The task as stored after the refresh — same [Task.status] it had, with
  /// `lastKnownStatus` and `lastSyncedAt` brought up to date.
  final Task task;

  /// Status name Jira reported.
  final String remoteStatus;

  /// `true` when Jira's status and the local one describe different states.
  ///
  /// A `true` here is a **question for the user**, never an instruction to
  /// the app (BR-02).
  final bool hasDivergence;
}

/// Reads a linked issue's current status from Jira.
///
/// **BR-02 is the whole design of this use case.** It refreshes the display
/// cache and reports what it saw; it does not reconcile. When Jira says one
/// thing and the local task says another, both values stay exactly as they
/// are and `hasDivergence` goes up — the UI raises a `DivergenceBanner` and
/// the user decides. There is no code path in this class, or below it, that
/// writes [Task.status].
///
/// **BR-09** — of everything Jira returns, only the status name is kept, in
/// `lastKnownStatus`. The app does not learn the summary, the assignee or the
/// sprint, because it is not a mirror.
class RefreshJiraStatus {
  const RefreshJiraStatus({
    required this.repository,
    required this.gateway,
    required this.clock,
  });

  final TaskRepository repository;
  final JiraGateway gateway;
  final Clock clock;

  /// Refreshes the status of [task]'s issue.
  ///
  /// Returns [NotLinkedFailure] when [task] carries no link, and whatever the
  /// gateway raised on a transport error — in which case nothing is written
  /// and the previous cache stands.
  Future<Result<JiraRefresh>> call(Task task) async {
    final JiraLink? link = task.jiraLink;
    if (link == null) {
      return const Err<JiraRefresh>(NotLinkedFailure());
    }

    final String remoteStatus;
    try {
      remoteStatus = await gateway.getStatus(link.issueKey);
    } on NotFoundFailure {
      return Err<JiraRefresh>(JiraIssueNotFoundFailure(link.issueKey));
    } on Failure catch (failure) {
      return Err<JiraRefresh>(failure);
    }

    // The cache and the sync stamp move; TaskStatus does not (BR-02).
    final Task refreshed = task.copyWith(
      jiraLink: link.copyWith(
        lastKnownStatus: remoteStatus,
        lastSyncedAt: clock.now().toUtc(),
      ),
    );
    await repository.save(refreshed);

    return Ok<JiraRefresh>(
      JiraRefresh(
        task: refreshed,
        remoteStatus: remoteStatus,
        hasDivergence: JiraStatusMapping.diverges(task.status, remoteStatus),
      ),
    );
  }
}
