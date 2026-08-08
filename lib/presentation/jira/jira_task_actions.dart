import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../application/usecases/refresh_jira_status.dart';
import '../../domain/entities/jira_status_mapping.dart';
import '../../domain/entities/outbox_operation.dart';
import '../../domain/entities/task.dart';
import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../l10n/generated/app_localizations.dart';
import '../shared/theme/norte_colors.dart';
import '../shared/theme/norte_spacing.dart';
import '../shared/theme/norte_typography.dart';
import '../shared/widgets/norte_button.dart';
import '../shared/widgets/norte_text_field.dart';
import '../tasks/task_providers.dart';
import 'jira_failure_text.dart';
import 'jira_providers.dart';

/// The Jira actions available on one task.
///
/// Everything the user can do to a ticket from a task lives here, so the
/// tasks screen stays about tasks. Two rules shape the whole file:
///
/// * **Writes are queued, reads are not** (BR-05). A comment or a transition
///   returns the instant it is in the outbox, and the user is told so. Linking
///   and refreshing go to the site and can therefore fail in ways the user
///   must see.
/// * **A divergence is never resolved here** (BR-02). [keepLocal] and
///   [adoptRemote] exist only because the user pressed one of the two buttons
///   on the banner; nothing calls them on the app's own initiative.
abstract final class JiraTaskActions {
  /// Keys the tests and the E2E suite drive these dialogs by.
  static const Key issueKeyFieldKey = Key('jira.issueKey');
  static const Key commentFieldKey = Key('jira.comment');
  static const Key projectKeyFieldKey = Key('jira.projectKey');
  static const Key confirmButtonKey = Key('jira.confirm');
  static const Key menuLinkKey = Key('jira.menu.link');
  static const Key menuUnlinkKey = Key('jira.menu.unlink');
  static const Key menuRefreshKey = Key('jira.menu.refresh');
  static const Key menuCommentKey = Key('jira.menu.comment');
  static const Key menuPushStatusKey = Key('jira.menu.pushStatus');
  static const Key menuCreateIssueKey = Key('jira.menu.createIssue');

  /// Opens the action sheet for [task].
  static Future<void> showMenu(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (!ref.read(jiraConfiguredProvider)) {
      _tell(context, l10n.jiraNotConfiguredMessage);
      return;
    }

    final _JiraAction? action = await showModalBottomSheet<_JiraAction>(
      context: context,
      backgroundColor: NorteColors.of(context).surface,
      builder: (BuildContext sheetContext) =>
          _ActionSheet(isLinked: task.jiraLink != null),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case _JiraAction.link:
        await link(context, ref, task);
      case _JiraAction.unlink:
        await ref.read(unlinkTaskProvider)(taskId: task.id);
      case _JiraAction.refresh:
        await refresh(context, ref, task);
      case _JiraAction.comment:
        await comment(context, ref, task);
      case _JiraAction.pushStatus:
        await pushStatus(context, ref, task);
      case _JiraAction.createIssue:
        await createIssue(context, ref, task);
    }
  }

  /// Asks for an issue key and links it — after the site has confirmed it
  /// exists (`sprint-02` validation rules).
  static Future<void> link(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? issueKey = await _ask(
      context,
      title: l10n.jiraLinkTitle,
      label: l10n.jiraFieldIssueKey,
      hint: l10n.jiraFieldIssueKeyHint,
      confirmLabel: l10n.jiraLinkAction,
      fieldKey: issueKeyFieldKey,
    );
    if (issueKey == null || !context.mounted) return;

    final Result<Task> result = await ref.read(linkTaskToJiraProvider)(
      taskId: task.id,
      issueKey: issueKey,
    );
    if (!context.mounted) return;
    if (result case Err<Task>(:final Failure failure)) {
      _tell(context, jiraFailureText(l10n, failure));
    }
  }

  /// Re-reads the issue status. Updates the cache; decides nothing (BR-02).
  static Future<void> refresh(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Result<JiraRefresh> result = await ref.read(
      refreshJiraStatusProvider,
    )(task);
    if (!context.mounted) return;
    if (result case Err<JiraRefresh>(:final Failure failure)) {
      _tell(context, jiraFailureText(l10n, failure));
    }
  }

  /// Queues a comment.
  static Future<void> comment(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? body = await _ask(
      context,
      title: l10n.jiraCommentTitle,
      label: l10n.jiraFieldComment,
      confirmLabel: l10n.jiraCommentAction,
      fieldKey: commentFieldKey,
      maxLines: 4,
    );
    if (body == null || !context.mounted) return;

    final Result<OutboxOperation> queued = await ref.read(
      addJiraCommentProvider,
    )(task: task, body: body);
    if (context.mounted) _queue(context, queued);
  }

  /// Queues a transition to the task's current local status.
  static Future<void> pushStatus(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final Result<OutboxOperation> queued = await ref.read(
      updateJiraStatusProvider,
    )(task: task, status: JiraStatusMapping.toRemote(task.status));
    if (context.mounted) _queue(context, queued);
  }

  /// Queues the creation of an issue from the task.
  static Future<void> createIssue(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? projectKey = await _ask(
      context,
      title: l10n.jiraCreateIssueTitle,
      label: l10n.jiraFieldProjectKey,
      hint: l10n.jiraFieldProjectKeyHint,
      confirmLabel: l10n.jiraCreateIssueAction,
      fieldKey: projectKeyFieldKey,
    );
    if (projectKey == null || !context.mounted) return;

    final Result<OutboxOperation> queued = await ref.read(
      createJiraIssueFromTaskProvider,
    )(task: task, projectKey: projectKey);
    if (context.mounted) _queue(context, queued);
  }

  /// Divergence decision — keep the local status, and tell Jira about it.
  ///
  /// The local task is left exactly as it was; what changes is that a
  /// transition joins the queue.
  static Future<void> keepLocal(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final Result<OutboxOperation> queued = await ref.read(
      updateJiraStatusProvider,
    )(task: task, status: JiraStatusMapping.toRemote(task.status));
    if (context.mounted) _queue(context, queued);
  }

  /// Divergence decision — take Jira's status locally.
  ///
  /// Nothing is sent to the site: the user is agreeing with it, not
  /// instructing it. An unmappable remote status leaves the task alone, since
  /// there is no local state to move it to.
  static Future<void> adoptRemote(WidgetRef ref, Task task) async {
    final String? remote = task.jiraLink?.lastKnownStatus;
    final TaskStatus? adopted = remote == null
        ? null
        : JiraStatusMapping.toLocal(remote);
    if (adopted == null) return;

    await ref.read(updateTaskProvider)(id: task.id, status: adopted);
  }

  /// Reports the outcome of an enqueue.
  static void _queue(BuildContext context, Result<OutboxOperation> result) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    _tell(context, switch (result) {
      Ok<OutboxOperation>() => l10n.jiraQueuedMessage,
      Err<OutboxOperation>(:final Failure failure) => jiraFailureText(
        l10n,
        failure,
      ),
    });
  }

  static void _tell(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: NorteTypography.body),
        backgroundColor: NorteColors.of(context).surfaceRaised,
      ),
    );
  }

  /// One-field dialog. Returns the trimmed value, or `null` if cancelled.
  static Future<String?> _ask(
    BuildContext context, {
    required String title,
    required String label,
    required String confirmLabel,
    required Key fieldKey,
    String? hint,
    int maxLines = 1,
  }) {
    final TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        final NorteColors colors = NorteColors.of(dialogContext);
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NorteSpacing.radius),
          ),
          title: Text(
            title,
            style: NorteTypography.title.copyWith(color: colors.textPrimary),
          ),
          content: NorteTextField(
            key: fieldKey,
            label: label,
            hint: hint,
            controller: controller,
            autofocus: true,
            maxLines: maxLines,
          ),
          actions: <Widget>[
            NorteButton(
              label: AppLocalizations.of(dialogContext).actionCancel,
              onPressed: () => Navigator.of(dialogContext).pop(),
              variant: NorteButtonVariant.secondary,
            ),
            NorteButton(
              key: confirmButtonKey,
              label: confirmLabel,
              onPressed: () {
                final String value = controller.text.trim();
                Navigator.of(dialogContext).pop(value.isEmpty ? null : value);
              },
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }
}

/// What the action sheet can return.
enum _JiraAction { link, unlink, refresh, comment, pushStatus, createIssue }

class _ActionSheet extends StatelessWidget {
  const _ActionSheet({required this.isLinked});

  final bool isLinked;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);

    Widget item(Key key, IconData icon, String label, _JiraAction action) =>
        ListTile(
          key: key,
          leading: Icon(icon, size: 18, color: colors.textSecondary),
          title: Text(
            label,
            style: NorteTypography.body.copyWith(color: colors.textPrimary),
          ),
          onTap: () => Navigator.of(context).pop(action),
        );

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: isLinked
            ? <Widget>[
                item(
                  JiraTaskActions.menuRefreshKey,
                  LucideIcons.refreshCw,
                  l10n.jiraRefreshAction,
                  _JiraAction.refresh,
                ),
                item(
                  JiraTaskActions.menuPushStatusKey,
                  LucideIcons.arrowUpRight,
                  l10n.jiraPushStatusAction,
                  _JiraAction.pushStatus,
                ),
                item(
                  JiraTaskActions.menuCommentKey,
                  LucideIcons.messageSquare,
                  l10n.jiraCommentAction,
                  _JiraAction.comment,
                ),
                item(
                  JiraTaskActions.menuUnlinkKey,
                  LucideIcons.unlink,
                  l10n.jiraUnlinkAction,
                  _JiraAction.unlink,
                ),
              ]
            : <Widget>[
                item(
                  JiraTaskActions.menuLinkKey,
                  LucideIcons.link,
                  l10n.jiraLinkAction,
                  _JiraAction.link,
                ),
                item(
                  JiraTaskActions.menuCreateIssueKey,
                  LucideIcons.plus,
                  l10n.jiraCreateIssueAction,
                  _JiraAction.createIssue,
                ),
              ],
      ),
    );
  }
}
