import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:norte/application/usecases/update_task.dart';
import 'package:norte/domain/entities/jira_link.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/failures/result.dart';
import 'package:norte/domain/ports/task_repository.dart';

import '../fakes/fakes.dart';

class _MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  /// T0 — when the task was created.
  final DateTime t0 = DateTime.utc(2026, 1, 1, 9);

  /// T1 — the clock when the update runs, strictly after T0.
  final DateTime t1 = DateTime.utc(2026, 1, 1, 14, 30);

  late _MockTaskRepository repository;
  late FakeClock clock;
  late UpdateTask updateTask;
  late Task existing;

  setUpAll(() {
    registerFallbackValue(
      Task(id: 'fallback', title: 'fallback', createdAt: t0, updatedAt: t0),
    );
  });

  setUp(() {
    existing = Task(
      id: 'task-1',
      title: 'Review PR',
      description: 'the connector one',
      priority: Priority.high,
      dueDate: DateTime.utc(2026, 1, 5, 18),
      jiraLink: const JiraLink(
        issueKey: 'PROJ-123',
        siteUrl: 'https://example.atlassian.net',
      ),
      tags: const <String>['api', 'urgent'],
      createdAt: t0,
      updatedAt: t0,
    );

    repository = _MockTaskRepository();
    clock = FakeClock(t1);
    updateTask = UpdateTask(repository: repository, clock: clock);

    when(() => repository.findById('task-1')).thenAnswer((_) async => existing);
    when(() => repository.save(any())).thenAnswer((_) async {});
  });

  test(
    'S01-UT-03: an update refreshes updatedAt and preserves everything else',
    () async {
      final Result<Task> result = await updateTask(
        id: 'task-1',
        status: TaskStatus.inProgress,
      );

      final Task updated = (result as Ok<Task>).value;

      expect(updated.status, TaskStatus.inProgress, reason: 'the change lands');
      expect(updated.createdAt, t0, reason: 'creation is never rewritten');
      expect(updated.updatedAt, t1, reason: 'updatedAt comes from the clock');

      // Every untouched field survives.
      expect(updated.id, existing.id);
      expect(updated.title, existing.title);
      expect(updated.description, existing.description);
      expect(updated.priority, existing.priority);
      expect(updated.dueDate, existing.dueDate);
      expect(updated.jiraLink, existing.jiraLink);
      expect(updated.tags, existing.tags);

      // Immutability: the original instance was not mutated in place.
      expect(existing.status, TaskStatus.todo);
      expect(existing.updatedAt, t0);

      final List<Task> saved = verify(
        () => repository.save(captureAny()),
      ).captured.cast<Task>();
      expect(saved, <Task>[updated]);
    },
  );

  test(
    'S01-UT-03: a blank title is rejected before the task is read',
    () async {
      final Result<Task> result = await updateTask(id: 'task-1', title: '   ');

      expect((result as Err<Task>).failure, isA<ValidationFailure>());
      verifyNever(() => repository.findById(any()));
      verifyNever(() => repository.save(any()));
    },
  );

  test('S01-UT-03: updating an unknown id returns NotFoundFailure', () async {
    when(() => repository.findById('ghost')).thenAnswer((_) async => null);

    final Result<Task> result = await updateTask(
      id: 'ghost',
      status: TaskStatus.done,
    );

    expect((result as Err<Task>).failure, isA<NotFoundFailure>());
    verifyNever(() => repository.save(any()));
  });

  test(
    'S01-UT-03: an omitted optional field is kept, a Patch(null) clears it',
    () async {
      final Task kept = ((await updateTask(id: 'task-1')) as Ok<Task>).value;
      expect(kept.dueDate, existing.dueDate);
      expect(kept.jiraLink, existing.jiraLink);
      expect(kept.description, existing.description);

      final Task cleared =
          ((await updateTask(
                    id: 'task-1',
                    dueDate: const Patch<DateTime?>(null),
                    jiraLink: const Patch<JiraLink?>(null),
                    description: const Patch<String?>(null),
                  ))
                  as Ok<Task>)
              .value;

      // BR-01 — a Jira link is removable at any time.
      expect(cleared.dueDate, isNull);
      expect(cleared.jiraLink, isNull);
      expect(cleared.description, isNull);
    },
  );
}
