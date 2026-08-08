import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../shared/theme/norte_colors.dart';

/// The always-present voice affordance: an `accent` circle with a mic icon
/// (`docs/design-system.md` §5).
///
/// Sprint 00 ships the affordance only — [onPressed] stays unwired until the
/// realtime voice pipeline arrives in Sprint 05.
class VoiceButton extends StatelessWidget {
  const VoiceButton({required this.semanticLabel, super.key, this.onPressed});

  /// Localized accessible label (BR-11).
  final String semanticLabel;

  final VoidCallback? onPressed;

  /// Diameter of the circle.
  static const double size = 48;

  @override
  Widget build(BuildContext context) {
    final colors = NorteColors.of(context);

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Tooltip(
        message: semanticLabel,
        child: Material(
          color: colors.accent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            hoverColor: colors.accentHover,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(LucideIcons.mic, size: 20, color: colors.onAccent),
            ),
          ),
        ),
      ),
    );
  }
}
