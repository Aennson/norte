import 'package:flutter/material.dart';

import '../theme/norte_colors.dart';
import '../theme/norte_spacing.dart';
import '../theme/norte_typography.dart';

/// The four task states the badge can render (`docs/design-system.md` §4).
///
/// Presentation-level on purpose: Sprint 00 has no domain yet. When
/// `domain/entities/task.dart` lands in Sprint 01, the screens map
/// `TaskStatus` onto this enum — the widget stays framework-only.
enum NorteStatus { todo, inProgress, done, blocked }

/// Mono uppercase label preceded by a 6px colour dot.
///
/// The [label] is supplied already localized by the caller (BR-11): the widget
/// never holds a user-facing literal.
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.status, required this.label, super.key});

  final NorteStatus status;

  /// Localized text, e.g. `AppLocalizations.of(context).statusDone`.
  final String label;

  Color _color(NorteColors colors) => switch (status) {
    NorteStatus.todo => colors.textMuted,
    NorteStatus.inProgress => colors.info,
    NorteStatus.done => colors.success,
    NorteStatus.blocked => colors.error,
  };

  @override
  Widget build(BuildContext context) {
    final colors = NorteColors.of(context);
    final color = _color(colors);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: NorteSpacing.sm),
        Text(
          label.toUpperCase(),
          style: NorteTypography.monoSmall.copyWith(color: color),
        ),
      ],
    );
  }
}
