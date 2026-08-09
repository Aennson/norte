import 'package:flutter/material.dart';

import '../../../application/usecases/list_tasks.dart';
import '../../../domain/entities/task.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../shared/theme/norte_colors.dart';
import '../../shared/theme/norte_spacing.dart';
import '../../shared/widgets/norte_chip.dart';
import '../task_labels.dart';

/// Status filter and ordering control above the task list.
///
/// "All" plus one chip per [TaskStatus]; the ordering chips sit on the same
/// scrolling row on narrow viewports.
///
/// **The status chips are multi-select** (`sprint-05a`). Tapping a second one
/// adds it rather than replacing the first, so `{todo, blocked}` shows the
/// union — the list a developer wants when they are looking for what is not
/// moving. "All" is not a fifth status but the absence of the other four, and
/// it lights up exactly when none of them is active.
class TaskFilterBar extends StatelessWidget {
  const TaskFilterBar({
    required this.query,
    required this.onStatusToggled,
    required this.onAllSelected,
    required this.onSortSelected,
    super.key,
  });

  final TaskQuery query;

  /// Adds the status to the filter, or removes it when it is already active.
  final ValueChanged<TaskStatus> onStatusToggled;

  /// Clears the status filter — the "All" chip.
  final VoidCallback onAllSelected;

  final ValueChanged<TaskSort> onSortSelected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          NorteChip(
            key: const Key('filter-all'),
            label: l10n.tasksFilterAll,
            isSelected: query.statuses.isEmpty,
            onSelected: onAllSelected,
          ),
          for (final TaskStatus status in TaskStatus.values) ...<Widget>[
            const SizedBox(width: NorteSpacing.sm),
            NorteChip(
              key: Key('filter-${status.name}'),
              label: status.label(l10n),
              isSelected: query.statuses.contains(status),
              dotColor: status.dotColor(colors),
              onSelected: () => onStatusToggled(status),
            ),
          ],
          // Ordering chips sit after a wider gap — same row, different job.
          const SizedBox(width: NorteSpacing.lg),
          for (final TaskSort sort in TaskSort.values) ...<Widget>[
            const SizedBox(width: NorteSpacing.sm),
            NorteChip(
              key: Key('sort-${sort.name}'),
              label: sort.label(l10n),
              isSelected: query.sort == sort,
              onSelected: () => onSortSelected(sort),
            ),
          ],
        ],
      ),
    );
  }
}
