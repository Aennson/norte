import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/entities/jira_link.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/infrastructure/persistence/drift_task_repository.dart';
import 'package:norte/infrastructure/persistence/norte_database.dart';

/// Tasks survive a restart (`sprint-01` Definition of Done).
///
/// The sprint asks for a manual check, and §5 of the report records one. This
/// covers the part a machine can prove: the rows are on disk, and a **new**
/// database instance opened over the same file reads them back intact — the
/// same sequence `openNorteDatabase()` performs on every launch. What it
/// cannot cover is the app process itself, which is what the manual pass adds.
void main() {
  late Directory directory;
  late File file;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('norte_restart_');
    file = File('${directory.path}/norte.sqlite');
  });

  tearDown(() => directory.deleteSync(recursive: true));

  NorteDatabase open() => NorteDatabase(NativeDatabase(file));

  final Task task = Task(
    id: 'survives-restart',
    title: 'Buy coffee',
    description: 'the good one',
    status: TaskStatus.inProgress,
    priority: Priority.urgent,
    dueDate: DateTime.utc(2026, 1, 5, 18, 30, 15, 123),
    jiraLink: const JiraLink(
      issueKey: 'PROJ-123',
      siteUrl: 'https://example.atlassian.net',
      lastKnownStatus: 'In Review',
    ),
    tags: const <String>['errands', 'urgent'],
    createdAt: DateTime.utc(2026, 1, 1, 9, 0, 0, 789),
    updatedAt: DateTime.utc(2026, 1, 1, 10, 15, 30, 42),
  );

  test(
    'S01-IT-01: a task written to the file database survives a reopen',
    () async {
      final NorteDatabase first = open();
      await DriftTaskRepository(first).save(task);
      await first.close();

      expect(file.existsSync(), isTrue, reason: 'the database is a real file');
      expect(file.lengthSync(), greaterThan(0));

      // A fresh instance over the same file — what a relaunch does.
      final NorteDatabase second = open();
      final List<Task> read = await DriftTaskRepository(second).listAll();
      await second.close();

      expect(read, <Task>[task]);
    },
  );

  test('S01-IT-03: a deletion survives a reopen too', () async {
    final NorteDatabase first = open();
    await DriftTaskRepository(first).save(task);
    await DriftTaskRepository(first).delete(task.id);
    await first.close();

    final NorteDatabase second = open();
    final List<Task> read = await DriftTaskRepository(second).listAll();
    await second.close();

    expect(read, isEmpty, reason: 'the row is gone from disk, not just memory');
  });
}
