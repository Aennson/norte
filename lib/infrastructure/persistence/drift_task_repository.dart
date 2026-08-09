import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/jira_link.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_comment.dart';
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

  /// Tasks and their comments, joined in Dart.
  ///
  /// Two queries rather than a `join`: a task with three comments would come
  /// back as three rows to be regrouped, and the regrouping is the part that
  /// gets a task with no comments wrong.
  @override
  Stream<List<Task>> watchAll() {
    return _database
        .select(_database.taskRows)
        .watch()
        .asyncMap((List<TaskRow> rows) async {
          final Map<String, List<TaskComment>> comments = await _commentsFor(
            rows.map((TaskRow row) => row.id),
          );
          return List<Task>.unmodifiable(
            rows.map((TaskRow row) => _toEntity(row, comments[row.id])),
          );
        })
        .handleError(
          (Object error) => throw StorageFailure('watching tasks failed'),
        );
  }

  @override
  Future<List<Task>> listAll() async {
    return _guard(() async {
      final List<TaskRow> rows = await _database
          .select(_database.taskRows)
          .get();
      final Map<String, List<TaskComment>> comments = await _commentsFor(
        rows.map((TaskRow row) => row.id),
      );
      return List<Task>.unmodifiable(
        rows.map((TaskRow row) => _toEntity(row, comments[row.id])),
      );
    }, 'reading tasks failed');
  }

  @override
  Future<Task?> findById(String id) async {
    return _guard(() async {
      final TaskRow? row = await (_database.select(
        _database.taskRows,
      )..where(($TaskRowsTable t) => t.id.equals(id))).getSingleOrNull();
      if (row == null) return null;
      return _toEntity(row, (await _commentsFor(<String>[id]))[id]);
    }, 'reading task $id failed');
  }

  /// Upserts the task and **replaces** its comments with the ones it carries.
  ///
  /// Both in one transaction: a task whose comments were written and whose row
  /// was not — or the reverse — is a state no reader could make sense of.
  /// Replace rather than merge, because `Task.comments` is the whole list and
  /// a caller that removed one means it.
  @override
  Future<void> save(Task task) {
    return _guard(
      () => _database.transaction(() async {
        await _database
            .into(_database.taskRows)
            .insertOnConflictUpdate(_toCompanion(task));
        await _deleteComments(task.id);
        for (final (int index, TaskComment comment) in task.comments.indexed) {
          await _database
              .into(_database.taskCommentRows)
              .insert(
                TaskCommentRowsCompanion.insert(
                  id: comment.id,
                  taskId: task.id,
                  body: comment.body,
                  createdAtMs: _msFrom(comment.createdAt)!,
                  position: index,
                ),
              );
        }
      }),
      'saving task ${task.id} failed',
    );
  }

  /// Deleting an absent id is a no-op, not an error (S01-IT-03): the
  /// `DELETE ... WHERE id = ?` simply matches zero rows.
  ///
  /// The task's comments go with it, and no other task's do (S05a-IT-01).
  @override
  Future<void> delete(String id) {
    return _guard(
      () => _database.transaction(() async {
        await _deleteComments(id);
        await (_database.delete(
          _database.taskRows,
        )..where(($TaskRowsTable t) => t.id.equals(id))).go();
      }),
      'deleting task $id failed',
    );
  }

  Future<int> _deleteComments(String taskId) {
    return (_database.delete(
      _database.taskCommentRows,
    )..where(($TaskCommentRowsTable c) => c.taskId.equals(taskId))).go();
  }

  /// The comments of [taskIds], grouped by task and in insertion order.
  Future<Map<String, List<TaskComment>>> _commentsFor(
    Iterable<String> taskIds,
  ) async {
    final List<String> ids = taskIds.toList();
    if (ids.isEmpty) return const <String, List<TaskComment>>{};

    final List<TaskCommentRow> rows =
        await (_database.select(_database.taskCommentRows)
              ..where(($TaskCommentRowsTable c) => c.taskId.isIn(ids))
              ..orderBy(<OrderClauseGenerator<$TaskCommentRowsTable>>[
                ($TaskCommentRowsTable c) => OrderingTerm.asc(c.position),
              ]))
            .get();

    final Map<String, List<TaskComment>> grouped =
        <String, List<TaskComment>>{};
    for (final TaskCommentRow row in rows) {
      grouped
          .putIfAbsent(row.taskId, () => <TaskComment>[])
          .add(
            TaskComment(
              id: row.id,
              body: row.body,
              createdAt: _dateFrom(row.createdAtMs)!,
            ),
          );
    }
    return grouped;
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

  Task _toEntity(TaskRow row, List<TaskComment>? comments) {
    return Task(
      comments: List<TaskComment>.unmodifiable(
        comments ?? const <TaskComment>[],
      ),
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
