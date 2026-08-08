import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../domain/entities/task.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../shared/theme/norte_colors.dart';
import '../../shared/theme/norte_spacing.dart';
import '../../shared/theme/norte_typography.dart';
import '../../shared/widgets/norte_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../task_labels.dart';

/// One task in the list.
///
/// Layout: status badge and priority on top, title next, then the metadata row
/// (due date and tags). Technical data — status, priority, dates, tags — is
/// drawn in the mono roles (`docs/design-system.md` §1.4).
///
/// The whole card opens the editor; the leading control toggles completion and
/// the trailing one deletes, both with their own accessible labels.
class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.task,
    required this.onTap,
    required this.onToggleDone,
    required this.onDelete,
    super.key,
  });

  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggleDone;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);
    final bool isDone = task.status.isTerminal;

    return NorteCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _CompletionToggle(
            isDone: isDone,
            label: isDone ? l10n.taskMarkNotDone : l10n.taskMarkDone,
            onPressed: onToggleDone,
          ),
          const SizedBox(width: NorteSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    StatusBadge(
                      status: task.status.badge,
                      label: task.status.label(l10n),
                    ),
                    const SizedBox(width: NorteSpacing.md),
                    Text(
                      task.priority.label(l10n).toUpperCase(),
                      style: NorteTypography.monoSmall.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: NorteSpacing.sm),
                Text(
                  task.title,
                  style: NorteTypography.title.copyWith(
                    color: isDone ? colors.textSecondary : colors.textPrimary,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    decorationColor: colors.textSecondary,
                  ),
                ),
                if (task.dueDate != null || task.tags.isNotEmpty) ...<Widget>[
                  const SizedBox(height: NorteSpacing.sm),
                  Wrap(
                    spacing: NorteSpacing.md,
                    runSpacing: NorteSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      if (task.dueDate != null)
                        Text(
                          l10n.taskDueLabel(
                            formatTaskDate(context, task.dueDate!),
                          ),
                          style: NorteTypography.mono.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      for (final String tag in task.tags)
                        Text(
                          '#$tag',
                          style: NorteTypography.mono.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: NorteSpacing.sm),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(LucideIcons.trash2, size: 18),
            color: colors.textMuted,
            tooltip: l10n.actionDelete,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// Square check control on the left of the card.
///
/// A completed task shows the `success` tick; an open one shows an empty
/// `border` square, so the state reads without relying on colour alone.
class _CompletionToggle extends StatelessWidget {
  const _CompletionToggle({
    required this.isDone,
    required this.label,
    required this.onPressed,
  });

  final bool isDone;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final NorteColors colors = NorteColors.of(context);

    return Semantics(
      checked: isDone,
      child: IconButton(
        onPressed: onPressed,
        tooltip: label,
        visualDensity: VisualDensity.compact,
        icon: Icon(
          isDone ? LucideIcons.squareCheck : LucideIcons.square,
          size: 20,
          color: isDone ? colors.success : colors.textMuted,
        ),
      ),
    );
  }
}
