import '../../domain/entities/reminder.dart';
import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/clock.dart';
import '../../domain/ports/id_generator.dart';
import '../../domain/ports/notification_scheduler.dart';
import '../../domain/ports/reminder_notification_copy.dart';
import '../../domain/ports/reminder_repository.dart';
import '../../domain/ports/time_zone.dart';
import '../../domain/services/trigger_time.dart';

/// Creates a reminder and asks the platform to deliver it — Pillar 5 end to
/// end (`docs/architecture.md` §8).
///
/// This is the Sprint 05 stub grown up. That stub could resolve `+20m` and an
/// ISO instant and refused every wall-clock phrase, because resolving one
/// needs a zone and it had none; it also held no scheduler at all, so that
/// "Sprint 05 does not schedule" was a fact about its constructor. Both gaps
/// close here, and the order of what follows is the whole use case:
///
/// 1. the text must not be blank,
/// 2. the slot must resolve — [TriggerTime] and the injected [TimeZone],
/// 3. the instant must be in the future,
/// 4. persist,
/// 5. schedule.
///
/// **Persist before schedule, and never the other way round.** A scheduled
/// notification with no row behind it fires and lands the user on a reminder
/// that does not exist; a row with no schedule is a reminder that shows in the
/// list and is caught by the launch check. One of those two failures is
/// recoverable and the other is not, so the order is not a matter of taste.
///
/// **A refused schedule does not discard the reminder.** When the user has
/// denied the notification permission the row stays and the failure surfaces —
/// what they said is not thrown away because the platform said no, and the
/// screen can offer the permission again with the reminder still listed.
///
/// **BR-06 needs nothing from this class.** [Reminder.sourceAudioNote] is
/// never set here and the repository drops it on write regardless, so there is
/// no path by which audio reaches disk — S06-UT-04 asserts it for both the
/// success and the failure branch precisely because neither branch can be the
/// one that leaks.
class CreateVoiceReminder {
  const CreateVoiceReminder({
    required this.repository,
    required this.scheduler,
    required this.clock,
    required this.zone,
    required this.idGenerator,
    required this.copy,
  });

  final ReminderRepository repository;
  final NotificationScheduler scheduler;
  final Clock clock;
  final TimeZone zone;
  final IdGenerator idGenerator;
  final ReminderNotificationCopy copy;

  /// Stores a reminder saying [text], due at [triggerAt], and schedules its
  /// notification.
  ///
  /// [triggerAt] is the slot exactly as the parser returned it — this class
  /// owns reading it, so a caller never has to know the grammar.
  Future<Result<Reminder>> call({
    required String text,
    required String triggerAt,
  }) async {
    final String body = text.trim();
    if (body.isEmpty) {
      return const Err<Reminder>(
        ValidationFailure('reminder text must not be empty', 'text'),
      );
    }

    final DateTime now = clock.now().toUtc();
    final DateTime? due = TriggerTime.resolve(triggerAt, now, zone);
    if (due == null) {
      return Err<Reminder>(
        ValidationFailure(
          '"$triggerAt" is not a time this app can read',
          'triggerAt',
        ),
      );
    }
    if (!due.isAfter(now)) {
      return Err<Reminder>(InvalidTriggerTimeFailure(triggerAt: due, now: now));
    }

    final Reminder reminder = Reminder(
      id: idGenerator.newId(),
      text: body,
      triggerAt: due,
      createdAt: now,
    );

    await repository.save(reminder);

    try {
      await scheduler.schedule(
        ScheduledNotification(
          id: reminder.id,
          title: copy.title,
          body: reminder.text,
          triggerAt: reminder.triggerAt,
        ),
      );
    } on Failure catch (failure) {
      return Err<Reminder>(failure);
    }

    return Ok<Reminder>(reminder);
  }
}
