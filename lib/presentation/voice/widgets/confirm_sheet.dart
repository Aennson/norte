import 'package:flutter/material.dart';

import '../../shared/theme/norte_colors.dart';
import '../../shared/theme/norte_spacing.dart';
import '../../shared/theme/norte_typography.dart';
import '../../shared/widgets/norte_button.dart';

/// The bottom sheet that stands between a parsed intent and a mutation
/// (BR-04, `docs/design-system.md` §4).
///
/// Three things are on it, and each is there for a reason:
///
/// * **The interpreted action, in `mono`.** Not the words the user said — what
///   the app understood them to mean. A user who sees `PROJ-124 → Done` when
///   they said 123 catches the mistake here, which is the only place it is
///   still free to catch.
/// * **A confidence bar.** How sure the app is, as a quantity rather than an
///   adjective. It is coloured `warning` below the threshold and `accent`
///   above it, so the two cases the router distinguishes look different.
/// * **Why it is asking.** A confident Jira write and a doubtful parse both
///   land here, and telling the user which is which is the difference between
///   a policy they can change in Settings and a sentence they should repeat.
class ConfirmSheet extends StatelessWidget {
  const ConfirmSheet({
    required this.title,
    required this.action,
    required this.reason,
    required this.confidence,
    required this.confidenceLabel,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
    super.key,
  });

  /// Localized sheet title (BR-11).
  final String title;

  /// The interpreted action, already localized and formatted.
  final String action;

  /// Why the app is asking.
  final String reason;

  /// Parser confidence, `0.0..1.0`.
  final double confidence;

  /// Localized "Confidence 68%".
  final String confidenceLabel;

  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  /// **BR-04** — the line the bar is read against.
  static const double threshold = 0.75;

  /// Keys the widget and E2E suites drive this sheet by.
  static const Key confirmButtonKey = Key('voice.confirm');
  static const Key cancelButtonKey = Key('voice.cancel');

  @override
  Widget build(BuildContext context) {
    final colors = NorteColors.of(context);
    final bool isDoubtful = confidence < threshold;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.border,
            width: NorteSpacing.borderWidth,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(NorteSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                title,
                style: NorteTypography.title.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: NorteSpacing.md),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.accentSubtle,
                  borderRadius: BorderRadius.circular(NorteSpacing.radius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(NorteSpacing.md),
                  child: Text(
                    action,
                    style: NorteTypography.mono.copyWith(color: colors.accent),
                  ),
                ),
              ),
              const SizedBox(height: NorteSpacing.lg),
              Semantics(
                label: confidenceLabel,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(NorteSpacing.xs),
                      child: LinearProgressIndicator(
                        value: confidence.clamp(0.0, 1.0),
                        minHeight: NorteSpacing.xs,
                        backgroundColor: colors.surfaceRaised,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDoubtful ? colors.warning : colors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: NorteSpacing.sm),
                    Text(
                      confidenceLabel,
                      style: NorteTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: NorteSpacing.md),
              Text(
                reason,
                style: NorteTypography.body.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: NorteSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: NorteButton(
                      key: ConfirmSheet.cancelButtonKey,
                      label: cancelLabel,
                      onPressed: onCancel,
                      variant: NorteButtonVariant.secondary,
                    ),
                  ),
                  const SizedBox(width: NorteSpacing.md),
                  Expanded(
                    child: NorteButton(
                      key: ConfirmSheet.confirmButtonKey,
                      label: confirmLabel,
                      onPressed: onConfirm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
