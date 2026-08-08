import 'package:flutter_test/flutter_test.dart';
import 'package:norte/application/usecases/create_reminder.dart';
import 'package:norte/domain/entities/reminder.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/failures/result.dart';

import '../fakes/fakes.dart';

/// The Sprint 05 reminder stub (`sprint-05` scope note, DEC-024).
///
/// Not a documented sprint case — added under `docs/project-rules.md` §5.4.
/// What it pins is the **boundary**: which `triggerAt` forms this sprint
/// claims, and which it hands to Sprint 06 with a failing case attached.
void main() {
  late FakeReminderRepository reminders;
  late FakeClock clock;
  late CreateReminder createReminder;

  final DateTime now = DateTime.utc(2026, 8, 8, 14);

  setUp(() {
    reminders = FakeReminderRepository();
    clock = FakeClock(now);
    createReminder = CreateReminder(
      repository: reminders,
      clock: clock,
      idGenerator: FakeIdGenerator(),
    );
  });

  tearDown(() => reminders.dispose());

  group('what Sprint 05 resolves', () {
    test('a relative offset is resolved against the injected clock', () async {
      final Result<Reminder> created = await createReminder(
        text: 'olhar o build',
        triggerAt: '+20m',
      );

      final Reminder reminder = created.valueOrNull!;
      expect(reminder.text, 'olhar o build');
      expect(reminder.triggerAt, now.add(const Duration(minutes: 20)));
      expect(reminders.all, <Reminder>[reminder]);
    });

    test('seconds, hours and days are read the same way', () async {
      final Map<String, Duration> forms = <String, Duration>{
        '+90s': Duration(seconds: 90),
        '+1h': Duration(hours: 1),
        '+2d': Duration(days: 2),
      };

      for (final MapEntry<String, Duration> form in forms.entries) {
        final Result<Reminder> created = await createReminder(
          text: 'algo',
          triggerAt: form.key,
        );
        expect(created.valueOrNull!.triggerAt, now.add(form.value));
      }
    });

    test('an ISO 8601 instant is taken as it stands, in UTC', () async {
      final Result<Reminder> created = await createReminder(
        text: 'fechar o ponto',
        triggerAt: '2026-08-08T18:00:00Z',
      );

      expect(created.valueOrNull!.triggerAt, DateTime.utc(2026, 8, 8, 18));
    });
  });

  group('what Sprint 06 owns', () {
    test('a wall-clock phrase is refused rather than guessed at', () async {
      // Resolving these needs the device timezone and a weekday calendar —
      // S06-IT-02. Implementing it here would be doing a future sprint's
      // work badly; refusing leaves Sprint 06 a case it has to make pass.
      for (final String phrase in <String>[
        'today 15:00',
        'tomorrow 09:00',
        'friday 15:00',
      ]) {
        final Result<Reminder> created = await createReminder(
          text: 'algo',
          triggerAt: phrase,
        );

        expect(created.failureOrNull, isA<ValidationFailure>(), reason: phrase);
        expect(
          (created.failureOrNull! as ValidationFailure).field,
          'triggerAt',
        );
      }

      expect(reminders.saves, 0, reason: 'nothing was written');
    });
  });

  group('validation happens before the repository is touched', () {
    test('a blank text is refused and nothing is written', () async {
      final Result<Reminder> created = await createReminder(
        text: '   ',
        triggerAt: '+20m',
      );

      expect((created.failureOrNull! as ValidationFailure).field, 'text');
      expect(reminders.saves, 0);
    });
  });

  group('BR-06', () {
    test('nothing scheduled, and no audio note survives the write', () async {
      // The scheduler is not a dependency of this class at all, which is what
      // makes "Sprint 05 does not schedule" a fact about the constructor.
      final Reminder created = (await createReminder(
        text: 'responder o e-mail',
        triggerAt: '+5m',
      )).valueOrNull!;

      expect(created.sourceAudioNote, isNull);
      expect(reminders.reminders[created.id]!.sourceAudioNote, isNull);
    });
  });
}
