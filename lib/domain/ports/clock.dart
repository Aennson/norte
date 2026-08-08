/// Source of the current time.
///
/// Tests must never depend on the real clock (`docs/project-rules.md` §5.5),
/// so everything that needs "now" — reminder scheduling, Jira sync windows,
/// `createdAt`/`updatedAt` stamps — takes a [Clock] instead of calling
/// `DateTime.now()` directly.
///
/// **Contract**
/// * [now] is non-blocking and never throws.
/// * Consecutive calls are monotonically non-decreasing for a real
///   implementation; a fake may return a frozen value.
abstract interface class Clock {
  /// The current time.
  DateTime now();
}

/// The production [Clock] — delegates to the platform clock.
final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
