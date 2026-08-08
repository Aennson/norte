import 'package:flutter/material.dart';

import '../theme/norte_colors.dart';
import '../theme/norte_spacing.dart';

/// Flat surface of the design system: `surface` background, 1px `border`,
/// radius 8, padding 16 (`docs/design-system.md` §4).
///
/// No elevation and no shadow — the terminal aesthetic separates surfaces with
/// hairlines, not depth.
class NorteCard extends StatelessWidget {
  const NorteCard({
    required this.child,
    super.key,
    this.onTap,
    this.padding = const EdgeInsets.all(NorteSpacing.lg),
  });

  final Widget child;

  /// Makes the whole card tappable; `null` renders a static surface.
  final VoidCallback? onTap;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = NorteColors.of(context);
    final radius = BorderRadius.circular(NorteSpacing.radius);

    return Material(
      color: colors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        hoverColor: colors.surfaceRaised,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: colors.border,
              width: NorteSpacing.borderWidth,
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
