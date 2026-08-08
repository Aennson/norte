import '../../domain/entities/jira_issue_snapshot.dart';
import '../../domain/entities/jira_link.dart';
import '../../domain/entities/task.dart';
import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/clock.dart';
import '../../domain/ports/jira_gateway.dart';
import '../../domain/ports/task_repository.dart';

/// Attaches a Jira issue to an existing task.
///
/// **Linking is the one Jira operation that requires a live site.** It is not
/// queued and has no offline path (`sprint-02` validation rules): storing a
/// link to a key nobody has confirmed would mean every later transition and
/// comment queues up against an issue that may not exist. So the key is read
/// back from Jira first, and only a confirmed issue becomes a [JiraLink].
///
/// This is not a contradiction of BR-05 — that rule governs *writes*, and
/// linking writes nothing to Jira.
///
/// **BR-01** — the task itself is untouched apart from the link: title,
/// status, priority, dates and tags all survive, and `UnlinkTask` puts things
/// back exactly as they were.
///
/// **BR-09** — only the four permitted fields are stored. The snapshot's
/// status is kept as `lastKnownStatus`, a display cache, and is never applied
/// to [Task.status].
class LinkTaskToJira {
  const LinkTaskToJira({
    required this.repository,
    required this.gateway,
    required this.clock,
  });

  final TaskRepository repository;
  final JiraGateway gateway;
  final Clock clock;

  /// Links the task with [taskId] to [issueKey].
  ///
  /// Returns:
  /// * [ValidationFailure] — [issueKey] is blank;
  /// * [NotFoundFailure] — no local task with [taskId];
  /// * [JiraIssueNotFoundFailure] — the site has no such issue;
  /// * [NetworkFailure] — no connection; the link is **not** queued for later;
  /// * whatever else the gateway raised ([AuthFailure], [RateLimitFailure]…).
  ///
  /// In every failing case nothing is written locally.
  Future<Result<Task>> call({
    required String taskId,
    required String issueKey,
  }) async {
    final String key = issueKey.trim().toUpperCase();
    if (key.isEmpty) {
      return const Err<Task>(
        ValidationFailure('issue key must not be empty', 'issueKey'),
      );
    }

    final Task? task = await repository.findById(taskId);
    if (task == null) {
      return Err<Task>(NotFoundFailure('no task with id $taskId'));
    }

    final JiraIssueSnapshot snapshot;
    try {
      snapshot = await gateway.getIssue(key);
    } on NotFoundFailure {
      return Err<Task>(JiraIssueNotFoundFailure(key));
    } on Failure catch (failure) {
      return Err<Task>(failure);
    }

    final Task linked = task.copyWith(
      jiraLink: JiraLink(
        issueKey: snapshot.issueKey,
        siteUrl: snapshot.siteUrl,
        lastKnownStatus: snapshot.status,
        lastSyncedAt: clock.now().toUtc(),
      ),
      updatedAt: clock.now().toUtc(),
    );
    await repository.save(linked);
    return Ok<Task>(linked);
  }
}
