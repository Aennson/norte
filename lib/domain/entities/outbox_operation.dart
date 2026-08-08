import 'package:freezed_annotation/freezed_annotation.dart';

part 'outbox_operation.freezed.dart';

/// The kinds of Jira write the app can queue.
///
/// Reads are never queued — they are pointless once stale, and linking
/// requires a live answer (`sprint-02` validation rules).
enum OutboxOperationKind {
  /// Move the issue to `payload`, a Jira status name.
  transition,

  /// Post `payload` as a comment.
  comment,

  /// Create a new issue in project `issueKey` with `payload` as its summary.
  createIssue,
}

/// Where an operation stands in the queue.
enum OutboxOperationState {
  /// Waiting for the dispatcher, or waiting out a backoff window.
  pending,

  /// Applied by Jira. Terminal.
  completed,

  /// Out of attempts. Terminal until the user asks for a manual retry
  /// (`sprint-02` validation rules).
  failed;

  /// `true` while the operation still owes the user an outcome — what the
  /// "pending sync" and "sync failed" indicators are drawn from.
  bool get isUnsettled => this != OutboxOperationState.completed;
}

/// One queued Jira write.
///
/// **BR-05** — every Jira mutation becomes one of these first. No use case
/// calls the gateway to write; it enqueues, and `OutboxDispatcher` is the only
/// thing that talks to Jira. That is what makes the app offline-first: the
/// user's action lands locally and survives a restart, a dead network and a
/// rate limit.
///
/// [operationId] is the idempotency key. It is generated once, when the
/// operation is created, and reused across every attempt — so a retry after a
/// lost response cannot apply the same change twice.
@freezed
abstract class OutboxOperation with _$OutboxOperation {
  const factory OutboxOperation({
    /// Idempotency key (BR-05). A UUID v4 from the use case, stable across
    /// attempts.
    required String operationId,

    required OutboxOperationKind kind,

    /// Issue the write targets — or, for [OutboxOperationKind.createIssue],
    /// the project key it will be created in.
    required String issueKey,

    /// Kind-dependent argument: the target status, the comment body, or the
    /// summary of the issue to create.
    required String payload,

    /// When the operation was enqueued.
    required DateTime createdAt,

    /// Local task the operation belongs to, when there is one. Lets the
    /// dispatcher write the resulting issue key back onto the task after a
    /// [OutboxOperationKind.createIssue].
    String? taskId,

    @Default(OutboxOperationState.pending) OutboxOperationState state,

    /// How many times the dispatcher has tried. `0` before the first attempt.
    @Default(0) int attempts,

    /// Earliest instant the next attempt may run — the backoff window.
    /// `null` means "as soon as the dispatcher gets to it".
    DateTime? nextAttemptAt,

    /// Message of the failure that ended the last attempt, for the UI and the
    /// report. Never carries a payload or a credential (BR-08).
    String? lastError,

    /// Insertion order, assigned by the repository. The dispatcher works in
    /// ascending order so that two writes to the same issue reach Jira in the
    /// order the user made them (S02-IT-03) — [createdAt] cannot serve, since
    /// two operations created in the same millisecond would tie.
    @Default(0) int sequence,
  }) = _OutboxOperation;
}
