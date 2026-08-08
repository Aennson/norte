import '../entities/outbox_operation.dart';

/// Durable queue of pending Jira writes (BR-05).
///
/// The queue is local and survives a restart: an action taken on a plane is
/// still waiting when the network comes back.
///
/// **Contract**
/// * [enqueue] assigns `sequence` — strictly increasing, never reused — and
///   returns the stored operation. It rejects nothing; validation happened in
///   the use case.
/// * [pending] returns operations in `state == pending` whose backoff window
///   has opened, in ascending `sequence` order. Two writes to the same issue
///   therefore leave in the order the user made them (S02-IT-03).
/// * [save] replaces an operation by `operationId`.
/// * [watchUnsettled] emits immediately on subscription and after every
///   change — it is what the "pending sync" indicator is built on, so the UI
///   never polls.
/// * A storage error surfaces as a thrown `StorageFailure`.
abstract interface class OutboxRepository {
  /// Appends [operation] to the queue.
  Future<OutboxOperation> enqueue(OutboxOperation operation);

  /// Operations ready to be dispatched no later than [now].
  Future<List<OutboxOperation>> pending(DateTime now);

  /// Every operation still owing an outcome — pending or failed.
  Future<List<OutboxOperation>> unsettled();

  /// Reactive view of [unsettled].
  Stream<List<OutboxOperation>> watchUnsettled();

  /// The operation with [operationId], or `null`.
  Future<OutboxOperation?> findById(String operationId);

  /// Inserts or replaces [operation], keyed by `operationId`.
  Future<void> save(OutboxOperation operation);

  /// Drops completed operations older than [before], so the queue does not
  /// grow without bound.
  Future<void> purgeCompleted(DateTime before);
}
