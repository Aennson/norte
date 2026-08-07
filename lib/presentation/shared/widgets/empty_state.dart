import 'package:flutter/material.dart';

import '../theme/norte_colors.dart';
import '../theme/norte_spacing.dart';
import '../theme/norte_typography.dart';
import 'norte_button.dart';

/// One of the four mandatory screen states (`docs/design-system.md` §6):
/// a 32px muted icon, one short sentence, and an optional primary action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.message,
    super.key,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;

  /// Localized sentence (BR-11 — never a literal).
  final String message;

  /// Localized label of the optional primary action.
  final String? actionLabel;

  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = NorteColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NorteSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 32, color: colors.textMuted),
            const SizedBox(height: NorteSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: NorteTypography.body.copyWith(color: colors.textSecondary),
            ),
            if (actionLabel != null) ...<Widget>[
              const SizedBox(height: NorteSpacing.lg),
              NorteButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
