import '../../domain/entities/jira_issue_snapshot.dart';
import '../../domain/entities/jira_link.dart';
import '../../domain/entities/outbox_operation.dart';
import '../../domain/entities/task.dart';
import '../../domain/failures/failure.dart';
import '../../domain/ports/clock.dart';
import '../../domain/ports/jira_gateway.dart';
import '../../domain/ports/outbox_repository.dart';
import '../../domain/ports/task_repository.dart';

/// Drains the outbox into Jira.
///
/// **This is the only thing in the app that performs a Jira write** (BR-05).
/// Use cases enqueue; this dispatches. The separation is what makes an action
/// taken offline indistinguishable, from the user's point of view, from one
/// taken online — it just settles later.
///
/// **Order.** Operations leave in `sequence` order, so a transition and the
/// comment explaining it arrive the way the user made them (S02-IT-03). One
/// operation is in flight at a time; [dispatch] is re-entrant-safe and a
/// second concurrent call returns immediately rather than racing the first.
///
/// **Retries.** A failure that time might fix — no network, a timeout, a 429,
/// a 5xx — is retried on the schedule in [backoff]: the next attempt opens 2s
/// after the first, then 4s, 8s and 16s, for [maxAttempts] in total. After
/// the last one the operation is `failed` and stays there until the user asks
/// for [retry]. A failure time cannot fix — a rejected credential, a
/// nonexistent issue, a transition the workflow does not offer — skips the
/// schedule and fails immediately; burning five attempts on it would only
/// delay telling the user something they have to act on.
///
/// **Idempotency.** Every attempt reuses the operation's `operationId`, so a
/// retry after a lost response cannot apply the same change twice (S02-IT-01).
class OutboxDispatcher {
  OutboxDispatcher({
    required this.outbox,
    required this.gateway,
    required this.tasks,
    required this.clock,
  });

  final OutboxRepository outbox;
  final JiraGateway gateway;
  final TaskRepository tasks;
  final Clock clock;

  /// Wait before attempts 2, 3, 4 and 5 (`sprint-02` validation rules).
  static const List<Duration> backoff = <Duration>[
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 16),
  ];

  /// Attempts an operation gets before it is `failed`.
  static const int maxAttempts = 5;

  bool _running = false;

  /// Sends every operation whose backoff window has opened.
  ///
  /// Returns the number of operations that reached `completed` in this pass.
  /// Never throws: a failure is recorded on the operation, which is the whole
  /// point of having a queue.
  Future<int> dispatch() async {
    if (_running) return 0;
    _running = true;
    try {
      int completed = 0;
      for (final OutboxOperation operation in await outbox.pending(
        clock.now(),
      )) {
        if (await _attempt(operation)) completed++;
      }
      return completed;
    } finally {
      _running = false;
    }
  }

  /// Puts a `failed` operation back in the queue at full attempts — the
  /// manual retry behind the "sync failed" indicator.
  ///
  /// Does nothing when [operationId] is unknown or already settled.
  Future<void> retry(String operationId) async {
    final OutboxOperation? operation = await outbox.findById(operationId);
    if (operation == null || operation.state != OutboxOperationState.failed) {
      return;
    }
    await outbox.save(
      operation.copyWith(
        state: OutboxOperationState.pending,
        attempts: 0,
        nextAttemptAt: null,
        lastError: null,
      ),
    );
  }

  /// Runs one operation. Returns `true` when it completed.
  Future<bool> _attempt(OutboxOperation operation) async {
    try {
      await _apply(operation);
    } on Failure catch (failure) {
      await _recordFailure(operation, failure);
      return false;
    }

    await outbox.save(
      operation.copyWith(
        state: OutboxOperationState.completed,
        attempts: operation.attempts + 1,
        nextAttemptAt: null,
        lastError: null,
      ),
    );
    return true;
  }

  Future<void> _apply(OutboxOperation operation) async {
    switch (operation.kind) {
      case OutboxOperationKind.transition:
        await gateway.transitionIssue(
          issueKey: operation.issueKey,
          status: operation.payload,
          operationId: operation.operationId,
        );
      case OutboxOperationKind.comment:
        await gateway.addComment(
          issueKey: operation.issueKey,
          body: operation.payload,
          operationId: operation.operationId,
        );
      case OutboxOperationKind.createIssue:
        final JiraIssueSnapshot created = await gateway.createIssue(
          projectKey: operation.issueKey,
          summary: operation.payload,
          operationId: operation.operationId,
        );
        await _linkBack(operation, created);
    }
  }

  /// Attaches the issue the site just created to the task it came from.
  ///
  /// The link is written here rather than in the use case because until this
  /// moment there was no key to write (`CreateJiraIssueFromTask`). A task
  /// deleted while the operation was queued is not an error — the issue
  /// exists, there is simply nothing left to attach it to.
  Future<void> _linkBack(
    OutboxOperation operation,
    JiraIssueSnapshot created,
  ) async {
    final String? taskId = operation.taskId;
    if (taskId == null) return;
    final Task? task = await tasks.findById(taskId);
    if (task == null || task.jiraLink != null) return;
    await tasks.save(
      task.copyWith(
        jiraLink: JiraLink(
          issueKey: created.issueKey,
          siteUrl: created.siteUrl,
          lastKnownStatus: created.status,
          lastSyncedAt: clock.now().toUtc(),
        ),
      ),
    );
  }

  Future<void> _recordFailure(
    OutboxOperation operation,
    Failure failure,
  ) async {
    final int attempts = operation.attempts + 1;
    final bool giveUp = !_isRetryable(failure) || attempts >= maxAttempts;

    await outbox.save(
      operation.copyWith(
        attempts: attempts,
        state: giveUp
            ? OutboxOperationState.failed
            : OutboxOperationState.pending,
        nextAttemptAt: giveUp
            ? null
            : clock.now().toUtc().add(_delayBefore(attempts + 1)),
        // `Failure.message` is diagnostic text and never carries a payload or
        // a credential (BR-08), so it is safe to persist and to show.
        lastError: failure.message,
      ),
    );
  }

  /// Wait before attempt number [attempt] (1-based).
  ///
  /// A [RateLimitFailure] carrying `Retry-After` would be honoured by a future
  /// sprint; v1.0 keeps the fixed schedule the sprint specifies so that the
  /// timing is the same on every site.
  Duration _delayBefore(int attempt) =>
      backoff[(attempt - 2).clamp(0, backoff.length - 1)];

  /// Whether waiting could plausibly change the answer.
  bool _isRetryable(Failure failure) => switch (failure) {
    NetworkFailure() ||
    TimeoutFailure() ||
    RateLimitFailure() ||
    EngineFailure() ||
    StorageFailure() => true,
    AuthFailure() ||
    JiraUnreadableResponseFailure() ||
    NotFoundFailure() ||
    JiraIssueNotFoundFailure() ||
    NotLinkedFailure() ||
    ValidationFailure() => false,
  };
}
