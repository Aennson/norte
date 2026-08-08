import 'dart:async';

import 'package:norte/domain/entities/outbox_operation.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/outbox_repository.dart';

/// In-memory [OutboxRepository] for the unit tests
/// (`docs/testing-strategy.md` §3).
///
/// Deterministic and synchronous. It reproduces the two behaviours the use
/// cases and the dispatcher actually depend on: `sequence` increases strictly
/// with insertion, and `pending` hides an operation whose backoff window has
/// not opened.
///
/// The integration tests use the real Drift repository instead — this one is
/// for the layers that must not know a database exists.
class FakeOutboxRepository implements OutboxRepository {
  /// Every operation ever enqueued, in insertion order.
  final List<OutboxOperation> operations = <OutboxOperation>[];

  final StreamController<List<OutboxOperation>> _controller =
      StreamController<List<OutboxOperation>>.broadcast();

  /// When set, every call throws it.
  Failure? failWith;

  int _nextSequence = 1;

  @override
  Future<OutboxOperation> enqueue(OutboxOperation operation) async {
    _guard();
    final OutboxOperation stored = operation.copyWith(
      sequence: _nextSequence++,
    );
    operations.add(stored);
    _emit();
    return stored;
  }

  @override
  Future<List<OutboxOperation>> pending(DateTime now) async {
    _guard();
    return List<OutboxOperation>.unmodifiable(
      operations
          .where(
            (OutboxOperation o) =>
                o.state == OutboxOperationState.pending &&
                (o.nextAttemptAt == null || !o.nextAttemptAt!.isAfter(now)),
          )
          .toList()
        ..sort(
          (OutboxOperation a, OutboxOperation b) =>
              a.sequence.compareTo(b.sequence),
        ),
    );
  }

  @override
  Future<List<OutboxOperation>> unsettled() async {
    _guard();
    return List<OutboxOperation>.unmodifiable(
      operations.where((OutboxOperation o) => o.state.isUnsettled),
    );
  }

  @override
  Stream<List<OutboxOperation>> watchUnsettled() async* {
    yield await unsettled();
    yield* _controller.stream;
  }

  @override
  Future<OutboxOperation?> findById(String operationId) async {
    _guard();
    for (final OutboxOperation operation in operations) {
      if (operation.operationId == operationId) return operation;
    }
    return null;
  }

  @override
  Future<void> save(OutboxOperation operation) async {
    _guard();
    final int index = operations.indexWhere(
      (OutboxOperation stored) => stored.operationId == operation.operationId,
    );
    if (index == -1) {
      await enqueue(operation);
      return;
    }
    operations[index] = operation;
    _emit();
  }

  @override
  Future<void> purgeCompleted(DateTime before) async {
    _guard();
    operations.removeWhere(
      (OutboxOperation o) =>
          o.state == OutboxOperationState.completed &&
          o.createdAt.isBefore(before),
    );
    _emit();
  }

  /// The operations still waiting, in queue order.
  List<OutboxOperation> get pendingOperations => operations
      .where((OutboxOperation o) => o.state == OutboxOperationState.pending)
      .toList();

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(
      List<OutboxOperation>.unmodifiable(
        operations.where((OutboxOperation o) => o.state.isUnsettled),
      ),
    );
  }

  void _guard() {
    final Failure? failure = failWith;
    if (failure != null) throw failure;
  }

  /// Closes the stream. Call from a `tearDown`.
  Future<void> dispose() => _controller.close();
}
