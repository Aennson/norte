import 'package:drift/drift.dart';

import '../../domain/entities/reminder.dart';
import '../../domain/failures/failure.dart';
import '../../domain/ports/reminder_repository.dart';
import 'norte_database.dart';

/// Drift-backed [ReminderRepository].
///
/// Timestamps are normalised to **UTC** in and out, as in
/// `DriftTaskRepository`, so a value survives a round-trip whatever the
/// device's timezone.
///
/// **`sourceAudioNote` is dropped on write (BR-06).** Not by remembering to
/// clear it — [_toCompanion] simply has nowhere to put it, and neither does the
/// schema. A reminder read back therefore always has it `null`, which is what
/// the port promises and what S06-UT-04 will assert.
///
/// Storage errors are translated into [StorageFailure] — a Drift exception
/// never escapes this class (`docs/project-rules.md` §6).
class DriftReminderRepository implements ReminderRepository {
  const DriftReminderRepository(this._database);

  final NorteDatabase _database;

  @override
  Stream<List<Reminder>> watchAll() {
    return _database
        .select(_database.reminderRows)
        .watch()
        .map(
          (List<ReminderRow> rows) =>
              List<Reminder>.unmodifiable(rows.map(_toEntity)),
        )
        .handleError(
          (Object error) => throw StorageFailure('watching reminders failed'),
        );
  }

  @override
  Future<List<Reminder>> listAll() async {
    final List<ReminderRow> rows = await _guard(
      () => _database.select(_database.reminderRows).get(),
      'reading reminders failed',
    );
    return List<Reminder>.unmodifiable(rows.map(_toEntity));
  }

  @override
  Future<Reminder?> findById(String id) async {
    final ReminderRow? row = await _guard(
      () => (_database.select(
        _database.reminderRows,
      )..where(($ReminderRowsTable r) => r.id.equals(id))).getSingleOrNull(),
      'reading reminder $id failed',
    );
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<void> save(Reminder reminder) {
    return _guard(
      () => _database
          .into(_database.reminderRows)
          .insertOnConflictUpdate(_toCompanion(reminder)),
      'saving reminder ${reminder.id} failed',
    );
  }

  @override
  Future<void> delete(String id) {
    return _guard(
      () => (_database.delete(
        _database.reminderRows,
      )..where(($ReminderRowsTable r) => r.id.equals(id))).go(),
      'deleting reminder $id failed',
    );
  }

  Future<T> _guard<T>(Future<T> Function() operation, String message) async {
    try {
      return await operation();
    } on Failure {
      rethrow;
    } catch (_) {
      throw StorageFailure(message);
    }
  }

  Reminder _toEntity(ReminderRow row) => Reminder(
    id: row.id,
    text: row.body,
    triggerAt: DateTime.fromMillisecondsSinceEpoch(
      row.triggerAtMs,
      isUtc: true,
    ),
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      row.createdAtMs,
      isUtc: true,
    ),
    isFired: row.isFired,
    // Never read back, because it is never written (BR-06).
  );

  ReminderRowsCompanion _toCompanion(Reminder reminder) =>
      ReminderRowsCompanion.insert(
        id: reminder.id,
        body: reminder.text,
        triggerAtMs: reminder.triggerAt.toUtc().millisecondsSinceEpoch,
        createdAtMs: reminder.createdAt.toUtc().millisecondsSinceEpoch,
        isFired: Value<bool>(reminder.isFired),
      );
}
