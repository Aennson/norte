import 'package:flutter_test/flutter_test.dart';
import 'package:norte/application/usecases/comment_task.dart';
import 'package:norte/domain/entities/jira_link.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/domain/entities/task_comment.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/failures/result.dart';

import '../fakes/fakes.dart';
import '../support/task_fixtures.dart';

/// S05a-UT-06 — `CommentTask` on its own (BR-01, `docs/architecture.md` §3.2).
void main() {
  final DateTime created = DateTime.utc(2026, 8, 9, 9);
  final DateTime now = DateTime.utc(2026, 8, 9, 10);

  late FakeTaskRepository repository;
  late CommentTask commentTask;

  final Task linked = Task(
    id: 't1',
    title: 'Ligar para Samara',
    jiraLink: const JiraLink(
      issueKey: 'PROJ-123',
      siteUrl: 'https://example.atlassian.net',
    ),
    createdAt: created,
    updatedAt: created,
  );

  setUp(() {
    repository = FakeTaskRepository();
    commentTask = CommentTask(
      repository: repository,
      clock: FakeClock(now),
      idGenerator: FakeIdGenerator(),
    );
  });

  tearDown(() => repository.dispose());

  test(
    'S05a-UT-06: the comment is stored trimmed, stamped and appended',
    () async {
      await repository.save(linked);

      final Result<Task> result = await commentTask(
        id: 't1',
        body: '  cliente retornou  ',
      );

      final Task task = result.valueOrNull!;
      expect(task.comments.single.body, 'cliente retornou');
      expect(task.comments.single.createdAt, now);
      expect(task.comments.single.id, isNotEmpty);
      // A note is a change to the task; a list sorted by recency that ignored
      // comments would hide the row the user just touched.
      expect(task.updatedAt, now);
      expect(task.createdAt, created, reason: 'never rewritten');
    },
  );

  test(
    'S05a-UT-06: the linked issue is untouched — the note is local',
    () async {
      await repository.save(linked);

      final Task task = (await commentTask(
        id: 't1',
        body: 'nota',
      )).valueOrNull!;

      // The use case has no gateway and no outbox to reach for, which is the
      // point; this asserts it also leaves the link itself alone.
      expect(task.jiraLink, linked.jiraLink);
    },
  );

  test(
    'S05a-UT-06: a blank body is refused without touching storage',
    () async {
      await repository.save(linked);
      repository.saved.clear();
      repository.savedIds.clear();

      final Result<Task> result = await commentTask(id: 't1', body: '   ');

      expect(result, isA<Err<Task>>());
      expect((result as Err<Task>).failure, isA<ValidationFailure>());
      expect((result.failure as ValidationFailure).field, 'comment');
      expect(repository.savedIds, isEmpty);
    },
  );

  test(
    'S05a-UT-06: an unknown id is a NotFoundFailure, not a new task',
    () async {
      final Result<Task> result = await commentTask(id: 'nope', body: 'nota');

      expect((result as Err<Task>).failure, isA<NotFoundFailure>());
      expect(repository.savedIds, isEmpty);
    },
  );

  test('S05a-UT-06: existing comments survive a new one', () async {
    await repository.save(
      linked.copyWith(
        comments: <TaskComment>[
          TaskComment(id: 'c0', body: 'primeira', createdAt: created),
        ],
      ),
    );

    final Task task = (await commentTask(
      id: 't1',
      body: 'segunda',
    )).valueOrNull!;

    expect(task.comments.map((TaskComment c) => c.body), <String>[
      'primeira',
      'segunda',
    ]);
  });
}
