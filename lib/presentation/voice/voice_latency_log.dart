/// One command's latency, **broken down by who spent the time**.
///
/// Sprint 05 reported a single p95 of 3973 ms against a target of < 3 s and
/// could not say which half to attack, because the pipeline recorded one
/// number spanning two services. Optimising the wrong one is a day spent for
/// nothing, so a measurement now names its stages:
///
/// * [transcription] — **Scribe's**. From the last partial of the utterance to
///   the committed segment: the VAD silence window plus the final pass. This
///   is the one the old measurement never contained at all — it started *at*
///   the commit — so the 3973 ms was already post-commit, and the split will
///   show that as an absence rather than a guess.
/// * [grounding] — **ours**. Commit to the moment the parse request goes out:
///   the known-issue-key read against the local database. Small if the code is
///   right, and worth its own field precisely so "small" is a fact.
/// * [parse] — **Claude's**. The `parseIntent` call, request to intent.
///
/// **Why the anchor for [transcription] is the last partial.** Nothing on this
/// side of the socket knows when the user stopped speaking. The last partial is
/// the closest observable: it is emitted when Scribe had heard the last word,
/// so commit − last partial is what Scribe spent deciding the sentence was
/// over. It slightly *under*-reports — the partial trails the speech — which
/// is the safe direction for a number used to blame a service.
///
/// **Durations only.** No transcript, no intent, no slot; there is nothing here
/// to redact (BR-06).
class VoiceLatencySample {
  const VoiceLatencySample({
    required this.grounding,
    required this.parse,
    this.transcription,
  });

  /// Last partial → committed segment. Scribe's share.
  ///
  /// `null` when no partial preceded the commit, which happens for a typed
  /// slot answer and in tests that emit a commit on its own. Null rather than
  /// zero: an unmeasured stage must not be averaged in as a fast one.
  final Duration? transcription;

  /// Committed segment → parse request sent. Our own share.
  final Duration grounding;

  /// Parse request → intent in hand. Claude's share.
  final Duration parse;

  /// The span Sprint 05 measured and reported, unchanged in meaning so the
  /// 3973 ms stays comparable rather than quietly re-baselined.
  Duration get postCommit => grounding + parse;

  /// Everything the user waited for after their last word, or `null` when
  /// [transcription] was not observable.
  Duration? get total =>
      transcription == null ? null : transcription! + postCommit;

  @override
  String toString() =>
      'VoiceLatencySample(scribe ${transcription?.inMilliseconds ?? -1}ms, '
      'local ${grounding.inMilliseconds}ms, '
      'claude ${parse.inMilliseconds}ms)';
}

/// Records how long the pipeline takes, stage by stage
/// (`sprint-05` validation rules; risk §15).
///
/// **Why p95 and not the mean.** The mean hides the case that matters. A user
/// whose commands are usually instant and occasionally take six seconds
/// experiences an app that hangs, and a mean of 1.2s would report that as
/// healthy. The target is p95 < 3s because the ninety-fifth percentile is what
/// someone notices.
///
/// **Why per stage.** A p95 of the total tells you the app is slow. A p95 per
/// stage tells you which service to go and look at — and the two can disagree,
/// because the slowest command overall need not be the one with the slowest
/// parse. Each percentile is therefore computed over its own stage, not read
/// off whichever sample happened to be the worst total.
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
  final List<VoiceLatencySample> _samples = <VoiceLatencySample>[];

  /// The measurements held, oldest first.
  List<VoiceLatencySample> get samples =>
      List<VoiceLatencySample>.unmodifiable(_samples);

  /// Number of commands measured since the app started.
  int get count => _samples.length;

  /// Records one command's breakdown.
  void record(VoiceLatencySample sample) {
    _samples.add(sample);
    if (_samples.length > capacity) _samples.removeAt(0);
    sink?.call(_line(sample));
  }

  /// Scribe's p95, over the samples where a partial gave an anchor.
  Duration? get p95Transcription => _p95(<Duration>[
    for (final VoiceLatencySample sample in _samples)
      if (sample.transcription case final Duration measured) measured,
  ]);

  /// Our own p95 — the local read between commit and request.
  Duration? get p95Grounding => _p95(<Duration>[
    for (final VoiceLatencySample sample in _samples) sample.grounding,
  ]);

  /// Claude's p95.
  Duration? get p95Parse => _p95(<Duration>[
    for (final VoiceLatencySample sample in _samples) sample.parse,
  ]);

  /// The p95 of the span Sprint 05 reported as 3973 ms.
  Duration? get p95PostCommit => _p95(<Duration>[
    for (final VoiceLatencySample sample in _samples) sample.postCommit,
  ]);

  /// The p95 of everything the user waited for, over the samples that could
  /// measure all of it.
  Duration? get p95Total => _p95(<Duration>[
    for (final VoiceLatencySample sample in _samples)
      if (sample.total case final Duration measured) measured,
  ]);

  /// Forgets every measurement.
  void clear() => _samples.clear();

  /// One line per command, naming all three shares.
  ///
  /// The point of the line is that the Developer can read the answer off the
  /// console during a manual pass without re-deriving it: which service owns
  /// the time is stated, not implied by three numbers.
  String _line(VoiceLatencySample sample) {
    final String scribe = sample.transcription == null
        ? 'scribe n/a'
        : 'scribe ${sample.transcription!.inMilliseconds}ms';
    return 'voice: intent ready — $scribe · local '
        '${sample.grounding.inMilliseconds}ms · claude '
        '${sample.parse.inMilliseconds}ms '
        '(p95 over $count: scribe ${_ms(p95Transcription)}, claude '
        '${_ms(p95Parse)}, post-commit ${_ms(p95PostCommit)}, total '
        '${_ms(p95Total)})';
  }

  static String _ms(Duration? value) =>
      value == null ? 'n/a' : '${value.inMilliseconds}ms';

  /// Nearest-rank: the smallest sample at or above 95% of the ordered set.
  /// With a handful of measurements that is simply the slowest one, which is
  /// the honest answer — a percentile over four samples is not a percentile,
  /// and pretending otherwise would report a reassuring number computed from
  /// nothing.
  static Duration? _p95(List<Duration> values) {
    if (values.isEmpty) return null;
    final List<Duration> ordered = List<Duration>.of(values)..sort();
    final int rank = (ordered.length * 0.95).ceil().clamp(1, ordered.length);
    return ordered[rank - 1];
  }
}
