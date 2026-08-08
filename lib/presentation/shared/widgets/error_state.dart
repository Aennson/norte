import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/norte_colors.dart';
import '../theme/norte_spacing.dart';
import '../theme/norte_typography.dart';
import 'norte_button.dart';

/// One of the four mandatory screen states (`docs/design-system.md` §6):
/// a short message plus a retry action.
///
/// The icon uses the `error` token; the message stays in body type so a
/// failure reads as information, not as an alarm.
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.message,
    required this.retryLabel,
    super.key,
    this.onRetry,
  });

  /// Localized sentence explaining what failed (BR-11 — never a literal).
  final String message;

  /// Localized label of the retry action.
  final String retryLabel;

  /// `null` disables the button — used when nothing can be retried.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final NorteColors colors = NorteColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NorteSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(LucideIcons.circleAlert, size: 32, color: colors.error),
            const SizedBox(height: NorteSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: NorteTypography.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: NorteSpacing.lg),
            NorteButton(
              label: retryLabel,
              onPressed: onRetry,
              variant: NorteButtonVariant.secondary,
              icon: LucideIcons.rotateCw,
            ),
          ],
        ),
      ),
    );
  }
}
