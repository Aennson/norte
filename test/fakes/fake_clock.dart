import 'package:norte/domain/ports/clock.dart';

/// Deterministic [Clock] for reminder and sync tests
/// (`docs/testing-strategy.md` §3).
///
/// Time only moves when the test moves it — [advance] or [setTo]. Nothing here
/// reads the platform clock, so a test never depends on wall time.
class FakeClock implements Clock {
  FakeClock(this._now);

  /// Fixed, timezone-free instant used as the default "now" across the suite,
  /// so fixtures and goldens stay stable.
  factory FakeClock.fixed() => FakeClock(DateTime.utc(2026, 1, 1, 9));

  DateTime _now;

  /// Every instant [now] has returned, in call order.
  final List<DateTime> readings = <DateTime>[];

  @override
  DateTime now() {
    readings.add(_now);
    return _now;
  }

  /// Moves the clock forward (or backward, with a negative [duration]).
  void advance(Duration duration) => _now = _now.add(duration);

  /// Jumps to [instant].
  void setTo(DateTime instant) => _now = instant;
}
