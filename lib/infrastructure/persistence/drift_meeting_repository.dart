import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/meeting.dart';
import '../../domain/failures/failure.dart';
import '../../domain/ports/meeting_repository.dart';
import 'norte_database.dart';

/// Drift-backed [MeetingRepository].
///
/// **This class does not enforce BR-03 — and must not.** It stores the meeting
/// it is handed. The transcript is stripped one layer up, by
/// `Meeting.forStorage`, which every write path goes through. Putting the rule
/// in the use case makes it provable without a database and means a second
/// adapter cannot be the place it is forgotten (S03-UT-04).
///
/// Timestamps are normalised to UTC in and out, as in `DriftTaskRepository`.
/// A Drift exception never escapes: everything becomes a [StorageFailure]
/// (`docs/project-rules.md` §6).
class DriftMeetingRepository implements MeetingRepository {
  const DriftMeetingRepository(this._database);

  final NorteDatabase _database;

  @override
  Stream<List<Meeting>> watchAll() {
    return (_database.select(
          _database.meetingRows,
        )..orderBy(<OrderingTerm Function($MeetingRowsTable)>[
          ($MeetingRowsTable m) =>
              OrderingTerm(expression: m.createdAtMs, mode: OrderingMode.desc),
        ]))
        .watch()
        .map(
          (List<MeetingRow> rows) =>
              List<Meeting>.unmodifiable(rows.map(_toEntity)),
        )
        .handleError(
          (Object error) =>
              throw const StorageFailure('watching meetings failed'),
        );
  }

  @override
  Future<List<Meeting>> listAll() async {
    final List<MeetingRow> rows = await _guard(
      () =>
          (_database.select(_database.meetingRows)
                ..orderBy(<OrderingTerm Function($MeetingRowsTable)>[
                  ($MeetingRowsTable m) => OrderingTerm(
                    expression: m.createdAtMs,
                    mode: OrderingMode.desc,
                  ),
                ]))
              .get(),
      'reading meetings failed',
    );
    return List<Meeting>.unmodifiable(rows.map(_toEntity));
  }

  @override
  Future<Meeting?> findById(String id) async {
    final MeetingRow? row = await _guard(
      () => (_database.select(
        _database.meetingRows,
      )..where(($MeetingRowsTable m) => m.id.equals(id))).getSingleOrNull(),
      'reading meeting $id failed',
    );
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<void> save(Meeting meeting) {
    return _guard(
      () => _database
          .into(_database.meetingRows)
          .insertOnConflictUpdate(_toCompanion(meeting)),
      'saving meeting ${meeting.id} failed',
    );
  }

  @override
  Future<void> delete(String id) {
    return _guard(
      () => (_database.delete(
        _database.meetingRows,
      )..where(($MeetingRowsTable m) => m.id.equals(id))).go(),
      'deleting meeting $id failed',
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

  Meeting _toEntity(MeetingRow row) => Meeting(
    id: row.id,
    title: row.title,
    type: _typeFrom(row.type),
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      row.createdAtMs,
      isUtc: true,
    ),
    // A `null` column and an empty transcript mean the same thing to the
    // domain: there is nothing here to read.
    rawTranscript: row.rawTranscript ?? '',
    retention: _retentionFrom(row.retention),
    summary: _summaryFrom(row.summary),
  );

  MeetingRowsCompanion _toCompanion(Meeting meeting) =>
      MeetingRowsCompanion.insert(
        id: meeting.id,
        title: meeting.title,
        type: meeting.type.name,
        createdAtMs: meeting.createdAt.toUtc().millisecondsSinceEpoch,
        retention: meeting.retention.name,
        rawTranscript: Value<String?>(
          meeting.rawTranscript.isEmpty ? null : meeting.rawTranscript,
        ),
        summary: Value<String?>(_encodeSummary(meeting.summary)),
      );
}

/// Unknown names fall back to the entity defaults rather than throwing: one
/// row written by a future schema must not make the whole list unreadable.
MeetingType _typeFrom(String name) => MeetingType.values.firstWhere(
  (MeetingType value) => value.name == name,
  orElse: () => MeetingType.custom,
);

/// An unreadable retention value reads as [RetentionPolicy.ephemeral] — the
/// safe direction. Guessing `persisted` would be the app deciding to keep a
/// transcript the user never asked it to keep.
RetentionPolicy _retentionFrom(String name) =>
    RetentionPolicy.values.firstWhere(
      (RetentionPolicy value) => value.name == name,
      orElse: () => RetentionPolicy.ephemeral,
    );

String? _encodeSummary(MeetingSummary? summary) {
  if (summary == null) return null;
  return jsonEncode(<String, Object?>{
    'sections': summary.sections,
    'generatedAt': summary.generatedAt.toUtc().toIso8601String(),
    'engineId': summary.engineId,
    'actionItems': <Object?>[
      for (final ActionItem item in summary.actionItems)
        <String, Object?>{
          'id': item.id,
          'description': item.description,
          'assignee': item.assignee,
          'dueDate': item.dueDate?.toUtc().toIso8601String(),
          'convertedTaskId': item.convertedTaskId,
        },
    ],
  });
}

MeetingSummary? _summaryFrom(String? encoded) {
  if (encoded == null || encoded.isEmpty) return null;
  final Object? decoded = _tryDecode(encoded);
  if (decoded is! Map<String, Object?>) return null;

  final Object? sections = decoded['sections'];
  final Object? generatedAt = decoded['generatedAt'];
  return MeetingSummary(
    sections: sections is Map<String, Object?>
        ? Map<String, String>.unmodifiable(<String, String>{
            for (final MapEntry<String, Object?> entry in sections.entries)
              entry.key: entry.value is String ? entry.value! as String : '',
          })
        : const <String, String>{},
    generatedAt: generatedAt is String
        ? DateTime.tryParse(generatedAt)?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
        : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    engineId: decoded['engineId'] as String?,
    actionItems: _itemsFrom(decoded['actionItems']),
  );
}

List<ActionItem> _itemsFrom(Object? items) {
  if (items is! List<Object?>) return const <ActionItem>[];
  return List<ActionItem>.unmodifiable(<ActionItem>[
    for (final Object? entry in items)
      if (entry is Map<String, Object?> &&
          entry['id'] is String &&
          entry['description'] is String)
        ActionItem(
          id: entry['id']! as String,
          description: entry['description']! as String,
          assignee: entry['assignee'] as String?,
          dueDate: switch (entry['dueDate']) {
            final String date => DateTime.tryParse(date)?.toUtc(),
            _ => null,
          },
          convertedTaskId: entry['convertedTaskId'] as String?,
        ),
  ]);
}

Object? _tryDecode(String encoded) {
  try {
    return jsonDecode(encoded);
  } on FormatException {
    return null;
  }
}
