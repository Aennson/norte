import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../shared/theme/norte_colors.dart';
import '../../shared/theme/norte_spacing.dart';
import '../../shared/theme/norte_typography.dart';
import '../../shared/widgets/norte_button.dart';
import '../reminder_capture.dart';

/// The push-to-talk control and its countdown (`sprint-06` scope).
///
/// **The countdown is the visual feedback the limit needs.** A capture that
/// simply stopped after fifteen seconds would look like a bug; one that has
/// been counting down in front of the user for fifteen seconds is a rule they
/// watched being applied. The number is set in `mono` because it is a
/// measurement, not prose.
class PushToTalkBar extends StatelessWidget {
  const PushToTalkBar({
    required this.state,
    required this.onStart,
    required this.onStop,
    required this.onTypeInstead,
    super.key,
  });

  final ReminderCaptureState state;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onTypeInstead;

  /// Key of the record control, for the tests that drive it.
  static const Key recordKey = Key('reminder-push-to-talk');

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: NorteButton(
                key: recordKey,
                label: state.isCapturing
                    ? l10n.remindersListening
                    : l10n.remindersHold,
                icon: state.isCapturing ? LucideIcons.square : LucideIcons.mic,
                onPressed: state.isCapturing ? onStop : onStart,
              ),
            ),
            const SizedBox(width: NorteSpacing.sm),
            NorteButton(
              key: const Key('reminder-type-instead'),
              label: l10n.remindersTypeInstead,
              variant: NorteButtonVariant.secondary,
              onPressed: onTypeInstead,
            ),
          ],
        ),
        if (state.isCapturing) ...<Widget>[
          const SizedBox(height: NorteSpacing.sm),
          Row(
            children: <Widget>[
              Text(
                l10n.remindersSecondsLeft(state.secondsLeft),
                style: NorteTypography.monoSmall.copyWith(
                  color: colors.textMuted,
                ),
              ),
              if (state.partial case final String partial
                  when partial.isNotEmpty) ...<Widget>[
                const SizedBox(width: NorteSpacing.sm),
                Expanded(
                  child: Text(
                    partial,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NorteTypography.caption.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
        if (state.limitReached) ...<Widget>[
          const SizedBox(height: NorteSpacing.sm),
          Text(
            l10n.remindersLimitReached,
            style: NorteTypography.caption.copyWith(color: colors.textMuted),
          ),
        ],
      ],
    );
  }
}
