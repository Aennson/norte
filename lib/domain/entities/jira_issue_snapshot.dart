import 'package:freezed_annotation/freezed_annotation.dart';

part 'jira_issue_snapshot.freezed.dart';

/// What a single read of a Jira issue told us.
///
/// **BR-09** — these are the only three facts the app is allowed to learn
/// about a ticket. A snapshot is a transport value, not stored state: what
/// survives a read is the subset `JiraLink` keeps.
@freezed
abstract class JiraIssueSnapshot with _$JiraIssueSnapshot {
  const factory JiraIssueSnapshot({
    /// Issue key as Jira spells it, e.g. `PROJ-123`.
    required String issueKey,

    /// Base URL of the site the issue lives on.
    required String siteUrl,

    /// Status name at the moment of the read. Display cache only — Jira
    /// remains the source of truth and this is never used to decide a
    /// transition (BR-02).
    required String status,
  }) = _JiraIssueSnapshot;
}
