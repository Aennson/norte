import '../ports/time_zone.dart';

/// Turns the `triggerAt` slot into an instant.
///
/// The grammar is **the one the model is told to produce** — the `Reminders:`
/// line of `IntentCodec.systemPrompt` lists those five shapes, and this file is
/// the other half of that contract. Accepting less than the prompt promises is
/// a parse failure the user experiences as the app not understanding them.
///
/// | Slot | Read as |
/// |---|---|
/// | `+20m`, `+90s`, `+1h`, `+2d` | an offset from the injected clock |
/// | `today 15:00` | 15:00 local, on the local calendar day of "now" |
/// | `tomorrow 09:00` | 09:00 local, the day after that |
/// | `friday 15:00` | 15:00 local, on the **next** such weekday |
/// | `2026-08-09 15:00` | that local wall clock, on that date |
/// | an ISO 8601 instant | itself, converted to UTC |
///
/// **The dated form is not spoken, and the model is not told about it.** It is
/// what the typed fallback's date picker emits — a picker knows the exact day
/// and cannot say "tomorrow", and the alternative was asking a user who chose
/// *not* to talk to their laptop to type `+20m` instead. It goes through the
/// same zone as the other wall-clock forms, which is the reason it is a slot
/// shape at all rather than an ISO instant built in the widget layer against
/// whatever zone the device happened to be in.
///
/// **Everything wall-clock goes through [TimeZone].** Sprint 05 refused these
/// three forms rather than resolve them in the device's ambient zone
/// (DEC-025), and the reason survives into this sprint: a reminder is stored
/// in UTC, so the only place the user's zone can be applied is here, once,
/// where a test can pin it.
///
/// **`friday` is never today.** "lembra sexta às 15h" said on a Friday means
/// the Friday coming, not one that may already have passed — so a weekday
/// matching the current day resolves seven days out. `today` and `tomorrow`
/// stay literal, because those two words already name the day.
abstract final class TriggerTime {
  /// [slot] as an instant, or `null` when it is not one of the documented
  /// forms.
  ///
  /// [now] is the current instant and [zone] the user's zone. The result is
  /// always UTC. A `null` return is not "in the past" — that judgement belongs
  /// to the use case, which is the only layer that knows what to tell the user.
  static DateTime? resolve(String slot, DateTime now, TimeZone zone) {
    final String value = slot.trim();
    if (value.isEmpty) return null;

    final DateTime? offset = _resolveOffset(value, now);
    if (offset != null) return offset;

    // **The dated form answers for itself, including with a `null`.** Falling
    // through to `DateTime.tryParse` on a rejection would undo the rejection:
    // that parser is lenient and turns `2026-02-31` into 3 March without
    // complaint, so a date this class had just refused as impossible would
    // come back as a reminder on another day.
    final String lowered = value.toLowerCase();
    if (_datedWallClock.firstMatch(lowered) case final RegExpMatch dated) {
      return _resolveDated(dated, zone);
    }

    final DateTime? wallClock = _resolveWallClock(lowered, now, zone);
    if (wallClock != null) return wallClock;

    return DateTime.tryParse(value)?.toUtc();
  }

  /// The `2026-08-09 15:00` shape, already matched.
  ///
  /// `null` means the digits do not name a real minute — 25:00, month 13, the
  /// 31st of February.
  static DateTime? _resolveDated(RegExpMatch dated, TimeZone zone) {
    final int hour = int.parse(dated.group(4)!);
    final int minute = int.parse(dated.group(5)!);
    if (hour > 23 || minute > 59) return null;

    final int year = int.parse(dated.group(1)!);
    final int month = int.parse(dated.group(2)!);
    final int day = int.parse(dated.group(3)!);
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;

    final DateTime local = DateTime.utc(year, month, day, hour, minute);
    // `DateTime` rolls an impossible day into the next month rather than
    // refusing it, and a reminder silently moved to another day is worse than
    // one refused: the user is not told, and finds out by missing it.
    if (local.month != month || local.day != day) return null;

    return zone.instantOf(local);
  }

  static DateTime? _resolveOffset(String value, DateTime now) {
    final RegExpMatch? match = _offset.firstMatch(value);
    if (match == null) return null;

    final int amount = int.parse(match.group(1)!);
    final DateTime instant = now.toUtc();
    return switch (match.group(2)!) {
      's' => instant.add(Duration(seconds: amount)),
      'm' => instant.add(Duration(minutes: amount)),
      'h' => instant.add(Duration(hours: amount)),
      _ => instant.add(Duration(days: amount)),
    };
  }

  /// The relative shapes — `today 15:00`, `tomorrow 09:00`, `friday 15:00`.
  ///
  /// [lowered] has already been lower-cased by [resolve].
  static DateTime? _resolveWallClock(
    String lowered,
    DateTime now,
    TimeZone zone,
  ) {
    final RegExpMatch? match = _wallClock.firstMatch(lowered);
    if (match == null) return null;

    final int hour = int.parse(match.group(2)!);
    final int minute = int.parse(match.group(3)!);
    if (hour > 23 || minute > 59) return null;

    final DateTime today = zone.localAt(now);
    final String day = match.group(1)!;

    final DateTime local = switch (day) {
      'today' => _at(today, hour, minute),
      'tomorrow' => _at(today.add(const Duration(days: 1)), hour, minute),
      _ => _at(_nextWeekday(today, _weekdays[day]!), hour, minute),
    };

    return zone.instantOf(local);
  }

  /// [local] as the dated wall-clock slot this class reads back.
  ///
  /// The date picker's side of the contract, so the format lives beside the
  /// expression that parses it rather than in a widget three layers away.
  static String slotFor(DateTime local) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  /// [day] with its time replaced — calendar fields only, never arithmetic on
  /// a wall-clock reading (`TimeZone.localAt`).
  static DateTime _at(DateTime day, int hour, int minute) =>
      DateTime.utc(day.year, day.month, day.day, hour, minute);

  /// The next day whose weekday is [weekday], counting today as seven days
  /// away rather than zero.
  static DateTime _nextWeekday(DateTime from, int weekday) {
    final int ahead = (weekday - from.weekday + 7) % 7;
    return from.add(Duration(days: ahead == 0 ? 7 : ahead));
  }

  static final RegExp _offset = RegExp(r'^\+(\d+)\s*([smhd])$');

  static final RegExp _datedWallClock = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})[ t](\d{1,2}):(\d{2})$',
  );

  static final RegExp _wallClock = RegExp(
    r'^(today|tomorrow|monday|tuesday|wednesday|thursday|friday|saturday|sunday)'
    r'\s+(\d{1,2}):(\d{2})$',
  );

  static const Map<String, int> _weekdays = <String, int>{
    'monday': DateTime.monday,
    'tuesday': DateTime.tuesday,
    'wednesday': DateTime.wednesday,
    'thursday': DateTime.thursday,
    'friday': DateTime.friday,
    'saturday': DateTime.saturday,
    'sunday': DateTime.sunday,
  };
}
