import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/notification_scheduler.dart';
import 'package:norte/infrastructure/platform/local_notification_scheduler.dart';
import 'package:norte/infrastructure/platform/notification_id.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _FakeNotificationDetails extends Fake implements NotificationDetails {}

class _FakeTZDateTime extends Fake implements tz.TZDateTime {}

/// `LocalNotificationScheduler` — the part of it that is not a platform
/// channel.
///
/// Not a documented sprint case — added under `docs/project-rules.md` §5.4,
/// and squarely because of `sprint-05` §5: the one adapter nobody could test
/// was the one that dropped the API key. Everything reachable without a device
/// is reachable here — which id the plugin is given, what the payload carries,
/// what happens when the plugin refuses a time already past, and how a
/// platform error becomes a [Failure] the UI can act on.
void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    registerFallbackValue(_FakeNotificationDetails());
    registerFallbackValue(_FakeTZDateTime());
    registerFallbackValue(AndroidScheduleMode.exactAllowWhileIdle);
  });

  late _MockPlugin plugin;
  late LocalNotificationScheduler scheduler;

  final ScheduledNotification notification = ScheduledNotification(
    id: 'reminder-7',
    title: 'Lembrete',
    body: 'responder o e-mail',
    triggerAt: DateTime.utc(2026, 8, 8, 18),
  );

  setUp(() {
    plugin = _MockPlugin();
    scheduler = LocalNotificationScheduler(
      plugin: plugin,
      channelId: 'norte.reminders',
      channelName: 'Norte',
    );
  });

  group('schedule', () {
    test('the plugin is given the derived id and the full payload', () async {
      when(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      await scheduler.schedule(notification);

      final VerificationResult call = verify(
        () => plugin.zonedSchedule(
          id: captureAny(named: 'id'),
          scheduledDate: captureAny(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          title: captureAny(named: 'title'),
          body: captureAny(named: 'body'),
          payload: captureAny(named: 'payload'),
        ),
      );
      final List<Object?> captured = call.captured;

      expect(captured[0], notificationIdOf('reminder-7'));
      // The instant, not the wall reading: `tz.TZDateTime.from` keeps the
      // moment and changes only how it is expressed.
      expect(
        (captured[1]! as tz.TZDateTime).toUtc(),
        DateTime.utc(2026, 8, 8, 18),
      );
      expect(captured[2], 'Lembrete');
      expect(captured[3], 'responder o e-mail');
      expect(
        LocalNotificationScheduler.reminderIdFromPayload(
          captured[4]! as String,
        ),
        'reminder-7',
      );
    });

    test('a time the plugin refuses as past is shown immediately', () async {
      // The port says a past instant fires as soon as the platform allows and
      // is never silently dropped. `zonedSchedule` refuses one outright, so
      // this branch is the only thing standing between an overdue reminder and
      // silence.
      when(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      ).thenThrow(ArgumentError('scheduledDate must be in the future'));
      when(
        () => plugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      await scheduler.schedule(notification);

      verify(
        () => plugin.show(
          id: notificationIdOf('reminder-7'),
          title: 'Lembrete',
          body: 'responder o e-mail',
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });

    test(
      'a denied permission surfaces as AuthFailure, not as a crash',
      () async {
        // The two failures the UI treats differently: one sends the user to the
        // system settings, the other is worth a retry.
        when(
          () => plugin.zonedSchedule(
            id: any(named: 'id'),
            scheduledDate: any(named: 'scheduledDate'),
            notificationDetails: any(named: 'notificationDetails'),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            payload: any(named: 'payload'),
          ),
        ).thenThrow(PlatformException(code: 'permission_denied'));

        expect(
          () => scheduler.schedule(notification),
          throwsA(isA<AuthFailure>()),
        );
      },
    );

    test('any other platform error is an EngineFailure', () async {
      when(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      ).thenThrow(PlatformException(code: 'invalid_channel'));

      expect(
        () => scheduler.schedule(notification),
        throwsA(isA<EngineFailure>()),
      );
    });
  });

  test('cancel passes the same derived id', () async {
    when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((_) async {});

    await scheduler.cancel('reminder-7');

    verify(() => plugin.cancel(id: notificationIdOf('reminder-7'))).called(1);
  });

  group('pending', () {
    test('the payload is what restores the id and the instant', () async {
      when(() => plugin.pendingNotificationRequests()).thenAnswer(
        (_) async => <PendingNotificationRequest>[
          PendingNotificationRequest(
            notificationIdOf('later'),
            'Lembrete',
            'depois',
            LocalNotificationScheduler.payloadFor(
              ScheduledNotification(
                id: 'later',
                title: 'Lembrete',
                body: 'depois',
                triggerAt: DateTime.utc(2026, 8, 9),
              ),
            ),
          ),
          PendingNotificationRequest(
            notificationIdOf('sooner'),
            'Lembrete',
            'antes',
            LocalNotificationScheduler.payloadFor(
              ScheduledNotification(
                id: 'sooner',
                title: 'Lembrete',
                body: 'antes',
                triggerAt: DateTime.utc(2026, 8, 8),
              ),
            ),
          ),
        ],
      );

      final List<ScheduledNotification> pending = await scheduler.pending();

      // Ordered by triggerAt, as the port promises — which is only possible
      // because the instant rides in the payload.
      expect(pending.map((ScheduledNotification n) => n.id), <String>[
        'sooner',
        'later',
      ]);
      expect(pending.first.triggerAt, DateTime.utc(2026, 8, 8));
    });

    test(
      'a registration this class did not write is skipped, not guessed at',
      () async {
        when(() => plugin.pendingNotificationRequests()).thenAnswer(
          (_) async => <PendingNotificationRequest>[
            PendingNotificationRequest(1, 'other', 'app', null),
          ],
        );

        expect(await scheduler.pending(), isEmpty);
      },
    );
  });

  group('launchedByReminder', () {
    test('nothing when the app was not launched by a notification', () async {
      when(
        () => plugin.getNotificationAppLaunchDetails(),
      ).thenAnswer((_) async => const NotificationAppLaunchDetails(false));

      expect(await scheduler.launchedByReminder(), isNull);
    });

    test('the reminder id when it was', () async {
      when(() => plugin.getNotificationAppLaunchDetails()).thenAnswer(
        (_) async => NotificationAppLaunchDetails(
          true,
          notificationResponse: NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: LocalNotificationScheduler.payloadFor(notification),
          ),
        ),
      );

      expect(await scheduler.launchedByReminder(), 'reminder-7');
    });
  });
}
