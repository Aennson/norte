import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/jira_link.dart';
import '../../domain/entities/task.dart';
import '../../domain/failures/failure.dart';
import '../../domain/ports/task_repository.dart';
import 'norte_database.dart';

/// Drift-backed [TaskRepository].
///
/// All timestamps are normalised to **UTC** on the way in and returned as UTC,
/// so a value survives a round-trip unchanged regardless of the device's
/// timezone. The use cases already stamp UTC (`CreateTask`, `UpdateTask`).
///
/// Storage errors are translated into [StorageFailure] — a Drift exception
/// never escapes this class (`docs/project-rules.md` §6).
class DriftTaskRepository implements TaskRepository {
  const DriftTaskRepository(this._database);

  final NorteDatabase _database;

  @override
  Stream<List<Task>> watchAll() {
    return _database
        .select(_database.taskRows)
        .watch()
        .map(
          (List<TaskRow> rows) => List<Task>.unmodifiable(rows.map(_toEntity)),
        )
        .handleError(
          (Object error) => throw StorageFailure('watching tasks failed'),
        );
  }

  @override
  Future<List<Task>> listAll() async {
    final List<TaskRow> rows = await _guard(
      () => _database.select(_database.taskRows).get(),
      'reading tasks failed',
    );
    return List<Task>.unmodifiable(rows.map(_toEntity));
  }

  @override
  Future<Task?> findById(String id) async {
    final TaskRow? row = await _guard(
      () => (_database.select(
        _database.taskRows,
      )..where(($TaskRowsTable t) => t.id.equals(id))).getSingleOrNull(),
      'reading task $id failed',
    );
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<void> save(Task task) {
    return _guard(
      () => _database
          .into(_database.taskRows)
          .insertOnConflictUpdate(_toCompanion(task)),
      'saving task ${task.id} failed',
    );
  }

  /// Deleting an absent id is a no-op, not an error (S01-IT-03): the
  /// `DELETE ... WHERE id = ?` simply matches zero rows.
  @override
  Future<void> delete(String id) {
    return _guard(
      () => (_database.delete(
        _database.taskRows,
      )..where(($TaskRowsTable t) => t.id.equals(id))).go(),
      'deleting task $id failed',
    );
  }

  /// Translates anything the database throws into a [StorageFailure].
  ///
  /// Deliberately broad: SQLite surfaces errors as several unrelated types
  /// (`SqliteException`, `DriftRemoteException`, plain `StateError` from the
  /// isolate bridge), and none of them may cross the port boundary
  /// (`docs/project-rules.md` §6). A [Failure] already raised further in is
  /// passed through untouched.
  Future<T> _guard<T>(Future<T> Function() operation, String message) async {
    try {
      return await operation();
    } on Failure {
      rethrow;
    } catch (_) {
      throw StorageFailure(message);
    }
  }

  Task _toEntity(TaskRow row) {
    return Task(
      id: row.id,
      title: row.title,
      description: row.description,
      status: _statusFrom(row.status),
      priority: _priorityFrom(row.priority),
      dueDate: _dateFrom(row.dueDateMs),
      jiraLink: row.jiraIssueKey == null || row.jiraSiteUrl == null
          ? null
          : JiraLink(
              issueKey: row.jiraIssueKey!,
              siteUrl: row.jiraSiteUrl!,
              lastKnownStatus: row.jiraLastKnownStatus,
              lastSyncedAt: _dateFrom(row.jiraLastSyncedAtMs),
            ),
      tags: _tagsFrom(row.tags),
      sourceMeetingId: row.sourceMeetingId,
      createdAt: _dateFrom(row.createdAtMs)!,
      updatedAt: _dateFrom(row.updatedAtMs)!,
    );
  }

  TaskRowsCompanion _toCompanion(Task task) {
    final JiraLink? link = task.jiraLink;
    return TaskRowsCompanion.insert(
      id: task.id,
      title: task.title,
      description: Value<String?>(task.description),
      status: task.status.name,
      priority: task.priority.name,
      dueDateMs: Value<int?>(_msFrom(task.dueDate)),
      createdAtMs: _msFrom(task.createdAt)!,
      updatedAtMs: _msFrom(task.updatedAt)!,
      tags: Value<String>(jsonEncode(task.tags)),
      sourceMeetingId: Value<String?>(task.sourceMeetingId),
      jiraIssueKey: Value<String?>(link?.issueKey),
      jiraSiteUrl: Value<String?>(link?.siteUrl),
      jiraLastKnownStatus: Value<String?>(link?.lastKnownStatus),
      jiraLastSyncedAtMs: Value<int?>(_msFrom(link?.lastSyncedAt)),
    );
  }
}

int? _msFrom(DateTime? value) => value?.toUtc().millisecondsSinceEpoch;

DateTime? _dateFrom(int? ms) =>
    ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

/// Unknown names fall back to the entity defaults rather than throwing: a row
/// written by a future schema must not make the whole list unreadable.
TaskStatus _statusFrom(String name) => TaskStatus.values.firstWhere(
  (TaskStatus value) => value.name == name,
  orElse: () => TaskStatus.todo,
);

Priority _priorityFrom(String name) => Priority.values.firstWhere(
  (Priority value) => value.name == name,
  orElse: () => Priority.medium,
);

List<String> _tagsFrom(String encoded) {
  if (encoded.isEmpty) return const <String>[];
  final Object? decoded = jsonDecode(encoded);
  if (decoded is! List<Object?>) return const <String>[];
  return List<String>.unmodifiable(decoded.whereType<String>());
}
