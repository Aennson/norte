import 'package:flutter/material.dart';

import '../theme/norte_colors.dart';
import '../theme/norte_spacing.dart';
import '../theme/norte_typography.dart';

/// Selectable pill used for filters and small option sets.
///
/// Selected: `accentSubtle` fill with `accent` text, the highlight treatment
/// `docs/design-system.md` §2 reserves for accent chips. Unselected: `surface`
/// fill with a 1px `border`.
///
/// The [label] is technical data (a status, a priority, an ordering), so it is
/// drawn in the `monoSmall` role like [StatusBadge] — and arrives already
/// localized (BR-11).
class NorteChip extends StatelessWidget {
  const NorteChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    super.key,
    this.dotColor,
  });

  /// Localized text.
  final String label;

  final bool isSelected;

  /// Tap handler. `null` makes the chip a label rather than a control — used
  /// where a chip states a fact (the type of a saved meeting) or is
  /// temporarily unavailable (the template picker while a summary runs). A
  /// null handler also drops the button semantics, so a screen reader is not
  /// told about an action that is not there.
  final VoidCallback? onSelected;

  /// Optional 6px leading dot, matching [StatusBadge]'s status colours.
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final NorteColors colors = NorteColors.of(context);
    final Color foreground = isSelected ? colors.accent : colors.textSecondary;
    final BorderRadius radius = BorderRadius.circular(NorteSpacing.radius);

    return Semantics(
      selected: isSelected,
      button: onSelected != null,
      child: Material(
        color: isSelected ? colors.accentSubtle : colors.surface,
        borderRadius: radius,
        child: InkWell(
          onTap: onSelected,
          borderRadius: radius,
          hoverColor: colors.surfaceRaised,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: isSelected ? colors.accent : colors.border,
                width: NorteSpacing.borderWidth,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: NorteSpacing.md,
                vertical: NorteSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (dotColor != null) ...<Widget>[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: NorteSpacing.sm),
                  ],
                  Text(
                    label.toUpperCase(),
                    style: NorteTypography.monoSmall.copyWith(
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
