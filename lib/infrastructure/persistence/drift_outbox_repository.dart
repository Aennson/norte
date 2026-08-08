import 'package:drift/drift.dart';

import '../../domain/entities/outbox_operation.dart';
import '../../domain/failures/failure.dart';
import '../../domain/ports/outbox_repository.dart';
import 'norte_database.dart';

/// Drift-backed [OutboxRepository].
///
/// The queue lives in the same database as the tasks, which is what makes an
/// action durable the instant the user takes it: enqueuing a transition and
/// updating the task are two writes to one file, and a crash between them
/// loses at most the operation, never the task.
///
/// Timestamps are stored as UTC milliseconds, matching `DriftTaskRepository`.
/// Storage errors are translated into [StorageFailure]
/// (`docs/project-rules.md` §6).
class DriftOutboxRepository implements OutboxRepository {
  const DriftOutboxRepository(this._database);

  final NorteDatabase _database;

  @override
  Future<OutboxOperation> enqueue(OutboxOperation operation) async {
    final int sequence = await _guard(
      () =>
          _database.into(_database.outboxRows).insert(_toInsertable(operation)),
      'enqueuing operation ${operation.operationId} failed',
    );
    return operation.copyWith(sequence: sequence);
  }

  /// Ready operations only: `pending`, and past their backoff window.
  ///
  /// An operation whose window has not opened is not returned at all, so the
  /// dispatcher cannot accidentally burn an attempt early (S02-IT-02).
  @override
  Future<List<OutboxOperation>> pending(DateTime now) async {
    final int nowMs = now.toUtc().millisecondsSinceEpoch;
    final List<OutboxRow> rows = await _guard(
      () =>
          (_database.select(_database.outboxRows)
                ..where(
                  ($OutboxRowsTable t) =>
                      t.state.equals(OutboxOperationState.pending.name) &
                      (t.nextAttemptAtMs.isNull() |
                          t.nextAttemptAtMs.isSmallerOrEqualValue(nowMs)),
                )
                ..orderBy(<OrderClauseGenerator<$OutboxRowsTable>>[
                  ($OutboxRowsTable t) => OrderingTerm.asc(t.sequence),
                ]))
              .get(),
      'reading the outbox failed',
    );
    return List<OutboxOperation>.unmodifiable(rows.map(_toEntity));
  }

  @override
  Future<List<OutboxOperation>> unsettled() async {
    final List<OutboxRow> rows = await _guard(
      () => (_unsettledQuery()).get(),
      'reading the outbox failed',
    );
    return List<OutboxOperation>.unmodifiable(rows.map(_toEntity));
  }

  @override
  Stream<List<OutboxOperation>> watchUnsettled() {
    return _unsettledQuery()
        .watch()
        .map(
          (List<OutboxRow> rows) =>
              List<OutboxOperation>.unmodifiable(rows.map(_toEntity)),
        )
        .handleError(
          (Object error) => throw StorageFailure('watching the outbox failed'),
        );
  }

  @override
  Future<OutboxOperation?> findById(String operationId) async {
    final OutboxRow? row = await _guard(
      () =>
          (_database.select(_database.outboxRows)..where(
                ($OutboxRowsTable t) => t.operationId.equals(operationId),
              ))
              .getSingleOrNull(),
      'reading operation $operationId failed',
    );
    return row == null ? null : _toEntity(row);
  }

  /// Updates the row carrying `operation.operationId`, inserting it when there
  /// is none — the dispatcher calls this after every attempt.
  @override
  Future<void> save(OutboxOperation operation) async {
    final int updated = await _guard(
      () =>
          (_database.update(_database.outboxRows)..where(
                ($OutboxRowsTable t) =>
                    t.operationId.equals(operation.operationId),
              ))
              .write(_toUpdateCompanion(operation)),
      'saving operation ${operation.operationId} failed',
    );
    if (updated == 0) await enqueue(operation);
  }

  @override
  Future<void> purgeCompleted(DateTime before) {
    final int beforeMs = before.toUtc().millisecondsSinceEpoch;
    return _guard(
      () =>
          (_database.delete(_database.outboxRows)..where(
                ($OutboxRowsTable t) =>
                    t.state.equals(OutboxOperationState.completed.name) &
                    t.createdAtMs.isSmallerThanValue(beforeMs),
              ))
              .go(),
      'purging the outbox failed',
    );
  }

  Selectable<OutboxRow> _unsettledQuery() =>
      _database.select(_database.outboxRows)
        ..where(
          ($OutboxRowsTable t) =>
              t.state.equals(OutboxOperationState.completed.name).not(),
        )
        ..orderBy(<OrderClauseGenerator<$OutboxRowsTable>>[
          ($OutboxRowsTable t) => OrderingTerm.asc(t.sequence),
        ]);

  /// See `DriftTaskRepository._guard` — same reasoning, same broadness.
  Future<T> _guard<T>(Future<T> Function() operation, String message) async {
    try {
      return await operation();
    } on Failure {
      rethrow;
    } catch (_) {
      throw StorageFailure(message);
    }
  }

  OutboxRowsCompanion _toInsertable(OutboxOperation operation) =>
      OutboxRowsCompanion.insert(
        operationId: operation.operationId,
        kind: operation.kind.name,
        issueKey: operation.issueKey,
        payload: operation.payload,
        taskId: Value<String?>(operation.taskId),
        state: operation.state.name,
        attempts: Value<int>(operation.attempts),
        createdAtMs: operation.createdAt.toUtc().millisecondsSinceEpoch,
        nextAttemptAtMs: Value<int?>(_msFrom(operation.nextAttemptAt)),
        lastError: Value<String?>(operation.lastError),
      );

  /// Only the mutable half: `operationId`, `kind`, `issueKey`, `payload` and
  /// `createdAt` describe what the user asked for and never change.
  OutboxRowsCompanion _toUpdateCompanion(OutboxOperation operation) =>
      OutboxRowsCompanion(
        state: Value<String>(operation.state.name),
        attempts: Value<int>(operation.attempts),
        nextAttemptAtMs: Value<int?>(_msFrom(operation.nextAttemptAt)),
        lastError: Value<String?>(operation.lastError),
      );

  OutboxOperation _toEntity(OutboxRow row) => OutboxOperation(
    operationId: row.operationId,
    kind: _kindFrom(row.kind),
    issueKey: row.issueKey,
    payload: row.payload,
    taskId: row.taskId,
    state: _stateFrom(row.state),
    attempts: row.attempts,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      row.createdAtMs,
      isUtc: true,
    ),
    nextAttemptAt: _dateFrom(row.nextAttemptAtMs),
    lastError: row.lastError,
    sequence: row.sequence,
  );
}

int? _msFrom(DateTime? value) => value?.toUtc().millisecondsSinceEpoch;

DateTime? _dateFrom(int? ms) =>
    ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

/// An unreadable name is treated as a comment: the least destructive of the
/// three, so a row written by a future schema can never fire a transition
/// nobody asked for.
OutboxOperationKind _kindFrom(String name) =>
    OutboxOperationKind.values.firstWhere(
      (OutboxOperationKind value) => value.name == name,
      orElse: () => OutboxOperationKind.comment,
    );

/// An unreadable state is treated as `failed`, never as `pending`: the app
/// stops and asks rather than dispatching something it does not understand.
OutboxOperationState _stateFrom(String name) =>
    OutboxOperationState.values.firstWhere(
      (OutboxOperationState value) => value.name == name,
      orElse: () => OutboxOperationState.failed,
    );
