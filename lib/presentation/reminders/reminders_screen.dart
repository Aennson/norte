import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/entities/reminder.dart';
import '../../domain/failures/failure.dart';
import '../../l10n/generated/app_localizations.dart';
import '../shared/theme/norte_colors.dart';
import '../shared/theme/norte_spacing.dart';
import '../shared/theme/norte_typography.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/error_state.dart';
import '../shared/widgets/loading_skeleton.dart';
import '../shared/widgets/norte_screen.dart';
import '../tasks/task_providers.dart';
import 'reminder_capture.dart';
import 'reminder_providers.dart';
import 'widgets/new_reminder_sheet.dart';
import 'widgets/push_to_talk_bar.dart';
import 'widgets/reminder_card.dart';

/// Reminders destination — Pillar 5's screen (`sprint-06`).
///
/// The four mandatory states come from the [StreamProvider]'s `AsyncValue`
/// plus a content state with no rows (`docs/design-system.md` §6), the same
/// arrangement `TasksScreen` uses.
///
/// **Upcoming and past are decided here, against the clock, not by a query.**
/// "Past" is a fact about *now*: a reminder due in one minute moves from one
/// section to the other while the screen is open, and a database that had
/// sorted them could only be right at the moment it was asked.
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  /// Route path of this destination.
  static const String routePath = '/reminders';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<Reminder>> reminders = ref.watch(remindersProvider);
    final ReminderCaptureState capture = ref.watch(reminderCaptureProvider);

    // The capture's outcome is a message, not a screen: the list below already
    // shows what was created, so the only thing left to say is what went
    // wrong, or that the app needs a time.
    ref.listen<ReminderCaptureState>(reminderCaptureProvider, (
      ReminderCaptureState? previous,
      ReminderCaptureState next,
    ) {
      if (next.askingForTime && previous?.askingForTime != true) {
        _askForTime(context, ref);
      }
      if (next.failure case final Failure failure
          when failure != previous?.failure) {
        _report(context, l10n, failure);
        ref.read(reminderCaptureProvider.notifier).acknowledge();
      }
    });

    return NorteScreen(
      title: l10n.navReminders,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PushToTalkBar(
            state: capture,
            onStart: () => ref.read(reminderCaptureProvider.notifier).start(),
            onStop: () => ref.read(reminderCaptureProvider.notifier).stop(),
            onTypeInstead: () => _createManually(context, ref),
          ),
          const SizedBox(height: NorteSpacing.lg),
          Expanded(
            child: reminders.when(
              loading: () =>
                  LoadingSkeletonList(semanticLabel: l10n.navReminders),
              error: (Object error, StackTrace stackTrace) => ErrorState(
                message: l10n.remindersLoadFailed,
                retryLabel: l10n.remindersRetry,
                onRetry: () => ref.invalidate(remindersProvider),
              ),
              data: (List<Reminder> all) => _RemindersList(
                reminders: all,
                onCancel: (Reminder reminder) =>
                    ref.read(cancelReminderProvider)(reminder.id),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createManually(BuildContext context, WidgetRef ref) async {
    final NewReminderInput? input = await showNewReminderSheet(context);
    if (input == null || !context.mounted) return;
    await ref
        .read(reminderCaptureProvider.notifier)
        .createManually(text: input.text, triggerAt: input.triggerAt);
  }

  /// The targeted question: the app asks for the **time alone**, because that
  /// is the only thing it is missing (S06-E2E-02).
  Future<void> _askForTime(BuildContext context, WidgetRef ref) async {
    final String? answer = await showReminderTimeSheet(context);
    if (answer == null || !context.mounted) return;
    await ref.read(reminderCaptureProvider.notifier).answerTime(answer);
  }

  void _report(BuildContext context, AppLocalizations l10n, Failure failure) {
    final String message = switch (failure) {
      InvalidTriggerTimeFailure() => l10n.remindersTimePassed,
      ValidationFailure(field: 'triggerAt') => l10n.remindersTimeUnreadable,
      AuthFailure() => l10n.remindersNotPermitted,
      _ => l10n.remindersLoadFailed,
    };
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RemindersList extends ConsumerWidget {
  const _RemindersList({required this.reminders, required this.onCancel});

  final List<Reminder> reminders;
  final void Function(Reminder) onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);
    final DateTime now = ref.watch(clockProvider).now().toUtc();

    final List<Reminder> upcoming = <Reminder>[
      for (final Reminder reminder in reminders)
        if (reminder.triggerAt.isAfter(now)) reminder,
    ]..sort((Reminder a, Reminder b) => a.triggerAt.compareTo(b.triggerAt));
    // Most recent first: what fired ten minutes ago matters more than what
    // fired last week.
    final List<Reminder> past = <Reminder>[
      for (final Reminder reminder in reminders)
        if (!reminder.triggerAt.isAfter(now)) reminder,
    ]..sort((Reminder a, Reminder b) => b.triggerAt.compareTo(a.triggerAt));

    if (upcoming.isEmpty && past.isEmpty) {
      return EmptyState(
        icon: LucideIcons.bell,
        message: l10n.remindersEmptyMessage,
      );
    }

    Widget header(String label) => Padding(
      padding: const EdgeInsets.only(
        top: NorteSpacing.sm,
        bottom: NorteSpacing.sm,
      ),
      child: Text(
        label,
        style: NorteTypography.caption.copyWith(color: colors.textMuted),
      ),
    );

    return ListView(
      children: <Widget>[
        if (upcoming.isNotEmpty) ...<Widget>[
          header(l10n.remindersUpcoming),
          for (final Reminder reminder in upcoming)
            ReminderCard(
              key: Key('reminder.${reminder.id}'),
              reminder: reminder,
              isPast: false,
              onCancel: () => onCancel(reminder),
            ),
        ],
        if (past.isNotEmpty) ...<Widget>[
          header(l10n.remindersPast),
          for (final Reminder reminder in past)
            ReminderCard(
              key: Key('reminder.${reminder.id}'),
              reminder: reminder,
              isPast: true,
              onCancel: () => onCancel(reminder),
            ),
        ],
      ],
    );
  }
}
