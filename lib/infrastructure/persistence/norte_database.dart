import 'package:drift/drift.dart';

part 'norte_database.g.dart';

/// Storage for `Task` rows.
///
/// Design notes that the mapper in `drift_task_repository.dart` relies on:
///
/// * **Timestamps are integers**, milliseconds since epoch in UTC. Drift's
///   default `DateTime` column stores whole seconds, which would silently
///   truncate the millisecond precision S01-IT-01 asserts.
/// * **`tags` is a JSON array of strings**, so the user's ordering survives a
///   round-trip. A delimiter-joined string could not hold a tag containing the
///   delimiter.
/// * **The Jira link is four nullable columns**, not a blob: a link is
///   optional and removable (BR-01), and the app stores only the four fields
///   BR-09 allows — it never mirrors the ticket.
class TaskRows extends Table {
  @override
  String get tableName => 'tasks';

  /// UUID v4 produced by the use case.
  TextColumn get id => text()();

  TextColumn get title => text()();
  TextColumn get description => text().nullable()();

  /// `TaskStatus.name` — the name, not the index, so reordering the enum
  /// cannot silently reinterpret stored rows.
  TextColumn get status => text()();

  /// `Priority.name`, for the same reason as [status].
  TextColumn get priority => text()();

  /// Milliseconds since epoch, UTC.
  IntColumn get dueDateMs => integer().named('due_date_ms').nullable()();
  IntColumn get createdAtMs => integer().named('created_at_ms')();
  IntColumn get updatedAtMs => integer().named('updated_at_ms')();

  /// JSON array of strings, order preserved.
  TextColumn get tags => text().withDefault(const Constant('[]'))();

  TextColumn get jiraIssueKey => text().named('jira_issue_key').nullable()();
  TextColumn get jiraSiteUrl => text().named('jira_site_url').nullable()();
  TextColumn get jiraLastKnownStatus =>
      text().named('jira_last_known_status').nullable()();
  IntColumn get jiraLastSyncedAtMs =>
      integer().named('jira_last_synced_at_ms').nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// The application database.
///
/// Lives behind `TaskRepository`; nothing outside
/// `infrastructure/persistence/` may reference it (`sprint-01` validation
/// rules, enforced by gate G5).
@DriftDatabase(tables: <Type>[TaskRows])
class NorteDatabase extends _$NorteDatabase {
  NorteDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
