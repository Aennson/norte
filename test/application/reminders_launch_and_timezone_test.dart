import 'package:flutter_test/flutter_test.dart';
import 'package:norte/application/usecases/check_due_reminders.dart';
import 'package:norte/application/usecases/create_voice_reminder.dart';
import 'package:norte/domain/entities/reminder.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/failures/result.dart';
import 'package:norte/domain/ports/time_zone.dart';

import '../fakes/fakes.dart';

/// The zone every one of these cases is pinned to. `America/Sao_Paulo` has no
/// daylight saving since 2019, so a fixed −03:00 is the real offset and not an
/// approximation of one.
const TimeZone saoPaulo = FixedOffsetTimeZone(
  'America/Sao_Paulo',
  Duration(hours: -3),
);

/// S06-IT-01 and S06-IT-02 — the launch check, and the zone a spoken hour
/// belongs to.
void main() {
  late FakeReminderRepository reminders;
  late FakeNotificationScheduler scheduler;
  late FakeClock clock;

  /// 2026-08-07 at 14:00 in São Paulo.
  final DateTime now = DateTime.utc(2026, 8, 7, 17);

  setUp(() {
    reminders = FakeReminderRepository();
    scheduler = FakeNotificationScheduler();
    clock = FakeClock(now);
  });

  tearDown(() => reminders.dispose());

  Reminder reminder(String id, DateTime triggerAt, {bool isFired = false}) =>
      Reminder(
        id: id,
        text: 'lembrete $id',
        triggerAt: triggerAt,
        createdAt: now.subtract(const Duration(days: 1)),
        isFired: isFired,
      );

  group('S06-IT-01: the check when the app opens', () {
    late CheckDueReminders check;

    setUp(() async {
      check = CheckDueReminders(
        repository: reminders,
        scheduler: scheduler,
        clock: clock,
        copy: const FakeReminderNotificationCopy(),
      );

      await reminders.save(
        reminder('overdue-unfired', now.subtract(const Duration(hours: 2))),
      );
      await reminders.save(
        reminder(
          'overdue-fired',
          now.subtract(const Duration(hours: 3)),
          isFired: true,
        ),
      );
      await reminders.save(
        reminder('future', now.add(const Duration(hours: 4))),
      );
    });

    test('only the overdue reminder nobody has seen is delivered', () async {
      final LaunchCheckOutcome outcome = await check();

      expect(outcome.delivered, <String>['overdue-unfired']);
      expect(
        scheduler.scheduled.containsKey('overdue-fired'),
        isFalse,
        reason: 'a reminder already delivered must not shout again',
      );
    });

    test(
      'what was delivered is marked, so the next launch leaves it',
      () async {
        await check();
        expect(reminders.reminders['overdue-unfired']!.isFired, isTrue);

        // The second launch is the assertion that matters: the first one is
        // easy to get right and this is the one a user meets every morning.
        scheduler.reset();
        final LaunchCheckOutcome second = await check();

        expect(second.delivered, isEmpty);
        expect(scheduler.scheduled.keys, <String>['future']);
      },
    );

    test('the future reminder stays scheduled and stays unfired', () async {
      final LaunchCheckOutcome outcome = await check();

      expect(outcome.rescheduled, <String>['future']);
      expect(
        scheduler.scheduled['future']!.triggerAt,
        now.add(const Duration(hours: 4)),
      );
      expect(reminders.reminders['future']!.isFired, isFalse);
    });

    test(
      'a scheduler that refuses leaves the row for the next launch',
      () async {
        scheduler.failWith = const AuthFailure(
          'notifications are not permitted',
        );

        final LaunchCheckOutcome outcome = await check();

        expect(outcome.delivered, isEmpty);
        expect(outcome.rescheduled, isEmpty);
        expect(
          reminders.reminders['overdue-unfired']!.isFired,
          isFalse,
          reason: 'marking it fired would lose it for good',
        );
      },
    );
  });

  group('S06-IT-02: an absolute time belongs to a timezone', () {
    late CreateVoiceReminder createReminder;

    setUp(() {
      createReminder = CreateVoiceReminder(
        repository: reminders,
        scheduler: scheduler,
        clock: clock,
        zone: saoPaulo,
        idGenerator: FakeIdGenerator(),
        copy: const FakeReminderNotificationCopy(),
      );
    });

    test(
      '"tomorrow 09:00" is 09:00 in São Paulo, stored as 12:00 UTC',
      () async {
        final Result<Reminder> created = await createReminder(
          text: 'revisar o PR',
          triggerAt: 'tomorrow 09:00',
        );

        final Reminder stored = created.valueOrNull!;
        // The comparison the sprint asks for is made in UTC…
        expect(stored.triggerAt, DateTime.utc(2026, 8, 8, 12));
        expect(stored.triggerAt.isUtc, isTrue);
        // …and the reading the user would recognise is 09:00 the next day.
        final DateTime local = saoPaulo.localAt(stored.triggerAt);
        expect(<int>[local.year, local.month, local.day], <int>[2026, 8, 8]);
        expect(<int>[local.hour, local.minute], <int>[9, 0]);

        // The platform is asked for the same instant, not the wall reading. A
        // scheduler handed 09:00 with no zone fires three hours early here.
        expect(scheduler.scheduled[stored.id]!.triggerAt, stored.triggerAt);
      },
    );

    test(
      'the same phrase in Rome resolves three hours earlier in UTC',
      () async {
        // Two zones, one utterance, one clock: if the zone were being ignored,
        // these two would agree, and this is the only assertion in the suite
        // that can tell.
        final CreateVoiceReminder inRome = CreateVoiceReminder(
          repository: reminders,
          scheduler: scheduler,
          clock: clock,
          zone: const FixedOffsetTimeZone('Europe/Rome', Duration(hours: 2)),
          idGenerator: FakeIdGenerator(),
          copy: const FakeReminderNotificationCopy(),
        );

        final Reminder roman = (await inRome(
          text: 'revisar o PR',
          triggerAt: 'tomorrow 09:00',
        )).valueOrNull!;

        expect(roman.triggerAt, DateTime.utc(2026, 8, 8, 7));
      },
    );

    test('"today 15:00" is an hour away, not a day', () async {
      final Reminder stored = (await createReminder(
        text: 'daily',
        triggerAt: 'today 15:00',
      )).valueOrNull!;

      expect(stored.triggerAt, DateTime.utc(2026, 8, 7, 18));
      expect(stored.triggerAt.difference(now), const Duration(hours: 1));
    });

    test('"friday 15:00" said on a Friday means the next one', () async {
      // 2026-08-07 is a Friday. "sexta às 15h" said at 14:00 that day is not
      // an hour away — the speaker is naming the Friday to come. Resolving it
      // to today would be right by an hour and wrong by a week.
      expect(saoPaulo.localAt(now).weekday, DateTime.friday);

      final Reminder stored = (await createReminder(
        text: 'retro',
        triggerAt: 'friday 15:00',
      )).valueOrNull!;

      expect(stored.triggerAt, DateTime.utc(2026, 8, 14, 18));
    });
  });
}
