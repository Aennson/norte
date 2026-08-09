import 'package:drift/drift.dart' show QueryRow;
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/domain/entities/task_comment.dart';
import 'package:norte/infrastructure/persistence/drift_task_repository.dart';
import 'package:norte/infrastructure/persistence/norte_database.dart';
import 'package:norte/infrastructure/persistence/norte_database_factory.dart';

/// S05a-IT-01 — task comments against a real in-memory database at schema 5.
void main() {
  late NorteDatabase database;
  late DriftTaskRepository repository;

  final DateTime t0 = DateTime.utc(2026, 8, 9, 10, 0, 0, 111);

  /// Three comments with **distinct** timestamps and a deliberately
  /// non-chronological one in the middle.
  ///
  /// The middle comment is stamped *earlier* than the first: insertion order
  /// and timestamp order disagree, so a reader that sorted by `createdAtMs`
  /// would come back in the wrong order and this test would say so. Under a
  /// pinned clock — which is how `CommentTask` is exercised everywhere else —
  /// all three would be identical and the bug would be invisible.
  final List<TaskComment> comments = <TaskComment>[
    TaskComment(id: 'c1', body: 'cliente retornou', createdAt: t0),
    TaskComment(
      id: 'c2',
      body: 'orçamento confirmado',
      createdAt: t0.subtract(const Duration(minutes: 5)),
    ),
    TaskComment(
      id: 'c3',
      body: 'aguardando assinatura',
      createdAt: t0.add(const Duration(hours: 2, milliseconds: 42)),
    ),
  ];

  Task task(String id, String title, List<TaskComment> notes) =>
      Task(id: id, title: title, comments: notes, createdAt: t0, updatedAt: t0);

  setUp(() {
    database = openInMemoryNorteDatabase();
    repository = DriftTaskRepository(database);
  });

  tearDown(() => database.close());

  test('S05a-IT-01: comments return in insertion order with their '
      'timestamps', () async {
    await repository.save(task('t1', 'Ligar para Samara', comments));

    final Task read = (await repository.findById('t1'))!;

    expect(read.comments, comments);
    expect(
      read.comments.map((TaskComment c) => c.id),
      <String>['c1', 'c2', 'c3'],
      reason: 'insertion order, not chronological order',
    );
    // Millisecond precision, as everywhere else in this schema.
    expect(read.comments[2].createdAt, comments[2].createdAt);
    expect(read.comments[2].createdAt.isUtc, isTrue);
  });

  test('S05a-IT-01: a task with no comments reads back with an empty list, '
      'not a null', () async {
    await repository.save(task('t1', 'Revisar PR', const <TaskComment>[]));

    expect((await repository.findById('t1'))!.comments, isEmpty);
  });

  test('S05a-IT-01: saving replaces the stored comments rather than '
      'appending to them', () async {
    await repository.save(task('t1', 'Ligar para Samara', comments));
    await repository.save(
      task('t1', 'Ligar para Samara', <TaskComment>[comments.first]),
    );

    // Not four rows, and not three: the entity carries the whole list, so a
    // caller that removed two meant it.
    expect((await repository.findById('t1'))!.comments, <TaskComment>[
      comments.first,
    ]);
  });

  test('S05a-IT-01: deleting the task removes its comments and nothing '
      'else', () async {
    await repository.save(task('t1', 'Ligar para Samara', comments));
    await repository.save(
      task('t2', 'Revisar PR', <TaskComment>[
        TaskComment(id: 'c9', body: 'segunda passada', createdAt: t0),
      ]),
    );

    await repository.delete('t1');

    expect(await repository.findById('t1'), isNull);
    final Task survivor = (await repository.findById('t2'))!;
    expect(survivor.comments.single.id, 'c9');

    // The orphan check the entity API cannot make: a `delete` that dropped the
    // task row and left the comment rows behind would pass every assertion
    // above, and the next task to be given the same id would inherit them.
    final int orphans = await database
        .customSelect('SELECT COUNT(*) AS n FROM task_comments')
        .map((QueryRow row) => row.read<int>('n'))
        .getSingle();
    expect(orphans, 1, reason: 'only t2 comment remains');
  });

  test('S05a-IT-01: listAll and watchAll carry the comments too', () async {
    await repository.save(task('t1', 'Ligar para Samara', comments));
    await repository.save(task('t2', 'Revisar PR', const <TaskComment>[]));

    final List<Task> listed = await repository.listAll();
    expect(listed.firstWhere((Task t) => t.id == 't1').comments, hasLength(3));
    expect(listed.firstWhere((Task t) => t.id == 't2').comments, isEmpty);

    final List<Task> watched = await repository.watchAll().first;
    expect(watched.firstWhere((Task t) => t.id == 't1').comments, comments);
  });
}
