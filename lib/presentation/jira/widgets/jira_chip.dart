import 'package:flutter/material.dart';

import '../../../domain/entities/jira_link.dart';
import '../../shared/theme/norte_colors.dart';
import '../../shared/theme/norte_spacing.dart';
import '../../shared/theme/norte_typography.dart';

/// The issue key on a linked task (`docs/design-system.md` §4).
///
/// `accentSubtle` fill, `accent` text, `mono` face — an issue key is technical
/// data, and the mono face is what tells the eye it can be copied verbatim
/// (§1.4).
///
/// Tapping it is the link action. The chip carries no status of its own: the
/// task's own [StatusBadge] says where the work stands here, and the Jira
/// status appears only when the two disagree, on the `DivergenceBanner`
/// (BR-02).
class JiraChip extends StatelessWidget {
  const JiraChip({
    required this.link,
    super.key,
    this.onTap,
    this.semanticsLabel,
  });

  final JiraLink link;

  /// Opens the issue. `null` renders the chip as a plain label.
  final VoidCallback? onTap;

  /// Accessible name, already localized. Falls back to the issue key.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final NorteColors colors = NorteColors.of(context);
    final BorderRadius radius = BorderRadius.circular(NorteSpacing.radius);

    final Widget label = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: NorteSpacing.sm,
        vertical: NorteSpacing.xs,
      ),
      child: Text(
        link.issueKey,
        style: NorteTypography.mono.copyWith(color: colors.accent),
      ),
    );

    return Semantics(
      label: semanticsLabel ?? link.issueKey,
      button: onTap != null,
      child: Material(
        color: colors.accentSubtle,
        borderRadius: radius,
        child: onTap == null
            ? label
            : InkWell(
                onTap: onTap,
                borderRadius: radius,
                hoverColor: colors.surfaceRaised,
                child: label,
              ),
      ),
    );
  }
}
