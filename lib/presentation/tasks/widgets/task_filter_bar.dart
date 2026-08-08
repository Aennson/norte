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
class TaskFilterBar extends StatelessWidget {
  const TaskFilterBar({
    required this.query,
    required this.onStatusSelected,
    required this.onSortSelected,
    super.key,
  });

  final TaskQuery query;

  /// `null` clears the status filter.
  final ValueChanged<TaskStatus?> onStatusSelected;

  final ValueChanged<TaskSort> onSortSelected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);
    final TaskStatus? selected = query.statuses.isEmpty
        ? null
        : query.statuses.first;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          NorteChip(
            key: const Key('filter-all'),
            label: l10n.tasksFilterAll,
            isSelected: selected == null,
            onSelected: () => onStatusSelected(null),
          ),
          for (final TaskStatus status in TaskStatus.values) ...<Widget>[
            const SizedBox(width: NorteSpacing.sm),
            NorteChip(
              key: Key('filter-${status.name}'),
              label: status.label(l10n),
              isSelected: selected == status,
              dotColor: status.dotColor(colors),
              onSelected: () => onStatusSelected(status),
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
