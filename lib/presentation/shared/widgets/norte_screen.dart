import 'package:flutter/material.dart';

import '../theme/norte_spacing.dart';
import '../theme/norte_typography.dart';
import '../theme/norte_colors.dart';

/// Common chrome for every destination: screen title in `display` type and a
/// content column capped at 840px on desktop (`docs/design-system.md` §5).
class NorteScreen extends StatelessWidget {
  const NorteScreen({
    required this.title,
    required this.child,
    super.key,
    this.action,
    this.onBack,
  });

  /// Localized screen title (BR-11).
  final String title;

  /// Optional primary action rendered on the title row, e.g. "New task".
  /// `null` keeps the header exactly as Sprint 00 shipped it.
  final Widget? action;

  /// Leaves this screen. `null` — the case for the four tab destinations —
  /// renders no control at all.
  ///
  /// Added in Sprint 03, which is the first sprint to *push* a screen rather
  /// than switch tabs. Without it the meeting composer was a dead end on
  /// desktop: no system back gesture, no chrome, no way out.
  final VoidCallback? onBack;

  final Widget child;

  /// Key of the back control, for the tests that drive it.
  static const Key backButtonKey = Key('norte-screen.back');

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
                  Row(
                    children: <Widget>[
                      if (onBack != null) ...<Widget>[
                        IconButton(
                          key: backButtonKey,
                          icon: const Icon(Icons.arrow_back),
                          color: colors.textSecondary,
                          onPressed: onBack,
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).backButtonTooltip,
                        ),
                        const SizedBox(width: NorteSpacing.sm),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: NorteTypography.display.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      ?action,
                    ],
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
