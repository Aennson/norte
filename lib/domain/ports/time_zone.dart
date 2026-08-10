/// The zone a wall-clock phrase is spoken in.
///
/// "tomorrow at 9" is not an instant — it becomes one only once somebody says
/// *whose* nine o'clock. The [Clock] answers "when is now"; this answers "what
/// does the wall read then", and Sprint 06 needs both because a reminder is
/// persisted in UTC and spoken about in local time
/// (`docs/architecture.md` §8, S06-IT-02).
///
/// It is a port rather than a `DateTime.toLocal()` call for the usual reason:
/// a test that depends on the machine's zone passes in São Paulo and fails in
/// Dublin, and the one thing a reminder must never do is fire three hours out.
///
/// **Contract**
/// * [name] is an IANA identifier — `America/Sao_Paulo`, `Europe/Rome`.
/// * [localAt] and [instantOf] are inverses wherever the local reading is
///   unambiguous. They are not across a DST discontinuity, and neither throws
///   there: [instantOf] picks the offset in force *before* the transition, so
///   a reminder set inside a skipped hour fires early rather than not at all.
/// * Both are pure and never throw.
abstract interface class TimeZone {
  /// IANA name of the zone.
  String get name;

  /// What the local wall clock reads at [instant].
  ///
  /// The returned value carries the local reading in a UTC-flagged
  /// [DateTime] — its fields are the ones a user would read off a clock, and
  /// it is deliberately not an instant. Doing arithmetic on it is a bug.
  DateTime localAt(DateTime instant);

  /// The instant at which the local wall clock reads [local].
  ///
  /// [local] is a wall-clock reading, not an instant: only its calendar fields
  /// are consulted.
  DateTime instantOf(DateTime local);
}

/// The zone with a single fixed offset — no daylight saving, ever.
///
/// Production uses the platform's zone database; this exists for the two cases
/// that legitimately have no database: a test pinning a zone, and the fallback
/// when the platform cannot name its own zone (`UTC`, offset zero, which is
/// wrong for nobody in a way that is at least predictable).
final class FixedOffsetTimeZone implements TimeZone {
  const FixedOffsetTimeZone(this.name, this.offset);

  /// UTC itself.
  const FixedOffsetTimeZone.utc() : name = 'UTC', offset = Duration.zero;

  @override
  final String name;

  /// How far local time runs ahead of UTC. Negative west of Greenwich.
  final Duration offset;

  @override
  DateTime localAt(DateTime instant) => instant.toUtc().add(offset);

  @override
  DateTime instantOf(DateTime local) => DateTime.utc(
    local.year,
    local.month,
    local.day,
    local.hour,
    local.minute,
    local.second,
    local.millisecond,
  ).subtract(offset);
}
