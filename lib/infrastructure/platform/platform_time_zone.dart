import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/ports/time_zone.dart';

/// [TimeZone] backed by the IANA database, for the zone the device is in.
///
/// Uses the same `timezone` package `flutter_local_notifications` schedules
/// against, deliberately: two zone implementations that disagree by an hour
/// would put the row and the notification in different times, and the user
/// would meet the difference exactly once a year.
///
/// Unlike `FixedOffsetTimeZone` this one knows about daylight saving, which
/// matters for the Italian half of BR-11 — São Paulo has had no DST since
/// 2019, Rome has it every year.
class PlatformTimeZone implements TimeZone {
  const PlatformTimeZone(this._location);

  /// Loads the database and the device's zone.
  ///
  /// Falls back to UTC when the platform cannot name its zone or names one the
  /// database does not carry. A wrong-by-hours reminder is bad; a crash at
  /// startup because a phone reported something unexpected is worse, and the
  /// fallback is at least the same everywhere.
  static Future<PlatformTimeZone> load() async {
    tz_data.initializeTimeZones();
    try {
      final TimezoneInfo zone = await FlutterTimezone.getLocalTimezone();
      return PlatformTimeZone(tz.getLocation(zone.identifier));
    } on Object {
      return PlatformTimeZone(tz.getLocation('UTC'));
    }
  }

  final tz.Location _location;

  @override
  String get name => _location.name;

  @override
  DateTime localAt(DateTime instant) {
    final tz.TZDateTime local = tz.TZDateTime.from(instant, _location);
    // A wall-clock *reading*, flagged UTC so nothing downstream does zone
    // arithmetic on it a second time — the shape `TimeZone` documents.
    return DateTime.utc(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
      local.second,
      local.millisecond,
    );
  }

  @override
  DateTime instantOf(DateTime local) => tz.TZDateTime(
    _location,
    local.year,
    local.month,
    local.day,
    local.hour,
    local.minute,
    local.second,
    local.millisecond,
  ).toUtc();
}
