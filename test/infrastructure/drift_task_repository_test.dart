import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/entities/jira_link.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/infrastructure/persistence/drift_task_repository.dart';
import 'package:norte/infrastructure/persistence/norte_database.dart';
import 'package:norte/infrastructure/persistence/norte_database_factory.dart';

/// S01-IT-01..03 — the Drift adapter against a real in-memory database
/// (`docs/testing-strategy.md` §1).
void main() {
  late NorteDatabase database;
  late DriftTaskRepository repository;

  /// A task with **every** field populated, including tags and a Jira link.
  ///
  /// Timestamps carry non-zero milliseconds on purpose: the schema stores
  /// epoch milliseconds precisely so this precision survives the round-trip.
  final Task fullTask = Task(
    id: '7d3f2b1a-9c4e-4a8b-9f1d-2e5c6a7b8d90',
    title: 'Review PR',
    description: 'the connector one',
    status: TaskStatus.inProgress,
    priority: Priority.urgent,
    dueDate: DateTime.utc(2026, 1, 5, 18, 30, 15, 123),
    jiraLink: JiraLink(
      issueKey: 'PROJ-123',
      siteUrl: 'https://example.atlassian.net',
      lastKnownStatus: 'In Review',
      lastSyncedAt: DateTime.utc(2026, 1, 1, 9, 0, 0, 456),
    ),
    tags: const <String>['api', 'urgent', 'jira'],
    createdAt: DateTime.utc(2026, 1, 1, 9, 0, 0, 789),
    updatedAt: DateTime.utc(2026, 1, 1, 10, 15, 30, 42),
  );

  setUp(() {
    database = openInMemoryNorteDatabase();
    repository = DriftTaskRepository(database);
  });

  tearDown(() => database.close());

  test(
    'S01-IT-01: a fully populated task survives a round-trip unchanged',
    () async {
      await repository.save(fullTask);

      final Task? read = await repository.findById(fullTask.id);

      // Whole-entity equality covers every field at once; the asserts below name
      // the ones the mapping could plausibly lose.
      expect(read, fullTask);
      expect(read!.tags, <String>[
        'api',
        'urgent',
        'jira',
      ], reason: 'order kept');
      expect(read.jiraLink, fullTask.jiraLink);
      expect(
        read.updatedAt.millisecondsSinceEpoch,
        fullTask.updatedAt.millisecondsSinceEpoch,
        reason: 'millisecond precision must not be truncated to seconds',
      );
      expect(read.dueDate!.millisecond, 123);
      expect(read.createdAt.millisecond, 789);
      expect(read.jiraLink!.lastSyncedAt!.millisecond, 456);
    },
  );

  test(
    'S01-IT-01: a minimal task round-trips with its optional fields empty',
    () async {
      final Task minimal = Task(
        id: 'minimal',
        title: 'Buy coffee',
        createdAt: DateTime.utc(2026, 1, 1, 9),
        updatedAt: DateTime.utc(2026, 1, 1, 9),
      );

      await repository.save(minimal);

      final Task? read = await repository.findById('minimal');
      expect(read, minimal);
      expect(read!.description, isNull);
      expect(read.dueDate, isNull);
      expect(read.jiraLink, isNull);
      expect(read.tags, isEmpty);
    },
  );

  test('S01-IT-01: saving the same id twice replaces the row', () async {
    await repository.save(fullTask);
    await repository.save(fullTask.copyWith(title: 'Review the other PR'));

    final List<Task> all = await repository.listAll();
    expect(all, hasLength(1), reason: 'save is an upsert keyed by id');
    expect(all.single.title, 'Review the other PR');
  });

  test(
    'S01-IT-02: the stream emits once per mutation, with the new state',
    () async {
      final List<List<Task>> emissions = <List<Task>>[];
      final Stream<List<Task>> stream = repository.watchAll();

      // Take the initial emission plus one per mutation (3 mutations).
      final Future<void> collected = stream.take(4).forEach(emissions.add);

      // Let the subscription deliver the initial (empty) state first, then
      // mutate one step at a time so the emissions cannot coalesce.
      await pumpEventQueue();
      await repository.save(fullTask);
      await pumpEventQueue();
      await repository.save(fullTask.copyWith(status: TaskStatus.done));
      await pumpEventQueue();
      await repository.delete(fullTask.id);
      await collected;

      expect(
        emissions,
        hasLength(4),
        reason: 'initial state plus one emission per mutation',
      );
      expect(emissions[0], isEmpty, reason: 'the database starts empty');
      expect(
        emissions[1].single.status,
        TaskStatus.inProgress,
        reason: 'insert',
      );
      expect(emissions[2].single.status, TaskStatus.done, reason: 'update');
      expect(emissions[3], isEmpty, reason: 'delete');
    },
  );

  test(
    'S01-IT-03: deleting the same task twice is a no-op the second time',
    () async {
      final Task other = Task(
        id: 'survivor',
        title: 'Keep me',
        createdAt: DateTime.utc(2026, 1, 1, 9),
        updatedAt: DateTime.utc(2026, 1, 1, 9),
      );
      await repository.save(fullTask);
      await repository.save(other);

      await repository.delete(fullTask.id);
      expect(await repository.findById(fullTask.id), isNull);

      // The second delete must neither throw nor touch another row.
      await expectLater(repository.delete(fullTask.id), completes);

      final List<Task> remaining = await repository.listAll();
      expect(remaining, <Task>[other]);
    },
  );

  test('S01-IT-03: deleting an id that never existed succeeds', () async {
    await repository.save(fullTask);

    await expectLater(repository.delete('never-existed'), completes);

    expect(await repository.listAll(), <Task>[fullTask]);
  });
}
