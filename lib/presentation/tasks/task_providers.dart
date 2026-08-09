import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/usecases/comment_task.dart';
import '../../application/usecases/create_task.dart';
import '../../application/usecases/delete_task.dart';
import '../../application/usecases/list_tasks.dart';
import '../../application/usecases/update_task.dart';
import '../../domain/entities/task.dart';
import '../../domain/ports/clock.dart';
import '../../domain/ports/id_generator.dart';
import '../../domain/ports/task_repository.dart';

/// The [TaskRepository] the screens use.
///
/// Deliberately unimplemented here: `presentation/` must never reach into
/// `infrastructure/` (`docs/project-rules.md` §3, gate G5). The composition
/// root — `main.dart`, or a `ProviderScope` override in a test — supplies the
/// Drift adapter.
final Provider<TaskRepository> taskRepositoryProvider =
    Provider<TaskRepository>(
      (Ref ref) => throw UnimplementedError(
        'taskRepositoryProvider must be overridden in the composition root',
      ),
    );

/// Wall-clock time. Overridden by tests that need a pinned instant.
final Provider<Clock> clockProvider = Provider<Clock>(
  (Ref ref) => const SystemClock(),
);

/// Source of task identifiers.
final Provider<IdGenerator> idGeneratorProvider = Provider<IdGenerator>(
  (Ref ref) => UuidV4Generator(),
);

/// The task use cases, each assembled from the ports above.
final Provider<CreateTask> createTaskProvider = Provider<CreateTask>(
  (Ref ref) => CreateTask(
    repository: ref.watch(taskRepositoryProvider),
    clock: ref.watch(clockProvider),
    idGenerator: ref.watch(idGeneratorProvider),
  ),
);

final Provider<UpdateTask> updateTaskProvider = Provider<UpdateTask>(
  (Ref ref) => UpdateTask(
    repository: ref.watch(taskRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

final Provider<DeleteTask> deleteTaskProvider = Provider<DeleteTask>(
  (Ref ref) => DeleteTask(repository: ref.watch(taskRepositoryProvider)),
);

final Provider<CommentTask> commentTaskProvider = Provider<CommentTask>(
  (Ref ref) => CommentTask(
    repository: ref.watch(taskRepositoryProvider),
    clock: ref.watch(clockProvider),
    idGenerator: ref.watch(idGeneratorProvider),
  ),
);

final Provider<ListTasks> listTasksProvider = Provider<ListTasks>(
  (Ref ref) => ListTasks(repository: ref.watch(taskRepositoryProvider)),
);

/// The filter, search and ordering the user has chosen on the tasks screen.
class TaskQueryNotifier extends Notifier<TaskQuery> {
  @override
  TaskQuery build() => const TaskQuery();

  /// Adds [status] to the filter, or removes it when it is already there.
  ///
  /// Multi-select: two active chips show the **union** of both statuses, which
  /// is what "to do or blocked" means to the person reading the list. Removing
  /// the last one leaves the set empty, which is the same as "All".
  void toggleStatus(TaskStatus status) {
    final Set<TaskStatus> next = <TaskStatus>{...state.statuses};
    if (!next.remove(status)) next.add(status);
    state = state.copyWith(statuses: Set<TaskStatus>.unmodifiable(next));
  }

  /// Clears the status filter — the "All" chip.
  void clearStatuses() {
    state = state.copyWith(statuses: const <TaskStatus>{});
  }

  /// Narrows by free text over the title and description. Blank clears it.
  void search(String term) {
    state = term.trim().isEmpty
        ? state.copyWith(clearSearch: true)
        : state.copyWith(search: term);
  }

  /// Changes the ordering, keeping the filter and the search.
  void sortBy(TaskSort sort) {
    state = state.copyWith(sort: sort);
  }
}

final NotifierProvider<TaskQueryNotifier, TaskQuery> taskQueryProvider =
    NotifierProvider<TaskQueryNotifier, TaskQuery>(TaskQueryNotifier.new);

/// The task list the screen renders.
///
/// A [StreamProvider] over `ListTasks`, which reads Drift's `watch` — the UI
/// re-renders when the data changes and never polls (`sprint-01` validation
/// rules). It also gives the screen its loading and error states for free.
final StreamProvider<List<Task>> taskListProvider = StreamProvider<List<Task>>((
  Ref ref,
) {
  final ListTasks listTasks = ref.watch(listTasksProvider);
  return listTasks(ref.watch(taskQueryProvider));
});
