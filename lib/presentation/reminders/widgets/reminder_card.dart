import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../domain/entities/reminder.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../shared/theme/norte_colors.dart';
import '../../shared/theme/norte_spacing.dart';
import '../../shared/theme/norte_typography.dart';
import '../../shared/widgets/norte_card.dart';

/// One reminder in the list (`docs/design-system.md` §4).
///
/// The time is **technical data**, so it is set in `mono` — the same rule that
/// puts issue keys and statuses in that face. A past reminder is drawn in
/// `textMuted` throughout: it is still information, and dimming it says "this
/// has happened" without needing a word for it (S06-GT-01).
class ReminderCard extends StatelessWidget {
  const ReminderCard({
    required this.reminder,
    required this.isPast,
    super.key,
    this.onCancel,
    this.onTap,
  });

  final Reminder reminder;

  /// `true` when [Reminder.triggerAt] has passed.
  final bool isPast;

  /// `null` hides the cancel control — a reminder that has already fired has
  /// nothing left to cancel.
  final VoidCallback? onCancel;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);
    final Color text = isPast ? colors.textMuted : colors.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: NorteSpacing.sm),
      child: NorteCard(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    reminder.text,
                    style: NorteTypography.body.copyWith(color: text),
                  ),
                  const SizedBox(height: NorteSpacing.xs),
                  Row(
                    children: <Widget>[
                      Text(
                        formatReminderTime(context, reminder.triggerAt),
                        style: NorteTypography.monoSmall.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                      if (reminder.isFired) ...<Widget>[
                        const SizedBox(width: NorteSpacing.sm),
                        Text(
                          l10n.remindersFired,
                          style: NorteTypography.caption.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (onCancel != null)
              IconButton(
                key: Key('reminder-cancel.${reminder.id}'),
                icon: const Icon(LucideIcons.x, size: 16),
                color: colors.textMuted,
                tooltip: l10n.remindersCancel,
                onPressed: onCancel,
              ),
          ],
        ),
      ),
    );
  }
}

/// Formats [instant] for the active locale — `8 Aug 2026, 09:00`.
///
/// Stored in UTC and shown in local time, as task due dates are: "nine
/// o'clock" is a reading of the user's own clock, and any other rendering of
/// it would be a reminder they cannot check.
String formatReminderTime(BuildContext context, DateTime instant) {
  final String locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(locale).add_Hm().format(instant.toLocal());
}
