import '../entities/jira_issue_snapshot.dart';

/// Access to a Jira Cloud site.
///
/// The app is an **external layer** to Jira (`docs/architecture.md` §4.1): it
/// references tickets and never mirrors them, so this port exposes exactly the
/// five operations v1.0 needs and nothing that would tempt a caller into
/// keeping a local copy of a ticket (BR-09).
///
/// **Contract**
/// * Every method reaches the network. Nothing here is queued or cached — the
///   offline story lives one layer up, in the outbox (BR-05).
/// * Errors are thrown as `Failure`s, never as transport exceptions
///   (`docs/project-rules.md` §6):
///   * [NetworkFailure] — unreachable host, dropped connection.
///   * [AuthFailure] — 401/403, or no credentials configured.
///   * [NotFoundFailure] — 404, including an issue key that does not exist.
///   * [RateLimitFailure] — 429, carrying `Retry-After` when the site sends it.
///   * [TimeoutFailure] — the request outlived its deadline.
///   * [EngineFailure] — a response the adapter cannot make sense of.
/// * The three writes are **idempotent by `operationId`**: applying the same
///   id twice must leave the site in the state one application would (BR-05).
///   A replay is a success, not a duplicate.
abstract interface class JiraGateway {
  /// Reads [issueKey]. Used to validate a link before it is stored — a link
  /// is only ever created against an issue the site confirmed exists
  /// (`sprint-02` validation rules).
  Future<JiraIssueSnapshot> getIssue(String issueKey);

  /// Reads just the status name of [issueKey] — the background refresh path,
  /// which asks Jira for `fields=status` and nothing else
  /// (`docs/architecture.md` §4.1).
  Future<String> getStatus(String issueKey);

  /// Moves [issueKey] to the workflow status named [status].
  ///
  /// Throws [ValidationFailure] when the issue's workflow offers no transition
  /// to that status from where it currently sits — a condition the user has to
  /// resolve in Jira, not something to retry.
  Future<void> transitionIssue({
    required String issueKey,
    required String status,
    required String operationId,
  });

  /// Posts [body] as a comment on [issueKey].
  Future<void> addComment({
    required String issueKey,
    required String body,
    required String operationId,
  });

  /// Creates an issue in [projectKey] and returns the snapshot of what was
  /// created — the caller needs the assigned key to build the link.
  Future<JiraIssueSnapshot> createIssue({
    required String projectKey,
    required String summary,
    required String operationId,
    String? description,
  });
}
