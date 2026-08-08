import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:norte/application/usecases/create_task.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/failures/result.dart';
import 'package:norte/domain/ports/task_repository.dart';

import '../fakes/fakes.dart';

class _MockTaskRepository extends Mock implements TaskRepository {}

/// Canonical UUID v4: 8-4-4-4-12 lowercase hex, version nibble `4`, variant
/// nibble in `8..b`.
final RegExp _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  late _MockTaskRepository repository;
  late FakeClock clock;
  late FakeIdGenerator idGenerator;
  late CreateTask createTask;

  setUpAll(() {
    registerFallbackValue(
      Task(
        id: 'fallback',
        title: 'fallback',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
  });

  setUp(() {
    repository = _MockTaskRepository();
    clock = FakeClock.fixed();
    idGenerator = FakeIdGenerator();
    createTask = CreateTask(
      repository: repository,
      clock: clock,
      idGenerator: idGenerator,
    );
    when(() => repository.save(any())).thenAnswer((_) async {});
  });

  test(
    'S01-UT-01: a created task is local-only and carries the pinned clock',
    () async {
      final Result<Task> result = await createTask(title: 'Review PR');

      final Task task = (result as Ok<Task>).value;

      // BR-01 — the task is born independent of Jira.
      expect(task.jiraLink, isNull);
      expect(task.title, 'Review PR');
      expect(
        task.status,
        TaskStatus.todo,
        reason: 'todo is the default status',
      );
      expect(task.priority, Priority.medium);
      expect(task.tags, isEmpty);
      expect(task.dueDate, isNull);

      // Timestamps come from the injected clock, never from DateTime.now().
      expect(task.createdAt, clock.now());
      expect(task.updatedAt, clock.now());
      expect(task.createdAt, task.updatedAt);

      // The id is a UUID v4 produced in the use case.
      expect(task.id, matches(_uuidV4));
      expect(idGenerator.issued, <String>[task.id]);

      // It was persisted exactly once, as the returned instance.
      final List<Task> saved = verify(
        () => repository.save(captureAny()),
      ).captured.cast<Task>();
      expect(saved, <Task>[task]);
    },
  );

  test(
    'S01-UT-02: a blank title is rejected without touching the repository',
    () async {
      for (final String blank in <String>['', '   ', '\t\n ']) {
        final Result<Task> result = await createTask(title: blank);

        expect(
          result,
          isA<Err<Task>>(),
          reason: 'a blank title must not produce a task',
        );
        expect(
          (result as Err<Task>).failure,
          isA<ValidationFailure>(),
          reason: 'input validation belongs to the use case',
        );
        expect((result.failure as ValidationFailure).field, 'title');
      }

      verifyNever(() => repository.save(any()));
      expect(
        idGenerator.issued,
        isEmpty,
        reason: 'no id is burned on rejection',
      );
    },
  );

  test('S01-UT-02: a title is trimmed before it is stored', () async {
    final Result<Task> result = await createTask(title: '  Review PR  ');

    expect((result as Ok<Task>).value.title, 'Review PR');
  });

  test(
    'S01-UT-01: blank and duplicate tags are dropped, order is kept',
    () async {
      final Result<Task> result = await createTask(
        title: 'Review PR',
        tags: <String>['api', ' ', 'urgent', 'api', '  jira  '],
      );

      expect((result as Ok<Task>).value.tags, <String>[
        'api',
        'urgent',
        'jira',
      ]);
    },
  );
}
