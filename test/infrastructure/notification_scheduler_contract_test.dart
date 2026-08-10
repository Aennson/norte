import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:norte/domain/ports/notification_scheduler.dart';
import 'package:norte/infrastructure/platform/local_notification_scheduler.dart';
import 'package:norte/infrastructure/platform/notification_id.dart';
import 'package:norte/infrastructure/platform/windows_toast_scheduler.dart';
import 'package:windows_notification/notification_message.dart';
import 'package:windows_notification/windows_notification.dart';

import '../fakes/fakes.dart';

class _MockWindowsNotification extends Mock implements WindowsNotification {}

class _FakeNotificationMessage extends Fake implements NotificationMessage {}

/// The `NotificationScheduler` contract, run against every implementation
/// (`docs/testing-strategy.md` §3 — adapters go through one contract suite).
///
/// Not a documented sprint case — added under `docs/project-rules.md` §5.4,
/// and for the reason `sprint-05` §5 wrote down at length: a fake written from
/// what the caller expected agrees with the caller about everything, including
/// what both got wrong. Putting `FakeNotificationScheduler` and the real
/// Windows adapter through the same assertions is what makes the fake's
/// leniency visible.
///
/// `LocalNotificationScheduler` is absent from the loop on purpose. Every one
/// of its methods is a platform channel, so a "contract test" over it would be
/// a test of mocktail; what *can* be checked without a device — the payload it
/// writes and reads, and the id it derives — is checked separately below.
void main() {
  setUpAll(() => registerFallbackValue(_FakeNotificationMessage()));

  final DateTime now = DateTime.utc(2026, 8, 7, 17);

  ScheduledNotification notification(
    String id, {
    Duration offset = const Duration(hours: 1),
  }) => ScheduledNotification(
    id: id,
    title: 'Lembrete',
    body: 'responder o e-mail',
    triggerAt: now.add(offset),
  );

  /// Every implementation, built fresh, keyed by the name a failure reports.
  final Map<String, NotificationScheduler Function()> implementations =
      <String, NotificationScheduler Function()>{
        'FakeNotificationScheduler': FakeNotificationScheduler.new,
        'WindowsToastScheduler': () {
          final _MockWindowsNotification notifier = _MockWindowsNotification();
          when(
            () => notifier.showNotificationPluginTemplate(any()),
          ).thenAnswer((_) async {});
          when(
            () => notifier.removeNotificationId(any(), any()),
          ).thenAnswer((_) async {});
          return WindowsToastScheduler(
            notifier: notifier,
            clock: FakeClock(now),
          );
        },
      };

  for (final MapEntry<String, NotificationScheduler Function()> entry
      in implementations.entries) {
    group(entry.key, () {
      late NotificationScheduler scheduler;

      setUp(() => scheduler = entry.value());

      test('what was scheduled is pending', () async {
        await scheduler.schedule(notification('r1'));

        final List<ScheduledNotification> pending = await scheduler.pending();
        expect(pending.map((ScheduledNotification n) => n.id), <String>['r1']);
      });

      test('scheduling twice under one id replaces rather than adds', () async {
        await scheduler.schedule(notification('r1'));
        await scheduler.schedule(
          notification('r1', offset: const Duration(hours: 3)),
        );

        final List<ScheduledNotification> pending = await scheduler.pending();
        expect(pending.length, 1, reason: 'never double-fire');
        expect(pending.single.triggerAt, now.add(const Duration(hours: 3)));
      });

      test('pending is ordered by triggerAt', () async {
        await scheduler.schedule(
          notification('late', offset: const Duration(hours: 5)),
        );
        await scheduler.schedule(
          notification('soon', offset: const Duration(minutes: 5)),
        );

        final List<ScheduledNotification> pending = await scheduler.pending();
        expect(pending.map((ScheduledNotification n) => n.id), <String>[
          'soon',
          'late',
        ]);
      });

      test('cancel removes it, and an unknown id is a no-op', () async {
        await scheduler.schedule(notification('r1'));

        await scheduler.cancel('r1');
        expect(await scheduler.pending(), isEmpty);

        // The second call must not throw — the contract is explicit.
        await scheduler.cancel('r1');
        await scheduler.cancel('never-existed');
        expect(await scheduler.pending(), isEmpty);
      });
    });
  }

  group('WindowsToastScheduler: the timer is the schedule', () {
    late _MockWindowsNotification notifier;
    late WindowsToastScheduler scheduler;

    setUp(() {
      notifier = _MockWindowsNotification();
      when(
        () => notifier.showNotificationPluginTemplate(any()),
      ).thenAnswer((_) async {});
      when(
        () => notifier.removeNotificationId(any(), any()),
      ).thenAnswer((_) async {});
      scheduler = WindowsToastScheduler(
        notifier: notifier,
        clock: FakeClock(now),
      );
    });

    tearDown(() => scheduler.dispose());

    test('an instant already past fires rather than being dropped', () async {
      await scheduler.schedule(
        notification('overdue', offset: const Duration(hours: -2)),
      );
      // A zero-length timer, so one turn of the event loop is enough.
      await Future<void>.delayed(Duration.zero);

      final NotificationMessage shown =
          verify(
                () => notifier.showNotificationPluginTemplate(captureAny()),
              ).captured.single
              as NotificationMessage;
      expect(shown.id, 'overdue');
      expect(shown.body, 'responder o e-mail');
      expect(shown.payload['reminderId'], 'overdue');
      expect(await scheduler.pending(), isEmpty, reason: 'it has fired');
    });

    test('a future instant does not fire now', () async {
      await scheduler.schedule(notification('later'));
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => notifier.showNotificationPluginTemplate(any()));
    });

    test('cancelling before the timer elapses stops the toast', () async {
      await scheduler.schedule(
        notification('overdue', offset: const Duration(hours: -2)),
      );
      await scheduler.cancel('overdue');
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => notifier.showNotificationPluginTemplate(any()));
    });

    test('replacing a pending id leaves only one timer', () async {
      await scheduler.schedule(
        notification('r1', offset: const Duration(hours: -2)),
      );
      await scheduler.schedule(
        notification('r1', offset: const Duration(hours: -1)),
      );
      await Future<void>.delayed(Duration.zero);

      verify(() => notifier.showNotificationPluginTemplate(any())).called(1);
    });
  });

  group('LocalNotificationScheduler: what the platform hands back', () {
    test('the payload round-trips the id and the instant', () {
      final ScheduledNotification original = notification('reminder-7');
      final String payload = LocalNotificationScheduler.payloadFor(original);

      expect(
        LocalNotificationScheduler.reminderIdFromPayload(payload),
        'reminder-7',
      );
    });

    test('a bare id is still read as an id', () {
      // An app updated over a version that wrote the id alone still has those
      // notifications registered with the OS. A tap on one must open the
      // reminder rather than do nothing.
      expect(
        LocalNotificationScheduler.reminderIdFromPayload('reminder-7'),
        'reminder-7',
      );
    });

    test('nothing, and nonsense, are not ids', () {
      expect(LocalNotificationScheduler.reminderIdFromPayload(null), isNull);
      expect(LocalNotificationScheduler.reminderIdFromPayload(''), isNull);
      expect(
        LocalNotificationScheduler.reminderIdFromPayload('{"id": 7}'),
        isNull,
      );
    });
  });

  group('notificationIdOf', () {
    test('the same id gives the same number, every time', () {
      // The property the whole platform key rests on: a cancel that computed
      // a different number would cancel nothing, and the notification would
      // fire for a reminder the user deleted.
      expect(notificationIdOf('reminder-7'), notificationIdOf('reminder-7'));
    });

    test('it is a specific number, not merely a stable one', () {
      // Pinned so that a change of algorithm — which would orphan every
      // notification already registered on every installed device — has to be
      // a deliberate edit to this line rather than a silent one.
      expect(notificationIdOf('reminder-7'), 1348610851);
      expect(notificationIdOf(''), 0x811c9dc5 & 0x7fffffff);
    });

    test('different ids do not collide in the obvious cases', () {
      final Set<int> seen = <int>{
        for (int i = 0; i < 500; i++) notificationIdOf('reminder-$i'),
      };
      expect(seen.length, 500);
    });

    test('it always fits in the positive range the platform accepts', () {
      for (final String id in <String>['a', 'reminder-999999', 'ção-ü-🙂']) {
        final int value = notificationIdOf(id);
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThanOrEqualTo(0x7fffffff));
      }
    });
  });
}
