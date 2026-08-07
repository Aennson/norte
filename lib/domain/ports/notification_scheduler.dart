import '../failures/failure.dart';

/// A notification the platform has been asked to deliver at a future instant.
///
/// Carries only what every platform can express — the reminder entity itself
/// arrives in Sprint 06 and is never handed to the scheduler.
class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.triggerAt,
  });

  /// Stable identifier, used to cancel or replace the schedule.
  final String id;

  /// Already localized by the caller (BR-11).
  final String title;

  /// Already localized by the caller (BR-11).
  final String body;

  /// When the platform should fire the notification.
  final DateTime triggerAt;
}

/// Schedules local notifications.
///
/// Implemented per platform (`docs/architecture.md` §8):
/// `flutter_local_notifications` on Android/iOS, WinRT toast on Windows.
///
/// **Contract**
/// * [schedule] replaces any pending notification carrying the same
///   [ScheduledNotification.id] — scheduling twice never double-fires.
/// * [cancel] on an unknown id is a no-op, not an error.
/// * A [ScheduledNotification.triggerAt] in the past fires as soon as the
///   platform allows; implementations must not silently drop it.
/// * Failures surface as [Failure] — typically [AuthFailure] when the user
///   denied the notification permission.
abstract interface class NotificationScheduler {
  /// Registers [notification] with the platform.
  Future<void> schedule(ScheduledNotification notification);

  /// Cancels the pending notification with [id], if any.
  Future<void> cancel(String id);

  /// Everything currently scheduled, ordered by
  /// [ScheduledNotification.triggerAt].
  Future<List<ScheduledNotification>> pending();
}
