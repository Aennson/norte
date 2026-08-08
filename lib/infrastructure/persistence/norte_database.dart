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

/// Storage for the queue of Jira writes waiting to be dispatched (BR-05).
///
/// The queue is durable on purpose: an action taken with no network is still
/// waiting when the network returns, and still waiting after a restart. That
/// is what "offline-first" has to mean for a write.
///
/// Note what is *not* here — no Jira credential column. The token lives in
/// the platform's secure store and nowhere else (BR-08).
class OutboxRows extends Table {
  @override
  String get tableName => 'outbox';

  /// Insertion order, and the primary key. Auto-incrementing rather than
  /// derived from a timestamp: two operations created in the same millisecond
  /// must still have a defined order (S02-IT-03).
  IntColumn get sequence => integer().autoIncrement()();

  /// Idempotency key (BR-05), a UUID v4 from the use case. Unique, so the
  /// same operation cannot occupy two rows however often a dispatch is
  /// retried.
  TextColumn get operationId => text().named('operation_id').unique()();

  /// `OutboxOperationKind.name`.
  TextColumn get kind => text()();

  /// Target issue key, or the project key for a `createIssue`.
  TextColumn get issueKey => text().named('issue_key')();

  /// Target status, comment body, or new-issue summary.
  TextColumn get payload => text()();

  /// Local task the operation belongs to, when there is one.
  TextColumn get taskId => text().named('task_id').nullable()();

  /// `OutboxOperationState.name`.
  TextColumn get state => text()();

  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Milliseconds since epoch, UTC.
  IntColumn get createdAtMs => integer().named('created_at_ms')();

  /// Opening of the backoff window; `null` means "ready now".
  IntColumn get nextAttemptAtMs =>
      integer().named('next_attempt_at_ms').nullable()();

  /// Message of the last failure. Never a payload or a credential (BR-08).
  TextColumn get lastError => text().named('last_error').nullable()();
}

/// The application database.
///
/// Lives behind `TaskRepository` and `OutboxRepository`; nothing outside
/// `infrastructure/persistence/` may reference it (`sprint-01` validation
/// rules, enforced by gate G5).
@DriftDatabase(tables: <Type>[TaskRows, OutboxRows])
class NorteDatabase extends _$NorteDatabase {
  NorteDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  /// Schema 1 → 2 adds the outbox. Existing task rows are untouched: a user
  /// upgrading into Sprint 02 keeps every task they had.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) await m.createTable(outboxRows);
    },
  );
}
