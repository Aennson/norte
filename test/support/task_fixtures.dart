import 'dart:async';

import 'package:norte/domain/entities/jira_link.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/task_repository.dart';

/// In-memory [TaskRepository] for widget and golden tests
/// (`docs/testing-strategy.md` §3).
///
/// Deterministic and synchronous: no timers, no database, no randomness. The
/// three constructors give a screen each of its non-content states.
class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository([List<Task> initial = const <Task>[]])
    : _tasks = List<Task>.of(initial),
      _mode = _Mode.data;

  /// Every read fails — drives the error state.
  FakeTaskRepository.failing() : _tasks = <Task>[], _mode = _Mode.failing;

  /// Never emits — drives the loading state.
  FakeTaskRepository.pending() : _tasks = <Task>[], _mode = _Mode.pending;

  final List<Task> _tasks;
  final _Mode _mode;

  final StreamController<List<Task>> _controller =
      StreamController<List<Task>>.broadcast();

  /// Every mutation the widget under test performed, in order.
  final List<String> savedIds = <String>[];
  final List<String> deletedIds = <String>[];

  /// Mirrors the real adapter: the current state arrives on subscription, then
  /// one emission per mutation.
  @override
  Stream<List<Task>> watchAll() async* {
    switch (_mode) {
      case _Mode.pending:
        // Never completes — the screen stays in its loading state.
        await Completer<void>().future;
      case _Mode.failing:
        throw const StorageFailure('fake repository failure');
      case _Mode.data:
        yield List<Task>.unmodifiable(_tasks);
        yield* _controller.stream;
    }
  }

  @override
  Future<List<Task>> listAll() async => List<Task>.unmodifiable(_tasks);

  @override
  Future<Task?> findById(String id) async {
    for (final Task task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  @override
  Future<void> save(Task task) async {
    savedIds.add(task.id);
    final int index = _tasks.indexWhere((Task stored) => stored.id == task.id);
    if (index == -1) {
      _tasks.add(task);
    } else {
      _tasks[index] = task;
    }
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    deletedIds.add(id);
    _tasks.removeWhere((Task task) => task.id == id);
    _emit();
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(List<Task>.unmodifiable(_tasks));
  }
}

enum _Mode { data, failing, pending }

/// Fixed instant shared by the fixtures, so a golden never moves with the
/// calendar.
final DateTime _t0 = DateTime.utc(2026, 1, 1, 9);

/// The three tasks the content golden renders: one linked to Jira, one plain
/// and dated, one already done.
final List<Task> goldenTasks = <Task>[
  Task(
    id: 'task-linked',
    title: 'Review the connector PR',
    description: 'Second pass on the retry logic.',
    status: TaskStatus.inProgress,
    priority: Priority.urgent,
    dueDate: DateTime.utc(2026, 1, 5, 18),
    jiraLink: JiraLink(
      issueKey: 'PROJ-123',
      siteUrl: 'https://example.atlassian.net',
      lastKnownStatus: 'In Review',
      lastSyncedAt: _t0,
    ),
    tags: const <String>['api', 'urgent'],
    createdAt: _t0,
    updatedAt: _t0,
  ),
  Task(
    id: 'task-plain',
    title: 'Write the sprint report',
    status: TaskStatus.todo,
    priority: Priority.high,
    dueDate: DateTime.utc(2026, 1, 8, 12),
    tags: const <String>['docs'],
    createdAt: _t0,
    updatedAt: _t0,
  ),
  Task(
    id: 'task-done',
    title: 'Buy coffee',
    status: TaskStatus.done,
    priority: Priority.low,
    createdAt: _t0,
    updatedAt: _t0,
  ),
];
