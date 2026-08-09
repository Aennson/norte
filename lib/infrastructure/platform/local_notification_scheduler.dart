import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/failures/failure.dart';
import '../../domain/ports/notification_scheduler.dart';
import 'notification_id.dart';

/// [NotificationScheduler] for Android and iOS
/// (`docs/architecture.md` §8, §12).
///
/// The registration is the **operating system's**, not the app's: it survives
/// the process being killed and, on Android, a reboot. That is the whole
/// reason mobile does not need the Windows adapter's timers, and the reason
/// the launch check is idempotent rather than essential there.
///
/// **The reminder id rides in the payload.** The platform keys on an int
/// ([notificationIdOf]) and the app keys on a string; the payload is what
/// carries the real id back when the user taps the notification, so the deep
/// link opens the reminder rather than guessing from a hash.
class LocalNotificationScheduler implements NotificationScheduler {
  LocalNotificationScheduler({
    required this.plugin,
    required this.channelId,
    required this.channelName,
    this.onTapped,
  });

  final FlutterLocalNotificationsPlugin plugin;

  /// Android notification channel. Created by the plugin on first use.
  final String channelId;

  /// Human-readable channel name, already localized by the caller (BR-11).
  final String channelName;

  /// Called with the reminder id when the user taps a notification.
  final void Function(String reminderId)? onTapped;

  /// Registers the plugin and asks for the permission the platform requires.
  ///
  /// Returns `false` when the user refused. Scheduling still works in the
  /// sense that the registration is accepted; it simply will not be shown, so
  /// the caller is the one that decides what to tell the user.
  Future<bool> initialize({required String androidIcon}) async {
    await plugin.initialize(
      settings: InitializationSettings(
        android: AndroidInitializationSettings(androidIcon),
        iOS: const DarwinInitializationSettings(
          // Asked for explicitly below instead, so that a refusal is an answer
          // this method can return rather than something swallowed at startup.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final String? id = reminderIdFromPayload(response.payload);
        if (id != null) onTapped?.call(id);
      },
    );

    final IOSFlutterLocalNotificationsPlugin? ios = plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }

    final AndroidFlutterLocalNotificationsPlugin? android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return true;
  }

  /// Where the app was launched from a notification, the reminder id that did
  /// it — `null` otherwise.
  ///
  /// Tapping a notification for an app that is not running does not go through
  /// `onDidReceiveNotificationResponse`; it launches the process, and this is
  /// the only place the tap is recorded. Missing it is how a deep link works
  /// perfectly in testing and never once from a cold start.
  Future<String?> launchedByReminder() async {
    final NotificationAppLaunchDetails? details = await plugin
        .getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return reminderIdFromPayload(details.notificationResponse?.payload);
  }

  @override
  Future<void> schedule(ScheduledNotification notification) async {
    try {
      await plugin.zonedSchedule(
        id: notificationIdOf(notification.id),
        title: notification.title,
        body: notification.body,
        payload: payloadFor(notification),
        scheduledDate: tz.TZDateTime.from(notification.triggerAt, tz.local),
        // The port says a past instant must fire rather than be dropped, and
        // the plugin refuses a past `scheduledDate` outright — so an overdue
        // reminder is shown immediately instead. This is the mobile half of
        // §12's check on launch.
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    } on PlatformException catch (error) {
      throw _asFailure(error);
    } on ArgumentError {
      // `zonedSchedule` throws this for an instant already past. The port says
      // such a notification fires as soon as the platform allows rather than
      // being dropped, so it is shown now — which is also the mobile half of
      // §12's check on launch.
      await _showNow(notification);
    }
  }

  Future<void> _showNow(ScheduledNotification notification) async {
    await plugin.show(
      id: notificationIdOf(notification.id),
      title: notification.title,
      body: notification.body,
      payload: payloadFor(notification),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  @override
  Future<void> cancel(String id) => plugin.cancel(id: notificationIdOf(id));

  @override
  Future<List<ScheduledNotification>> pending() async {
    final List<PendingNotificationRequest> requests = await plugin
        .pendingNotificationRequests();
    final List<ScheduledNotification> all =
        <ScheduledNotification>[
          for (final PendingNotificationRequest request in requests)
            if (_decode(request.payload)
                case final Map<String, Object?> payload)
              ScheduledNotification(
                id: payload['id']! as String,
                title: request.title ?? '',
                body: request.body ?? '',
                triggerAt: DateTime.parse(payload['at']! as String),
              ),
        ]..sort(
          (ScheduledNotification a, ScheduledNotification b) =>
              a.triggerAt.compareTo(b.triggerAt),
        );
    return all;
  }

  /// The payload the platform hands back on a tap.
  ///
  /// It carries the reminder id **and** the instant, because the platform
  /// reports neither: `pendingNotificationRequests` returns the int key and
  /// the text, and the port promises a list ordered by `triggerAt`. Writing
  /// the time into the payload is what lets that promise be kept honestly
  /// rather than by inventing a value nobody could act on.
  static String payloadFor(ScheduledNotification notification) =>
      jsonEncode(<String, String>{
        'id': notification.id,
        'at': notification.triggerAt.toUtc().toIso8601String(),
      });

  /// The reminder id inside [payload], or `null` when there is not one.
  ///
  /// Tolerant of a bare id: an app updated over a version that wrote the id
  /// alone still has those notifications registered with the platform, and a
  /// tap on one should open the reminder rather than do nothing.
  static String? reminderIdFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;

    final Object? decoded = _json(payload);
    // A payload that *is* an object is one this class wrote, so its `id` is
    // the only answer — falling back to the raw text here would hand the
    // router a JSON document as a reminder id.
    if (decoded is Map<String, Object?>) {
      final Object? id = decoded['id'];
      return id is String && id.isNotEmpty ? id : null;
    }
    return payload;
  }

  static Map<String, Object?>? _decode(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    final Object? decoded = _json(payload);
    if (decoded is! Map<String, Object?>) return null;
    return decoded['id'] is String && decoded['at'] is String ? decoded : null;
  }

  static Object? _json(String payload) {
    try {
      return jsonDecode(payload);
    } on FormatException {
      return null;
    }
  }

  Failure _asFailure(PlatformException error) {
    final String code = error.code.toLowerCase();
    if (code.contains('permission') || code.contains('denied')) {
      return AuthFailure('the platform refused to notify: ${error.code}');
    }
    return EngineFailure('the platform refused to notify: ${error.code}');
  }
}
