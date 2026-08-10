import '../../domain/entities/reminder.dart';
import '../../domain/ports/clock.dart';
import '../../domain/ports/notification_scheduler.dart';
import '../../domain/ports/reminder_notification_copy.dart';
import '../../domain/ports/reminder_repository.dart';

/// What a launch check did, so the report and the tests can say it.
class LaunchCheckOutcome {
  const LaunchCheckOutcome({
    required this.delivered,
    required this.rescheduled,
  });

  /// Ids of overdue reminders that were delivered now, in trigger order.
  final List<String> delivered;

  /// Ids of future reminders re-registered with the platform.
  final List<String> rescheduled;
}

/// The check when the app opens (`docs/architecture.md` §12).
///
/// **Windows has no persistent scheduler.** `flutter_local_notifications` hands
/// Android and iOS a registration the OS keeps across reboots; the WinRT toast
/// path registers with a running application, so everything scheduled is lost
/// when Norte closes. §12 answers that with a check on launch, and this is it.
/// Running it on mobile too is harmless — [NotificationScheduler.schedule]
/// replaces by id, so re-registering something already registered cannot
/// double-fire — and one routine that behaves the same everywhere is worth
/// more than a platform branch nobody exercises on the other platform.
///
/// Two things happen, and the split is the whole subject of S06-IT-01:
///
/// * a reminder whose time has **passed** and which has not fired is
///   delivered now, and marked [Reminder.isFired] so the next launch leaves it
///   alone. This is the one that makes a missed reminder a late reminder
///   rather than a lost one;
/// * a reminder still in the **future** is re-registered.
///
/// A reminder that is overdue and already fired is touched by neither. That is
/// the case a naive "deliver everything overdue" would get wrong, and the user
/// would experience it as the same reminder shouting at them every time they
/// opened the app.
class CheckDueReminders {
  const CheckDueReminders({
    required this.repository,
    required this.scheduler,
    required this.clock,
    required this.copy,
  });

  final ReminderRepository repository;
  final NotificationScheduler scheduler;
  final Clock clock;
  final ReminderNotificationCopy copy;

  /// Runs the check.
  ///
  /// Never throws: a launch routine that can fail the launch is worse than one
  /// that quietly does less. A scheduler refusing a registration — a denied
  /// permission, most often — leaves the row untouched, so the next launch
  /// tries again.
  Future<LaunchCheckOutcome> call() async {
    final DateTime now = clock.now().toUtc();
    // A copy: what a repository hands back is its own, and at least one
    // implementation returns it unmodifiable. Sorting the caller's list in
    // place is a habit that works until the day it does not.
    final List<Reminder> all = List<Reminder>.of(await repository.listAll())
      ..sort((Reminder a, Reminder b) => a.triggerAt.compareTo(b.triggerAt));

    final List<String> delivered = <String>[];
    final List<String> rescheduled = <String>[];

    for (final Reminder reminder in all) {
      final bool overdue = !reminder.triggerAt.isAfter(now);
      if (overdue && reminder.isFired) continue;

      try {
        await scheduler.schedule(
          ScheduledNotification(
            id: reminder.id,
            title: copy.title,
            body: reminder.text,
            triggerAt: reminder.triggerAt,
          ),
        );
      } on Object {
        // Nothing is marked and nothing is recorded: the next launch retries.
        continue;
      }

      if (overdue) {
        await repository.save(reminder.copyWith(isFired: true));
        delivered.add(reminder.id);
      } else {
        rescheduled.add(reminder.id);
      }
    }

    return LaunchCheckOutcome(delivered: delivered, rescheduled: rescheduled);
  }
}
