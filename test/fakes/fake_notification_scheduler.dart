import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/notification_scheduler.dart';

/// In-memory [NotificationScheduler] that records what was scheduled and lets
/// a test fire a notification by hand (`docs/testing-strategy.md` §3).
class FakeNotificationScheduler implements NotificationScheduler {
  /// Notifications currently pending, keyed by id.
  final Map<String, ScheduledNotification> scheduled =
      <String, ScheduledNotification>{};

  /// Ids passed to [cancel], in call order.
  final List<String> cancelled = <String>[];

  /// Ids delivered through [fire], in call order.
  final List<String> fired = <String>[];

  /// When set, the next call to [schedule] throws it instead of recording.
  /// Typically an [AuthFailure] standing in for a denied permission.
  Failure? failWith;

  @override
  Future<void> schedule(ScheduledNotification notification) async {
    final Failure? failure = failWith;
    if (failure != null) throw failure;
    // Replacing by id is part of the port contract — never double-fire.
    scheduled[notification.id] = notification;
  }

  @override
  Future<void> cancel(String id) async {
    cancelled.add(id);
    scheduled.remove(id);
  }

  @override
  Future<List<ScheduledNotification>> pending() async {
    final List<ScheduledNotification> all = scheduled.values.toList()
      ..sort((a, b) => a.triggerAt.compareTo(b.triggerAt));
    return all;
  }

  /// Simulates the platform delivering [id], removing it from [scheduled].
  ///
  /// Returns the notification that fired, or `null` when nothing was pending
  /// under that id.
  ScheduledNotification? fire(String id) {
    final ScheduledNotification? notification = scheduled.remove(id);
    if (notification != null) fired.add(id);
    return notification;
  }

  /// Forgets every recorded interaction.
  void reset() {
    scheduled.clear();
    cancelled.clear();
    fired.clear();
    failWith = null;
  }
}
