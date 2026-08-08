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

  /// Meeting whose action item produced this task, when one did
  /// (`sprint-03` validation rules). Nullable and not a foreign key: deleting
  /// the meeting must not delete the task.
  TextColumn get sourceMeetingId =>
      text().named('source_meeting_id').nullable()();

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

/// Storage for summarized meetings.
///
/// **BR-03 is why [rawTranscript] is nullable.** An ephemeral meeting reaches
/// this table with no transcript at all — the column exists only for meetings
/// the user opted to keep whole, and `Meeting.forStorage` is the single gate
/// that decides which is which.
class MeetingRows extends Table {
  @override
  String get tableName => 'meetings';

  TextColumn get id => text()();
  TextColumn get title => text()();

  /// `MeetingType.name` — the name, not the index, so reordering the enum
  /// cannot silently reinterpret stored rows.
  TextColumn get type => text()();

  /// Milliseconds since epoch, UTC (as in `tasks`).
  IntColumn get createdAtMs => integer().named('created_at_ms')();

  /// `RetentionPolicy.name`. Kept on the row so a stored meeting still says
  /// what the user chose, long after the choice was made.
  TextColumn get retention => text()();

  /// Present only under `RetentionPolicy.persisted` (BR-03).
  TextColumn get rawTranscript => text().named('raw_transcript').nullable()();

  /// The summary as JSON: `sections`, `actionItems`, `generatedAt`,
  /// `engineId`.
  ///
  /// A blob rather than child tables because the shape is the template's, not
  /// the schema's: section headings are user data and change whenever a
  /// template is edited. Modelling them as columns would mean a migration
  /// every time a user renames a heading.
  TextColumn get summary => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Storage for the summarization templates (`docs/architecture.md` §5.3).
///
/// Templates are data, not code: the four built-ins are seeded rows like any
/// other and the user may edit or delete them.
class MeetingTemplateRows extends Table {
  @override
  String get tableName => 'meeting_templates';

  /// `builtin.retro` for a seeded template, a UUID for a user's own. Stable,
  /// which is what lets the seed tell "already there" from "newly made".
  TextColumn get id => text()();

  /// `MeetingType.name`.
  TextColumn get type => text()();

  TextColumn get systemPrompt => text().named('system_prompt')();

  /// JSON array of `{"title": …, "guidance": …}`, order preserved — the order
  /// the summary's sections come back in.
  TextColumn get sections => text().withDefault(const Constant('[]'))();

  BoolColumn get extractActionItems => boolean()
      .named('extract_action_items')
      .withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Storage for voice-captured reminders (`docs/architecture.md` §8).
///
/// **There is no audio column, and there never will be.** `Reminder` carries a
/// transient `sourceAudioNote`; the repository drops it on write and the schema
/// gives it nowhere to land (BR-06). A column here would be the one place a
/// forgetful caller could leave voice audio on the user's disk.
///
/// Sprint 05 fills this table; Sprint 06 schedules from it.
class ReminderRows extends Table {
  @override
  String get tableName => 'reminders';

  TextColumn get id => text()();

  /// The transcribed text. Never the audio it came from (BR-06).
  ///
  /// Named `body` in Dart because `text` is `Table`'s own column builder;
  /// the column itself is `text`, which is what the entity calls it.
  TextColumn get body => text().named('text')();

  /// Milliseconds since epoch, UTC (as in `tasks`).
  IntColumn get triggerAtMs => integer().named('trigger_at_ms')();
  IntColumn get createdAtMs => integer().named('created_at_ms')();

  /// `true` once the notification has been delivered. Sprint 06 sets it; the
  /// column exists now so the Windows check-on-launch has something to read
  /// rather than a migration to wait for.
  BoolColumn get isFired =>
      boolean().named('is_fired').withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Key–value storage for the user's preferences.
///
/// A single narrow table rather than a column per setting: preferences are
/// added by nearly every sprint, and a schema migration per checkbox would be
/// a migration nobody reads. Values are JSON, so a preference can grow from a
/// boolean into an object without a fifth migration.
///
/// Note what is **not** here — no API key, no token. Those live in the
/// platform's secure store and nowhere else (BR-08).
class SettingsRows extends Table {
  @override
  String get tableName => 'settings';

  /// Namespaced key, e.g. `voice`.
  TextColumn get key => text()();

  /// The value as JSON.
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}

/// The application database.
///
/// Lives behind the repository ports; nothing outside
/// `infrastructure/persistence/` may reference it (`sprint-01` validation
/// rules, enforced by gate G5).
@DriftDatabase(
  tables: <Type>[
    TaskRows,
    OutboxRows,
    MeetingRows,
    MeetingTemplateRows,
    ReminderRows,
    SettingsRows,
  ],
)
class NorteDatabase extends _$NorteDatabase {
  NorteDatabase(super.executor);

  @override
  int get schemaVersion => 4;

  /// Every upgrade is additive, and deliberately so: a user who has been
  /// running Norte since Sprint 01 keeps every task, link and queued
  /// operation they had.
  ///
  /// * 1 → 2 adds the outbox.
  /// * 2 → 3 adds meetings and templates, and the tasks table gains the
  ///   back-reference to the meeting an action item came from.
  /// * 3 → 4 adds reminders and the preferences table.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) await m.createTable(outboxRows);
      if (from < 3) {
        await m.createTable(meetingRows);
        await m.createTable(meetingTemplateRows);
        await m.addColumn(taskRows, taskRows.sourceMeetingId);
      }
      if (from < 4) {
        await m.createTable(reminderRows);
        await m.createTable(settingsRows);
      }
    },
  );
}
