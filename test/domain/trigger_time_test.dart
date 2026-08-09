import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/ports/time_zone.dart';
import 'package:norte/domain/services/trigger_time.dart';

/// The `triggerAt` grammar, exhaustively.
///
/// Not a documented sprint case — added under `docs/project-rules.md` §5.4.
/// S06-UT-01 and S06-IT-02 assert the two forms the sprint names; this asserts
/// **every form the model is told to produce**, because the prompt's
/// `Reminders:` line is a promise and the only way to know it is kept is to
/// try each shape it lists.
void main() {
  const TimeZone saoPaulo = FixedOffsetTimeZone(
    'America/Sao_Paulo',
    Duration(hours: -3),
  );

  /// Friday 2026-08-07, 14:00 in São Paulo.
  final DateTime now = DateTime.utc(2026, 8, 7, 17);

  group('the offset forms', () {
    test('seconds, minutes, hours and days are each read', () {
      final Map<String, Duration> forms = <String, Duration>{
        '+90s': Duration(seconds: 90),
        '+20m': Duration(minutes: 20),
        '+1h': Duration(hours: 1),
        '+2d': Duration(days: 2),
      };

      for (final MapEntry<String, Duration> form in forms.entries) {
        expect(
          TriggerTime.resolve(form.key, now, saoPaulo),
          now.add(form.value),
          reason: form.key,
        );
      }
    });

    test('an offset ignores the zone entirely', () {
      // Twenty minutes is twenty minutes anywhere. If the zone leaked into
      // this branch the two answers would differ by five hours.
      expect(
        TriggerTime.resolve('+20m', now, saoPaulo),
        TriggerTime.resolve('+20m', now, const FixedOffsetTimeZone.utc()),
      );
    });
  });

  group('the wall-clock forms', () {
    test('today, tomorrow and a weekday all land on 15:00 local', () {
      for (final String slot in <String>[
        'today 15:00',
        'tomorrow 15:00',
        'monday 15:00',
      ]) {
        final DateTime resolved = TriggerTime.resolve(slot, now, saoPaulo)!;
        expect(saoPaulo.localAt(resolved).hour, 15, reason: slot);
        expect(saoPaulo.localAt(resolved).minute, 0, reason: slot);
        expect(resolved.isUtc, isTrue, reason: slot);
      }
    });

    test('a weekday still to come this week is this week', () {
      // Friday → Monday is three days, not ten.
      expect(
        TriggerTime.resolve('monday 09:00', now, saoPaulo),
        DateTime.utc(2026, 8, 10, 12),
      );
    });

    test('today at an hour already past resolves to the past, and says so', () {
      // `TriggerTime` does not judge — returning null here would make "already
      // passed" indistinguishable from "unreadable", and the use case owes the
      // user different words for those two.
      final DateTime resolved = TriggerTime.resolve(
        'today 09:00',
        now,
        saoPaulo,
      )!;
      expect(resolved.isBefore(now), isTrue);
    });

    test('the case the model uses is not the only case accepted', () {
      expect(
        TriggerTime.resolve('Tomorrow 09:00', now, saoPaulo),
        TriggerTime.resolve('tomorrow 09:00', now, saoPaulo),
      );
    });

    test('an impossible clock reading is refused, not wrapped around', () {
      // 25:00 as "the next day at 1am" would be an invention. The model was
      // never told to produce it, so reading it is guessing.
      expect(TriggerTime.resolve('today 25:00', now, saoPaulo), isNull);
      expect(TriggerTime.resolve('today 12:75', now, saoPaulo), isNull);
    });
  });

  group('ISO 8601', () {
    test('an instant with a zone is taken as it stands', () {
      expect(
        TriggerTime.resolve('2026-08-08T18:00:00Z', now, saoPaulo),
        DateTime.utc(2026, 8, 8, 18),
      );
    });

    test('an offset in the string wins over the injected zone', () {
      expect(
        TriggerTime.resolve('2026-08-08T18:00:00-03:00', now, saoPaulo),
        DateTime.utc(2026, 8, 8, 21),
      );
    });
  });

  group('what is not a time', () {
    test('prose, emptiness and half a form all return null', () {
      for (final String slot in <String>[
        '',
        '   ',
        'depois do almoço',
        'sometime after lunch',
        'tomorrow',
        '15:00',
        '+20',
        '+20x',
      ]) {
        expect(TriggerTime.resolve(slot, now, saoPaulo), isNull, reason: slot);
      }
    });
  });

  group('FixedOffsetTimeZone', () {
    test('localAt and instantOf are inverses', () {
      final DateTime instant = DateTime.utc(2026, 8, 7, 17, 34, 12);
      expect(saoPaulo.instantOf(saoPaulo.localAt(instant)), instant);
    });

    test('UTC is the identity', () {
      const TimeZone utc = FixedOffsetTimeZone.utc();
      final DateTime instant = DateTime.utc(2026, 8, 7, 17);
      expect(utc.localAt(instant), instant);
      expect(utc.instantOf(instant), instant);
      expect(utc.name, 'UTC');
    });
  });
}
