import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_comment.freezed.dart';

/// A note the user keeps on their own task (`docs/architecture.md` §3.1).
///
/// **It is local and it stays local** (§3.2). A comment here is never pushed
/// to a linked Jira issue: pushing a comment to Jira is `addComment`, a
/// separate, explicitly confirmed action that goes through the outbox (BR-05).
/// Conflating the two would mean a private note appearing where the whole team
/// can read it — which is the one mistake this entity exists to make
/// impossible.
///
/// Immutable, like every other entity, and it never stamps [createdAt] itself:
/// the use case owns the clock (`sprint-01` validation rules).
@freezed
abstract class TaskComment with _$TaskComment {
  const factory TaskComment({
    /// Locally generated UUID v4, unique across every task.
    required String id,

    /// What the user wrote, already trimmed by the use case. Never blank.
    required String body,

    /// When the comment was made. Never changes.
    required DateTime createdAt,
  }) = _TaskComment;
}
