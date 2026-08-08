import 'package:freezed_annotation/freezed_annotation.dart';

part 'jira_link.freezed.dart';

/// Reference to a Jira issue attached to a [Task].
///
/// The app is an **external layer** to Jira and never mirrors a ticket
/// (BR-09): only the four fields below are kept locally, and
/// [lastKnownStatus] is a display cache — Jira remains the source of truth.
///
/// A [JiraLink] is optional and removable at any moment (BR-01); a task is
/// fully usable without one.
@freezed
abstract class JiraLink with _$JiraLink {
  const factory JiraLink({
    /// Issue key as Jira spells it, e.g. `PROJ-123`.
    required String issueKey,

    /// Base URL of the Jira site the issue lives on.
    required String siteUrl,

    /// Status text from the last successful read. Display only — never used
    /// to decide a transition, and never reconciled automatically (BR-02).
    String? lastKnownStatus,

    /// When [lastKnownStatus] was read. `null` means "never synced".
    DateTime? lastSyncedAt,
  }) = _JiraLink;
}
