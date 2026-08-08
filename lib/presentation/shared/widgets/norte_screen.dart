import 'package:flutter/material.dart';

import '../theme/norte_spacing.dart';
import '../theme/norte_typography.dart';
import '../theme/norte_colors.dart';

/// Common chrome for every destination: screen title in `display` type and a
/// content column capped at 840px on desktop (`docs/design-system.md` §5).
class NorteScreen extends StatelessWidget {
  const NorteScreen({required this.title, required this.child, super.key});

  /// Localized screen title (BR-11).
  final String title;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = NorteColors.of(context);
    final isDesktop =
        MediaQuery.sizeOf(context).width >= NorteSpacing.desktopBreakpoint;
    final padding = isDesktop
        ? NorteSpacing.screenPaddingDesktop
        : NorteSpacing.screenPaddingMobile;

    return ColoredBox(
      color: colors.bg,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: NorteSpacing.contentMaxWidth,
            ),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    title,
                    style: NorteTypography.display.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: NorteSpacing.lg),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
