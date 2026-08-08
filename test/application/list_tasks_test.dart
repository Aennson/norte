import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:norte/application/usecases/list_tasks.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/domain/ports/task_repository.dart';

class _MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  final DateTime t0 = DateTime.utc(2026, 1, 1, 9);

  Task task({
    required String id,
    required TaskStatus status,
    required Priority priority,
    DateTime? dueDate,
    List<String> tags = const <String>[],
  }) {
    return Task(
      id: id,
      title: id,
      status: status,
      priority: priority,
      dueDate: dueDate,
      tags: tags,
      createdAt: t0,
      updatedAt: t0,
    );
  }

  /// Five tasks of varied statuses, priorities and due dates.
  ///
  /// The three `todo` ones are the interesting set: `low-urgent` and
  /// `dated-urgent` tie on priority and must be separated by their due dates,
  /// with the undated one last.
  late List<Task> fixture;
  late _MockTaskRepository repository;
  late ListTasks listTasks;

  setUp(() {
    fixture = <Task>[
      task(
        id: 'undated-urgent',
        status: TaskStatus.todo,
        priority: Priority.urgent,
        tags: <String>['api'],
      ),
      task(
        id: 'done-urgent',
        status: TaskStatus.done,
        priority: Priority.urgent,
        dueDate: DateTime.utc(2026, 1, 2),
      ),
      task(
        id: 'dated-urgent',
        status: TaskStatus.todo,
        priority: Priority.urgent,
        dueDate: DateTime.utc(2026, 1, 10),
        tags: <String>['api', 'jira'],
      ),
      task(
        id: 'todo-low',
        status: TaskStatus.todo,
        priority: Priority.low,
        dueDate: DateTime.utc(2026, 1, 3),
      ),
      task(
        id: 'blocked-high',
        status: TaskStatus.blocked,
        priority: Priority.high,
      ),
    ];

    repository = _MockTaskRepository();
    listTasks = ListTasks(repository: repository);
    when(
      () => repository.watchAll(),
    ).thenAnswer((_) => Stream<List<Task>>.value(fixture));
  });

  List<String> idsOf(List<Task> tasks) =>
      tasks.map((Task task) => task.id).toList();

  test('S01-UT-04: filtering by status and sorting by priority', () async {
    final List<Task> listed = await listTasks(
      const TaskQuery(
        statuses: <TaskStatus>{TaskStatus.todo},
        sort: TaskSort.priority,
      ),
    ).first;

    // Only todo tasks survive the filter.
    expect(
      listed.every((Task task) => task.status == TaskStatus.todo),
      isTrue,
      reason: 'the status filter drops every other status',
    );

    // Priority descending; the urgent tie breaks on dueDate ascending with the
    // undated task last; the low-priority task comes after both.
    expect(idsOf(listed), <String>[
      'dated-urgent',
      'undated-urgent',
      'todo-low',
    ]);
  });

  test('S01-UT-04: an unfiltered query keeps every task', () async {
    final List<Task> listed = await listTasks().first;

    expect(listed, hasLength(fixture.length));
    expect(idsOf(listed), <String>[
      'done-urgent', // urgent, due Jan 2
      'dated-urgent', // urgent, due Jan 10
      'undated-urgent', // urgent, undated -> last of the urgent group
      'blocked-high',
      'todo-low',
    ]);
  });

  test('S01-UT-04: sorting by due date puts undated tasks last', () async {
    final List<Task> listed = await listTasks(
      const TaskQuery(sort: TaskSort.dueDate),
    ).first;

    expect(idsOf(listed), <String>[
      'done-urgent', // Jan 2
      'todo-low', // Jan 3
      'dated-urgent', // Jan 10
      'undated-urgent', // undated, urgent
      'blocked-high', // undated, high
    ]);
  });

  test(
    'S01-UT-04: filtering by tag keeps only the tasks carrying it',
    () async {
      final List<Task> listed = await listTasks(
        const TaskQuery(tag: 'jira'),
      ).first;

      expect(idsOf(listed), <String>['dated-urgent']);
    },
  );

  test(
    'S01-UT-04: the listing is reactive — it re-emits on every repository emission',
    () async {
      when(() => repository.watchAll()).thenAnswer(
        (_) => Stream<List<Task>>.fromIterable(<List<Task>>[<Task>[], fixture]),
      );

      final List<List<String>> emissions = await listTasks(
        const TaskQuery(statuses: <TaskStatus>{TaskStatus.todo}),
      ).map(idsOf).toList();

      expect(emissions, <List<String>>[
        <String>[],
        <String>['dated-urgent', 'undated-urgent', 'todo-low'],
      ]);
    },
  );

  test(
    'S01-UT-04: a query that narrows nothing reports itself as unfiltered',
    () {
      expect(const TaskQuery().isUnfiltered, isTrue);
      expect(
        const TaskQuery(statuses: <TaskStatus>{TaskStatus.done}).isUnfiltered,
        isFalse,
      );
      expect(const TaskQuery(tag: 'api').isUnfiltered, isFalse);
    },
  );
}
