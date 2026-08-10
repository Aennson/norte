import 'dart:async';

import 'package:windows_notification/notification_message.dart';
import 'package:windows_notification/windows_notification.dart';

import '../../domain/ports/clock.dart';
import '../../domain/ports/notification_scheduler.dart';

/// [NotificationScheduler] for Windows — a WinRT toast, fired by a timer this
/// process owns (`docs/architecture.md` §8, §12).
///
/// **Windows has no scheduling here at all.** `windows_notification` shows a
/// toast now; there is no "show this in two hours" to hand the OS, and nothing
/// registered survives the app closing. The port's contract is honoured within
/// a session by a [Timer] per pending notification, and *across* sessions by
/// `CheckDueReminders`, which re-registers everything on launch and delivers
/// what fell due while Norte was shut. Neither half is optional: the timers
/// alone lose every reminder at exit, and the launch check alone would only
/// notify people who happened to restart the app.
///
/// **A past instant fires immediately**, as the port requires — a zero-length
/// timer rather than a special case, so the delivery path is the same one.
class WindowsToastScheduler implements NotificationScheduler {
  WindowsToastScheduler({
    required this.notifier,
    required this.clock,
    this.group = 'reminders',
    this.onTapped,
  });

  /// The plugin. Injected so a test can drive the timer logic without WinRT.
  final WindowsNotification notifier;

  final Clock clock;

  /// Toast group every reminder is filed under, so cancelling one cannot
  /// remove somebody else's notification.
  final String group;

  /// Called with the reminder id when the user clicks a toast.
  final void Function(String reminderId)? onTapped;

  final Map<String, ScheduledNotification> _pending =
      <String, ScheduledNotification>{};
  final Map<String, Timer> _timers = <String, Timer>{};

  /// Registers the tap callback.
  Future<void> initialize() async {
    await notifier.initNotificationCallBack((
      NotificationCallBackDetails details,
    ) {
      // Only a click. A toast that timed out or was swiped away is the user
      // declining to act, and opening the app for it would be the opposite of
      // what they did.
      if (details.eventType != EventType.onActivate) return;
      final Object? id = details.message.payload['reminderId'];
      if (id is String && id.isNotEmpty) onTapped?.call(id);
    });
  }

  @override
  Future<void> schedule(ScheduledNotification notification) async {
    // Replacing by id is the port's contract, and on this platform it is also
    // what stops two timers racing to show the same toast twice.
    _timers.remove(notification.id)?.cancel();
    _pending[notification.id] = notification;

    final Duration wait = notification.triggerAt.difference(
      clock.now().toUtc(),
    );
    _timers[notification.id] = Timer(
      wait.isNegative ? Duration.zero : wait,
      () => unawaited(_fire(notification)),
    );
  }

  @override
  Future<void> cancel(String id) async {
    _timers.remove(id)?.cancel();
    final bool wasPending = _pending.remove(id) != null;
    // Only if it might already be on screen: `removeNotificationId` on
    // something never shown is harmless, but asking WinRT nothing is cheaper
    // and an unknown id is a no-op by the port's contract either way.
    if (wasPending) await notifier.removeNotificationId(id, group);
  }

  @override
  Future<List<ScheduledNotification>> pending() async {
    final List<ScheduledNotification> all = _pending.values.toList()
      ..sort(
        (ScheduledNotification a, ScheduledNotification b) =>
            a.triggerAt.compareTo(b.triggerAt),
      );
    return all;
  }

  /// Cancels every timer. Called when the app shuts down cleanly; the launch
  /// check is what covers the times it does not.
  void dispose() {
    for (final Timer timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _pending.clear();
  }

  Future<void> _fire(ScheduledNotification notification) async {
    _timers.remove(notification.id);
    _pending.remove(notification.id);
    await notifier.showNotificationPluginTemplate(
      NotificationMessage.fromPluginTemplate(
        notification.id,
        notification.title,
        notification.body,
        group: group,
        payload: <String, String>{'reminderId': notification.id},
        // What the app is handed when the toast is clicked, so a reminder can
        // be opened from a toast raised while Norte was in the background.
        launch: 'norte://reminders/${notification.id}',
      ),
    );
  }
}
