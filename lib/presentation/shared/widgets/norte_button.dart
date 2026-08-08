import 'package:flutter/material.dart';

import '../theme/norte_colors.dart';
import '../theme/norte_spacing.dart';
import '../theme/norte_typography.dart';

/// Visual variants of [NorteButton] (`docs/design-system.md` §4).
enum NorteButtonVariant {
  /// `accent` background with `onAccent` label.
  primary,

  /// 1px `border` outline with `textPrimary` label.
  secondary,

  /// `error` background — destructive actions.
  destructive,
}

/// The project's button: radius 8, height 40, no elevation, no splash.
///
/// A `null` [onPressed] renders the disabled state (50% opacity); [isLoading]
/// replaces the label with a 16px spinner while keeping the button's width.
class NorteButton extends StatelessWidget {
  const NorteButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = NorteButtonVariant.primary,
    this.isLoading = false,
    this.icon,
  });

  /// Localized label (BR-11 — never a literal).
  final String label;

  /// `null` disables the button.
  final VoidCallback? onPressed;

  final NorteButtonVariant variant;

  /// Swaps the label for a 16px spinner and blocks interaction.
  final bool isLoading;

  /// Optional leading icon.
  final IconData? icon;

  bool get _isDisabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = NorteColors.of(context);

    final (
      Color background,
      Color foreground,
      Color? outline,
    ) = switch (variant) {
      NorteButtonVariant.primary => (colors.accent, colors.onAccent, null),
      NorteButtonVariant.secondary => (
        colors.surface,
        colors.textPrimary,
        colors.border,
      ),
      NorteButtonVariant.destructive => (colors.error, colors.onAccent, null),
    };

    final button = SizedBox(
      height: NorteSpacing.buttonHeight,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(NorteSpacing.radius),
        child: InkWell(
          onTap: _isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(NorteSpacing.radius),
          hoverColor: variant == NorteButtonVariant.secondary
              ? colors.surfaceRaised
              : colors.accentHover,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(NorteSpacing.radius),
              border: outline == null
                  ? null
                  : Border.all(color: outline, width: NorteSpacing.borderWidth),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: NorteSpacing.lg),
              child: Center(
                widthFactor: 1,
                child: isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foreground,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (icon != null) ...<Widget>[
                            Icon(icon, size: 16, color: foreground),
                            const SizedBox(width: NorteSpacing.sm),
                          ],
                          Text(
                            label,
                            style: NorteTypography.body.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!_isDisabled) return button;
    return Opacity(opacity: 0.5, child: IgnorePointer(child: button));
  }
}
