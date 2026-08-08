import '../../domain/entities/task.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/task_repository.dart';
import 'refresh_jira_status.dart';

/// Refreshes every task whose issue is worth asking about.
///
/// The selection is the point (`docs/architecture.md` §4.3): **linked, and
/// not done**. An unlinked task has nothing to ask about, and a completed one
/// has nothing left to learn — polling either would spend the site's rate
/// limit on answers nobody reads.
///
/// **BR-02 survives the automation.** Running unattended does not grant this
/// any authority a manual refresh lacks: it updates display caches and
/// collects the divergences it found, and every one of them waits for the
/// user. Nothing here writes a [Task.status].
///
/// Failures are per-task and never abort the pass: one unreachable issue must
/// not stop the other nine from refreshing.
class SyncLinkedTasks {
  const SyncLinkedTasks({required this.repository, required this.refresh});

  final TaskRepository repository;
  final RefreshJiraStatus refresh;

  /// Refreshes the eligible tasks and returns the ones Jira disagrees with.
  Future<List<JiraRefresh>> call() async {
    final List<Task> candidates = (await repository.listAll())
        .where((Task task) => task.jiraLink != null && !task.status.isTerminal)
        .toList();

    final List<JiraRefresh> divergences = <JiraRefresh>[];
    for (final Task task in candidates) {
      final Result<JiraRefresh> result = await refresh(task);
      switch (result) {
        case Ok<JiraRefresh>(:final JiraRefresh value):
          if (value.hasDivergence) divergences.add(value);
        case Err<JiraRefresh>():
          continue;
      }
    }
    return List<JiraRefresh>.unmodifiable(divergences);
  }
}
