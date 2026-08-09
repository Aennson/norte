import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/entities/reminder.dart';
import '../../l10n/generated/app_localizations.dart';
import '../shared/theme/norte_colors.dart';
import '../shared/theme/norte_spacing.dart';
import '../shared/theme/norte_typography.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_skeleton.dart';
import '../shared/widgets/norte_button.dart';
import '../shared/widgets/norte_screen.dart';
import '../tasks/task_providers.dart';
import 'reminder_providers.dart';
import 'widgets/reminder_card.dart';

/// One reminder, opened by tapping its notification (`sprint-06` scope: the
/// deep link).
///
/// **It survives the reminder not being there.** A notification can outlive
/// the row it came from — the user cancels a reminder on their laptop and taps
/// the toast on their phone — and a screen that assumed the id resolves would
/// meet that as a crash. The empty state says so instead.
class ReminderDetailScreen extends ConsumerWidget {
  const ReminderDetailScreen({required this.reminderId, super.key});

  /// Path of this route, nested under the reminders branch.
  static const String routeSegment = ':id';

  /// Full location of the reminder with [id].
  static String locationOf(String id) => '/reminders/$id';

  final String reminderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);
    final AsyncValue<List<Reminder>> reminders = ref.watch(remindersProvider);

    return NorteScreen(
      title: l10n.navReminders,
      onBack: () => context.go(RemindersLocation.path),
      child: reminders.when(
        loading: () =>
            LoadingSkeletonList(semanticLabel: l10n.navReminders, itemCount: 1),
        error: (Object error, StackTrace stackTrace) => EmptyState(
          icon: LucideIcons.bell,
          message: l10n.remindersLoadFailed,
        ),
        data: (List<Reminder> all) {
          final Reminder? reminder = all
              .where((Reminder candidate) => candidate.id == reminderId)
              .firstOrNull;
          if (reminder == null) {
            return EmptyState(
              icon: LucideIcons.bell,
              message: l10n.remindersEmptyMessage,
            );
          }

          final DateTime now = ref.watch(clockProvider).now().toUtc();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                reminder.text,
                style: NorteTypography.title.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: NorteSpacing.sm),
              Text(
                formatReminderTime(context, reminder.triggerAt),
                style: NorteTypography.mono.copyWith(color: colors.textMuted),
              ),
              const SizedBox(height: NorteSpacing.xl),
              if (reminder.triggerAt.isAfter(now))
                NorteButton(
                  key: const Key('reminder-detail-cancel'),
                  label: l10n.remindersCancel,
                  variant: NorteButtonVariant.secondary,
                  onPressed: () async {
                    await ref.read(cancelReminderProvider)(reminder.id);
                    if (context.mounted) context.go(RemindersLocation.path);
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

/// The reminders destination's location, without importing the screen that
/// declares it — the detail screen and the router both need it, and the list
/// screen importing the detail screen and back would be a cycle.
abstract final class RemindersLocation {
  static const String path = '/reminders';
}
