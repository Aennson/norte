import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../domain/entities/jira_link.dart';
import '../../../domain/entities/jira_status_mapping.dart';
import '../../../domain/entities/task.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../jira/widgets/divergence_banner.dart';
import '../../jira/widgets/jira_chip.dart';
import '../../shared/theme/norte_colors.dart';
import '../../shared/theme/norte_spacing.dart';
import '../../shared/theme/norte_typography.dart';
import '../../shared/widgets/norte_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../task_labels.dart';

/// One task in the list.
///
/// Layout: status badge and priority on top, title next, then the metadata row
/// (due date, tags and the Jira chip). Technical data — status, priority,
/// dates, tags, issue keys — is drawn in the mono roles
/// (`docs/design-system.md` §1.4).
///
/// The whole card opens the editor; the leading control toggles completion and
/// the trailing one deletes, both with their own accessible labels.
///
/// **A linked task can also carry a divergence.** The card derives it from
/// what is stored — the local status against the cached Jira one — so the
/// banner is there the moment the app opens, without waiting for a refresh,
/// and stays until the user decides (BR-02).
class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.task,
    required this.onTap,
    required this.onToggleDone,
    required this.onDelete,
    super.key,
    this.onJiraMenu,
    this.onKeepLocal,
    this.onAdoptRemote,
  });

  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggleDone;
  final VoidCallback onDelete;

  /// Opens the Jira actions for this task. `null` hides the control — which
  /// is what the golden and widget tests use to render the card on its own.
  final VoidCallback? onJiraMenu;

  /// Divergence decision: keep the local status and tell Jira.
  final VoidCallback? onKeepLocal;

  /// Divergence decision: take Jira's status locally.
  final VoidCallback? onAdoptRemote;

  /// Whether the stored link disagrees with the local status (BR-02).
  ///
  /// Derived, never stored: a divergence is a relation between two values the
  /// database already holds, and giving it a column of its own would let the
  /// two drift apart.
  bool get hasDivergence {
    final String? remote = task.jiraLink?.lastKnownStatus;
    return remote != null && JiraStatusMapping.diverges(task.status, remote);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);
    final bool isDone = task.status.isTerminal;
    final JiraLink? link = task.jiraLink;

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
                // The description, when there is one. Added in Sprint 05a
                // because the search now reads it (§4.1): a list that can be
                // filtered by a word the user cannot see is a list that
                // answers questions it will not show its working for. Two
                // lines, `textSecondary`, so the title still leads.
                if (task.description case final String description
                    when description.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: NorteSpacing.xs),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: NorteTypography.body.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
                if (task.dueDate != null ||
                    task.tags.isNotEmpty ||
                    link != null) ...<Widget>[
                  const SizedBox(height: NorteSpacing.sm),
                  Wrap(
                    spacing: NorteSpacing.md,
                    runSpacing: NorteSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      if (link != null)
                        JiraChip(
                          link: link,
                          semanticsLabel: link.lastSyncedAt == null
                              ? '${link.issueKey} · ${l10n.jiraNeverSyncedLabel}'
                              : '${link.issueKey} · '
                                    '${l10n.jiraLastSyncedLabel(formatTaskDate(context, link.lastSyncedAt!))}',
                        ),
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
                if (hasDivergence &&
                    onKeepLocal != null &&
                    onAdoptRemote != null) ...<Widget>[
                  const SizedBox(height: NorteSpacing.md),
                  DivergenceBanner(
                    issueKey: link!.issueKey,
                    localStatus: task.status.label(l10n),
                    remoteStatus: link.lastKnownStatus!,
                    onKeepLocal: onKeepLocal!,
                    onAdoptRemote: onAdoptRemote!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: NorteSpacing.sm),
          if (onJiraMenu != null)
            IconButton(
              key: Key('task-jira-menu-${task.id}'),
              onPressed: onJiraMenu,
              icon: const Icon(LucideIcons.link, size: 18),
              color: link == null ? colors.textMuted : colors.accent,
              tooltip: link == null ? l10n.jiraLinkAction : link.issueKey,
              visualDensity: VisualDensity.compact,
            ),
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
