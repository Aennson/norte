import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../shared/theme/norte_colors.dart';
import '../../shared/theme/norte_spacing.dart';
import '../../shared/theme/norte_typography.dart';
import '../../shared/widgets/norte_button.dart';

/// Confirmation for the one destructive action in the tasks flow.
///
/// Deleting a task is irreversible, so it asks first and the confirming button
/// uses the `error` variant (`docs/design-system.md` §4, `sprint-01`
/// validation rules). Resolves to `true` only when the user confirms —
/// dismissing the dialog counts as a cancel (S01-E2E-02).
class DeleteTaskDialog extends StatelessWidget {
  const DeleteTaskDialog({required this.taskTitle, super.key});

  /// Title of the task about to be deleted, quoted back to the user.
  final String taskTitle;

  /// Shows the dialog and resolves with the user's decision.
  static Future<bool> show(
    BuildContext context, {
    required String taskTitle,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => DeleteTaskDialog(taskTitle: taskTitle),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NorteSpacing.radius),
        side: BorderSide(color: colors.border, width: NorteSpacing.borderWidth),
      ),
      title: Text(
        l10n.taskDeleteTitle,
        style: NorteTypography.title.copyWith(color: colors.textPrimary),
      ),
      content: Text(
        l10n.taskDeleteMessage(taskTitle),
        style: NorteTypography.body.copyWith(color: colors.textSecondary),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        NorteSpacing.xl,
        0,
        NorteSpacing.xl,
        NorteSpacing.lg,
      ),
      actions: <Widget>[
        NorteButton(
          key: const Key('delete-cancel-button'),
          label: l10n.actionCancel,
          variant: NorteButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        NorteButton(
          key: const Key('delete-confirm-button'),
          label: l10n.actionDelete,
          variant: NorteButtonVariant.destructive,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
