import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../application/usecases/list_tasks.dart';
import '../../application/usecases/update_task.dart';
import '../../domain/entities/task.dart';
import '../../l10n/generated/app_localizations.dart';
import '../shared/theme/norte_spacing.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/error_state.dart';
import '../shared/widgets/loading_skeleton.dart';
import '../shared/widgets/norte_button.dart';
import '../shared/widgets/norte_screen.dart';
import 'task_providers.dart';
import 'widgets/delete_task_dialog.dart';
import 'widgets/task_card.dart';
import 'widgets/task_editor_sheet.dart';
import 'widgets/task_filter_bar.dart';

/// Tasks destination — the full local CRUD (`sprint-01`).
///
/// The list comes from a [StreamProvider] over Drift's `watch`, so every
/// mutation redraws the screen without a refresh call, and the provider's
/// `AsyncValue` supplies three of the four mandatory states directly
/// (`docs/design-system.md` §6). The fourth, empty, is a content state with no
/// rows.
class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  /// Route path of this destination.
  static const String routePath = '/tasks';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<Task>> tasks = ref.watch(taskListProvider);
    final TaskQuery query = ref.watch(taskQueryProvider);

    return NorteScreen(
      title: l10n.navTasks,
      action: NorteButton(
        key: const Key('new-task-button'),
        label: l10n.tasksNewTask,
        icon: LucideIcons.plus,
        onPressed: () => _createTask(context, ref),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TaskFilterBar(
            query: query,
            onStatusSelected: (TaskStatus? status) =>
                ref.read(taskQueryProvider.notifier).filterByStatus(status),
            onSortSelected: (TaskSort sort) =>
                ref.read(taskQueryProvider.notifier).sortBy(sort),
          ),
          const SizedBox(height: NorteSpacing.lg),
          Expanded(
            child: tasks.when(
              loading: () =>
                  LoadingSkeletonList(semanticLabel: l10n.tasksLoadingLabel),
              error: (Object error, StackTrace stackTrace) => ErrorState(
                message: l10n.tasksErrorMessage,
                retryLabel: l10n.actionRetry,
                onRetry: () => ref.invalidate(taskListProvider),
              ),
              data: (List<Task> data) => data.isEmpty
                  ? EmptyState(
                      icon: LucideIcons.listChecks,
                      // An empty database and a filter that matched nothing
                      // are different situations and read differently.
                      message: query.isUnfiltered
                          ? l10n.tasksEmptyMessage
                          : l10n.tasksFilteredEmptyMessage,
                      actionLabel: query.isUnfiltered
                          ? l10n.tasksNewTask
                          : null,
                      onAction: query.isUnfiltered
                          ? () => _createTask(context, ref)
                          : null,
                    )
                  : _TaskList(tasks: data),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskList extends ConsumerWidget {
  const _TaskList({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: NorteSpacing.md),
      itemBuilder: (BuildContext context, int index) {
        final Task task = tasks[index];
        return TaskCard(
          key: Key('task-card-${task.id}'),
          task: task,
          onTap: () => _editTask(context, ref, task),
          onToggleDone: () => _toggleDone(ref, task),
          onDelete: () => _deleteTask(context, ref, task),
        );
      },
    );
  }
}

/// Opens the editor and creates the task the user described.
Future<void> _createTask(BuildContext context, WidgetRef ref) async {
  final TaskDraft? draft = await TaskEditorSheet.show(context);
  if (draft == null) return;

  await ref.read(createTaskProvider)(
    title: draft.title,
    description: draft.description,
    status: draft.status,
    priority: draft.priority,
    dueDate: draft.dueDate,
    tags: draft.tags,
  );
}

/// Opens the editor pre-filled with [task] and applies the changes.
Future<void> _editTask(BuildContext context, WidgetRef ref, Task task) async {
  final TaskDraft? draft = await TaskEditorSheet.show(context, initial: task);
  if (draft == null) return;

  await ref.read(updateTaskProvider)(
    id: task.id,
    title: draft.title,
    description: Patch<String?>(draft.description),
    status: draft.status,
    priority: draft.priority,
    dueDate: Patch<DateTime?>(draft.dueDate),
    tags: draft.tags,
  );
}

/// Flips the task between `done` and `todo`.
Future<void> _toggleDone(WidgetRef ref, Task task) async {
  await ref.read(updateTaskProvider)(
    id: task.id,
    status: task.status.isTerminal ? TaskStatus.todo : TaskStatus.done,
  );
}

/// Asks first — deleting is irreversible (`sprint-01` validation rules).
Future<void> _deleteTask(BuildContext context, WidgetRef ref, Task task) async {
  final bool confirmed = await DeleteTaskDialog.show(
    context,
    taskTitle: task.title,
  );
  if (!confirmed) return;

  await ref.read(deleteTaskProvider)(task.id);
}
