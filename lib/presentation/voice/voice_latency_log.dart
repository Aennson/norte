/// Records how long the pipeline takes from committed speech to a usable
/// intent (`sprint-05` validation rules; risk §15).
///
/// **Why p95 and not the mean.** The mean hides the case that matters. A user
/// whose commands are usually instant and occasionally take six seconds
/// experiences an app that hangs, and a mean of 1.2s would report that as
/// healthy. The target is p95 < 3s because the ninety-fifth percentile is what
/// someone notices.
///
/// **In memory, and only in memory.** It holds durations — no transcripts, no
/// intents, no slots — so there is nothing here to redact and nothing that
/// would violate BR-06 if it were dumped. It is a diagnostic the Developer
/// reads from the console during the manual pass, not telemetry: nothing sends
/// it anywhere.
class VoiceLatencyLog {
  VoiceLatencyLog({this.capacity = 100, this.sink});

  /// How many measurements are kept. A rolling window rather than a growing
  /// list: a long-running session must not accumulate memory, and a percentile
  /// over the last hundred commands is the one worth reading.
  final int capacity;

  /// Where each measurement is written — the console during the manual pass.
  /// `null` records silently, which is what the tests want.
  final void Function(String line)? sink;
  final List<Duration> _samples = <Duration>[];

  /// The measurements held, oldest first.
  List<Duration> get samples => List<Duration>.unmodifiable(_samples);

  /// Number of commands measured since the app started.
  int get count => _samples.length;

  /// Records one committed-speech → intent-ready measurement.
  void record(Duration latency) {
    _samples.add(latency);
    if (_samples.length > capacity) _samples.removeAt(0);
    sink?.call(
      'voice: intent ready in ${latency.inMilliseconds}ms '
      '(p95 ${p95?.inMilliseconds ?? 0}ms over $count)',
    );
  }

  /// The 95th percentile of what has been recorded, or `null` when nothing
  /// has been.
  ///
  /// Nearest-rank: the smallest sample at or above 95% of the ordered set.
  /// With a handful of measurements that is simply the slowest one, which is
  /// the honest answer — a percentile over four samples is not a percentile,
  /// and pretending otherwise would report a reassuring number computed from
  /// nothing.
  Duration? get p95 {
    if (_samples.isEmpty) return null;
    final List<Duration> ordered = List<Duration>.of(_samples)..sort();
    final int rank = (ordered.length * 0.95).ceil().clamp(1, ordered.length);
    return ordered[rank - 1];
  }

  /// Forgets every measurement.
  void clear() => _samples.clear();
}
