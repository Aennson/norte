import 'package:flutter_test/flutter_test.dart';
import 'package:norte/application/usecases/cancel_reminder.dart';
import 'package:norte/application/usecases/create_voice_reminder.dart';
import 'package:norte/application/voice/intent_parser.dart';
import 'package:norte/domain/entities/intent_context.dart';
import 'package:norte/domain/entities/reminder.dart';
import 'package:norte/domain/entities/voice_intent.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/failures/result.dart';
import 'package:norte/domain/ports/notification_scheduler.dart';
import 'package:norte/domain/ports/time_zone.dart';

import '../fakes/fakes.dart';

/// S06-UT-01..04 — the reminder pipeline, its temporal guard, its cancellation
/// and BR-06.
void main() {
  /// The sprint's clock: 2026-08-07 at 14:00 **local**, in a zone that is not
  /// UTC. A test whose zone is UTC cannot tell a use case that applies the
  /// zone from one that ignores it, and applying it is the whole of S06-IT-02.
  const TimeZone saoPaulo = FixedOffsetTimeZone(
    'America/Sao_Paulo',
    Duration(hours: -3),
  );
  final DateTime now = DateTime.utc(2026, 8, 7, 17); // 14:00 in São Paulo

  late FakeReminderRepository reminders;
  late FakeNotificationScheduler scheduler;
  late FakeClock clock;
  late CreateVoiceReminder createReminder;

  setUp(() {
    reminders = FakeReminderRepository();
    scheduler = FakeNotificationScheduler();
    clock = FakeClock(now);
    createReminder = CreateVoiceReminder(
      repository: reminders,
      scheduler: scheduler,
      clock: clock,
      zone: saoPaulo,
      idGenerator: FakeIdGenerator(),
      copy: const FakeReminderNotificationCopy(),
    );
  });

  tearDown(() => reminders.dispose());

  group('S06-UT-01: creation with a relative date', () {
    /// The spoken sentence, and the intent the model returns for it. The
    /// fixture is the **raw model answer**, run through the real `IntentCodec`
    /// by `FakeAiEngine` — a hand-built `VoiceIntent` would prove the use case
    /// works on a value this test made up, not on one the codec can produce.
    const String utterance =
        'me lembra daqui a vinte minutos de responder o e-mail';
    const String answer = '''
{"intent": "createReminder",
 "slots": {"title": null, "description": null, "status": null,
           "priority": null, "dueDate": null, "taskRef": null,
           "change": null, "comment": null, "issueKey": null,
           "transition": null, "text": "responder o e-mail",
           "triggerAt": "+20m"},
 "confidence": 0.94}''';

    test(
      'the utterance becomes a reminder that is stored and scheduled',
      () async {
        final FakeAiEngine engine = FakeAiEngine(
          intents: <String, String>{utterance: answer},
        );
        final Result<VoiceIntent> parsed = await IntentParser(
          engine: engine,
        ).parse(utterance, context: const IntentContext(locale: 'pt-BR'));
        final VoiceIntent intent = parsed.valueOrNull!;
        expect(intent.type, IntentType.createReminder);

        final Result<Reminder> created = await createReminder(
          text: intent.slotText('text')!,
          triggerAt: intent.slotText('triggerAt')!,
        );

        final Reminder reminder = created.valueOrNull!;
        expect(reminder.text, 'responder o e-mail');
        // 14:20 São Paulo, which is 17:20 UTC — the stored instant.
        expect(reminder.triggerAt, DateTime.utc(2026, 8, 7, 17, 20));
        expect(saoPaulo.localAt(reminder.triggerAt).hour, 14);
        expect(saoPaulo.localAt(reminder.triggerAt).minute, 20);
        expect(reminders.all, <Reminder>[reminder]);

        final ScheduledNotification? notification =
            scheduler.scheduled[reminder.id];
        expect(notification, isNotNull, reason: 'scheduled under the row id');
        expect(notification!.triggerAt, reminder.triggerAt);
        expect(notification.body, 'responder o e-mail');
        // Asked of the port, never spelled in the use case (BR-11).
        expect(notification.title, '«reminder-title»');
      },
    );

    test(
      'the offset is read against the injected clock, not wall time',
      () async {
        clock.advance(const Duration(hours: 5));

        final Reminder reminder = (await createReminder(
          text: 'algo',
          triggerAt: '+1h',
        )).valueOrNull!;

        expect(reminder.triggerAt, DateTime.utc(2026, 8, 7, 23));
      },
    );
  });

  group('S06-UT-02: a past date is rejected', () {
    test(
      '13:00 today, said at 14:00, persists and schedules nothing',
      () async {
        final Result<Reminder> created = await createReminder(
          text: 'responder o e-mail',
          triggerAt: 'today 13:00',
        );

        final Failure failure = created.failureOrNull!;
        expect(failure, isA<InvalidTriggerTimeFailure>());
        // 13:00 São Paulo is 16:00 UTC — the failure carries the resolved
        // instant, so the screen can say which time it judged.
        expect(
          (failure as InvalidTriggerTimeFailure).triggerAt,
          DateTime.utc(2026, 8, 7, 16),
        );
        expect(failure.now, now);

        expect(reminders.saves, 0, reason: 'nothing persisted');
        expect(scheduler.scheduled, isEmpty, reason: 'nothing scheduled');
      },
    );

    test(
      '"now" exactly is refused too — a reminder must have a future',
      () async {
        final Result<Reminder> created = await createReminder(
          text: 'algo',
          triggerAt: now.toIso8601String(),
        );

        expect(created.failureOrNull, isA<InvalidTriggerTimeFailure>());
        expect(reminders.saves, 0);
      },
    );

    test(
      'an unreadable slot is a ValidationFailure, not a past time',
      () async {
        // The two are different for the user: one means "say another time", the
        // other "say it another way", and a screen that showed the same message
        // for both would send half its users down the wrong path.
        final Result<Reminder> created = await createReminder(
          text: 'algo',
          triggerAt: 'sometime after lunch',
        );

        final Failure failure = created.failureOrNull!;
        expect(failure, isA<ValidationFailure>());
        expect((failure as ValidationFailure).field, 'triggerAt');
        expect(reminders.saves, 0);
        expect(scheduler.scheduled, isEmpty);
      },
    );

    test('a blank text is refused before the clock is even read', () async {
      final Result<Reminder> created = await createReminder(
        text: '   ',
        triggerAt: '+20m',
      );

      expect((created.failureOrNull! as ValidationFailure).field, 'text');
      expect(reminders.saves, 0);
      expect(scheduler.scheduled, isEmpty);
    });
  });

  group('S06-UT-03: cancellation reaches both halves', () {
    test('the row goes and the scheduler is told the same id', () async {
      final Reminder reminder = (await createReminder(
        text: 'ligar para a Samara',
        triggerAt: '+2h',
      )).valueOrNull!;
      expect(scheduler.scheduled.containsKey(reminder.id), isTrue);

      final Result<void> cancelled = await CancelReminder(
        repository: reminders,
        scheduler: scheduler,
      )(reminder.id);

      expect(cancelled, isA<Ok<void>>());
      expect(reminders.reminders.containsKey(reminder.id), isFalse);
      expect(scheduler.cancelled, <String>[reminder.id]);
      expect(scheduler.scheduled, isEmpty);
    });

    test('cancelling something already gone is not an error', () async {
      final Result<void> cancelled = await CancelReminder(
        repository: reminders,
        scheduler: scheduler,
      )('no-such-reminder');

      expect(cancelled, isA<Ok<void>>());
      expect(scheduler.cancelled, <String>['no-such-reminder']);
    });
  });

  group('S06-UT-04: BR-06 — the audio never outlives the transcription', () {
    test('on success, nothing carries the audio note', () async {
      final Reminder created = (await createReminder(
        text: 'responder o e-mail',
        triggerAt: '+5m',
      )).valueOrNull!;

      expect(created.sourceAudioNote, isNull);
      expect(reminders.reminders[created.id]!.sourceAudioNote, isNull);
      // Nor does it reach the platform, which is the one place a leak would
      // survive the app being closed.
      expect(scheduler.scheduled[created.id]!.body, 'responder o e-mail');
    });

    test('on a rejected parse, nothing is written at all', () async {
      final Result<Reminder> created = await createReminder(
        text: 'responder o e-mail',
        triggerAt: 'depois do almoço',
      );

      expect(created.failureOrNull, isA<ValidationFailure>());
      expect(reminders.reminders, isEmpty);
      expect(scheduler.scheduled, isEmpty);
    });
  });

  group('a refused schedule keeps the reminder', () {
    test('the permission failure surfaces and the row survives it', () async {
      // Not a documented case; it pins the decision in the use case's dartdoc.
      // Discarding what the user said because the OS refused a toast would
      // lose the one thing the app could still have shown them.
      scheduler.failWith = const AuthFailure('notifications are not permitted');

      final Result<Reminder> created = await createReminder(
        text: 'pagar a conta',
        triggerAt: '+1d',
      );

      expect(created.failureOrNull, isA<AuthFailure>());
      expect(reminders.all.single.text, 'pagar a conta');
    });
  });
}
