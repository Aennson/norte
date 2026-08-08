import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// The four task use cases, each assembled from the ports above.
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

final Provider<ListTasks> listTasksProvider = Provider<ListTasks>(
  (Ref ref) => ListTasks(repository: ref.watch(taskRepositoryProvider)),
);

/// The filter and ordering the user has chosen on the tasks screen.
class TaskQueryNotifier extends Notifier<TaskQuery> {
  @override
  TaskQuery build() => const TaskQuery();

  /// Narrows the list to [status], or clears the filter when [status] is
  /// `null` (the "All" chip).
  void filterByStatus(TaskStatus? status) {
    state = TaskQuery(
      statuses: status == null ? const <TaskStatus>{} : <TaskStatus>{status},
      tag: state.tag,
      sort: state.sort,
    );
  }

  /// Changes the ordering, keeping the filter.
  void sortBy(TaskSort sort) {
    state = TaskQuery(statuses: state.statuses, tag: state.tag, sort: sort);
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
