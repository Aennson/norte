import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/meeting.dart';
import '../../domain/entities/meeting_template.dart';
import '../../domain/failures/failure.dart';
import '../../domain/ports/meeting_template_repository.dart';
import 'norte_database.dart';

/// Drift-backed [MeetingTemplateRepository].
///
/// The seeding rule is the interesting part — see [seedDefaults].
class DriftMeetingTemplateRepository implements MeetingTemplateRepository {
  const DriftMeetingTemplateRepository(this._database);

  final NorteDatabase _database;

  /// Inserts any built-in template that is not already stored.
  ///
  /// **Insert-if-absent, in one transaction.** That single choice delivers all
  /// three exit criteria of S03-IT-02: a fresh database gets the four
  /// defaults; a second run inserts nothing, because the ids already exist;
  /// and a template the user has edited is untouched, because its id exists
  /// too. Nothing here compares contents, so there is no version of this that
  /// silently reverts someone's edits.
  ///
  /// A default the user deleted comes back on the next seed. That is what
  /// "reset to defaults" means, and deleting it again is one tap.
  @override
  Future<void> seedDefaults() {
    return _guard(() async {
      await _database.transaction(() async {
        final Set<String> existing =
            (await _database.select(_database.meetingTemplateRows).get())
                .map((MeetingTemplateRow row) => row.id)
                .toSet();

        for (final MeetingTemplate template in defaultMeetingTemplates) {
          if (existing.contains(template.id)) continue;
          await _database
              .into(_database.meetingTemplateRows)
              .insert(_toCompanion(template));
        }
      });
    }, 'seeding the meeting templates failed');
  }

  @override
  Stream<List<MeetingTemplate>> watchAll() {
    return (_database.select(_database.meetingTemplateRows)
          ..orderBy(<OrderingTerm Function($MeetingTemplateRowsTable)>[
            ($MeetingTemplateRowsTable t) => OrderingTerm(expression: t.type),
          ]))
        .watch()
        .map(_sorted)
        .handleError(
          (Object error) =>
              throw const StorageFailure('watching templates failed'),
        );
  }

  @override
  Future<List<MeetingTemplate>> listAll() async {
    final List<MeetingTemplateRow> rows = await _guard(
      () => _database.select(_database.meetingTemplateRows).get(),
      'reading templates failed',
    );
    return _sorted(rows);
  }

  @override
  Future<MeetingTemplate?> findById(String id) async {
    final MeetingTemplateRow? row = await _guard(
      () =>
          (_database.select(_database.meetingTemplateRows)
                ..where(($MeetingTemplateRowsTable t) => t.id.equals(id)))
              .getSingleOrNull(),
      'reading template $id failed',
    );
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<MeetingTemplate?> findByType(MeetingType type) async {
    final MeetingTemplateRow? row = await _guard(
      () =>
          (_database.select(_database.meetingTemplateRows)
                ..where(
                  ($MeetingTemplateRowsTable t) => t.type.equals(type.name),
                )
                ..limit(1))
              .getSingleOrNull(),
      'reading the ${type.name} template failed',
    );
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<void> save(MeetingTemplate template) {
    return _guard(
      () => _database
          .into(_database.meetingTemplateRows)
          .insertOnConflictUpdate(_toCompanion(template)),
      'saving template ${template.id} failed',
    );
  }

  @override
  Future<void> delete(String id) {
    return _guard(
      () => (_database.delete(
        _database.meetingTemplateRows,
      )..where(($MeetingTemplateRowsTable t) => t.id.equals(id))).go(),
      'deleting template $id failed',
    );
  }

  /// Ordered by `MeetingType.index` so the four defaults always appear in the
  /// documented order — SQL would sort them alphabetically by name, which is
  /// not the order §5.3 lists them in.
  List<MeetingTemplate> _sorted(List<MeetingTemplateRow> rows) {
    final List<MeetingTemplate> templates = rows.map(_toEntity).toList()
      ..sort(
        (MeetingTemplate a, MeetingTemplate b) =>
            a.type.index.compareTo(b.type.index),
      );
    return List<MeetingTemplate>.unmodifiable(templates);
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

  MeetingTemplate _toEntity(MeetingTemplateRow row) => MeetingTemplate(
    id: row.id,
    type: _typeFrom(row.type),
    systemPrompt: row.systemPrompt,
    sections: _sectionsFrom(row.sections),
    extractActionItems: row.extractActionItems,
  );

  MeetingTemplateRowsCompanion _toCompanion(MeetingTemplate template) =>
      MeetingTemplateRowsCompanion.insert(
        id: template.id,
        type: template.type.name,
        systemPrompt: template.systemPrompt,
        sections: Value<String>(
          jsonEncode(<Object?>[
            for (final TemplateSection section in template.sections)
              <String, Object?>{
                'title': section.title,
                'guidance': section.guidance,
              },
          ]),
        ),
        extractActionItems: Value<bool>(template.extractActionItems),
      );
}

MeetingType _typeFrom(String name) => MeetingType.values.firstWhere(
  (MeetingType value) => value.name == name,
  orElse: () => MeetingType.custom,
);

List<TemplateSection> _sectionsFrom(String encoded) {
  if (encoded.isEmpty) return const <TemplateSection>[];
  final Object? decoded = _tryDecode(encoded);
  if (decoded is! List<Object?>) return const <TemplateSection>[];
  return List<TemplateSection>.unmodifiable(<TemplateSection>[
    for (final Object? entry in decoded)
      if (entry is Map<String, Object?> && entry['title'] is String)
        TemplateSection(
          title: entry['title']! as String,
          guidance: entry['guidance'] as String?,
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
