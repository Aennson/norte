/// Which AI engine the user prefers (`docs/architecture.md` §7.3).
///
/// The value is a **preference, not a decision**. A user who chose a CLI engine
/// on their desktop and then opens Norte on a phone has not chosen anything
/// impossible — the selection provider reads the preference and the platform
/// together, and the preference survives untouched (S07-UT-01). Rewriting it to
/// `claudeApi` on the phone would silently forget the desktop choice.
enum EnginePref {
  /// The remote Claude Messages API, BYOK. Available on every platform.
  claudeApi,

  /// GitHub Copilot CLI as a subprocess. Windows only in v1.0.
  copilotCli,

  /// Claude Code CLI as a subprocess. Windows only in v1.0 (DEC-038).
  claudeCodeCli,
}

/// The user's choices about which engine answers and what happens when it
/// cannot (`docs/architecture.md` §7.3, BR-10).
///
/// **No secret is in here.** The Claude API key lives in secure storage
/// (BR-08) and the CLI engines authenticate through their own credential
/// stores; this entity holds preferences and a model id, which is why it can
/// sit in the local database next to the voice settings.
class AiEngineSettings {
  const AiEngineSettings({
    this.engine = EnginePref.claudeApi,
    this.fallbackEnabled = true,
    this.models = const <String, String>{},
  });

  /// Which engine to try first.
  ///
  /// Defaults to [EnginePref.claudeApi] because it is the only one available on
  /// every platform, and a default that is unavailable where it lands would
  /// make the first run of the app depend on which device it was.
  final EnginePref engine;

  /// Whether a failing primary may fall back to another engine (BR-10).
  ///
  /// **On by default.** The alternative default hands the user an error in the
  /// one situation the app could have handled by itself. A user who wants to
  /// know their chosen engine failed — because they are debugging it, or
  /// because a fallback costs them money the primary did not — turns it off,
  /// and S07-UT-02 scenario D asserts that switching it off is honoured
  /// literally: the fallback is not touched, not even once.
  final bool fallbackEnabled;

  /// The model id chosen per engine, keyed by the engine's own id.
  ///
  /// **Absent means "let the engine decide", and that is not the same as a
  /// default.** Copilot's own `auto` routes per request and picked
  /// `claude-haiku-4.5` for a trivial prompt during the Sprint 07 manual pass;
  /// pinning a model here overrides that routing. Storing the absence rather
  /// than materialising today's default means an engine that gains a better
  /// model later starts using it, instead of holding every existing install on
  /// a choice nobody made deliberately.
  ///
  /// Keyed by engine id rather than held as one field because the engines do
  /// not share a namespace: `gpt-5-mini` means nothing to Claude Code, and a
  /// single field would silently carry one engine's answer to another.
  final Map<String, String> models;

  /// The model chosen for [engineId], or `null` to let that engine decide.
  String? modelFor(String engineId) => models[engineId];

  /// A copy with [engineId]'s model set, or cleared when [model] is `null`.
  AiEngineSettings withModel(String engineId, String? model) {
    final Map<String, String> next = Map<String, String>.of(models);
    if (model == null || model.trim().isEmpty) {
      next.remove(engineId);
    } else {
      next[engineId] = model.trim();
    }
    return copyWith(models: next);
  }

  AiEngineSettings copyWith({
    EnginePref? engine,
    bool? fallbackEnabled,
    Map<String, String>? models,
  }) => AiEngineSettings(
    engine: engine ?? this.engine,
    fallbackEnabled: fallbackEnabled ?? this.fallbackEnabled,
    models: models ?? this.models,
  );

  @override
  bool operator ==(Object other) =>
      other is AiEngineSettings &&
      other.engine == engine &&
      other.fallbackEnabled == fallbackEnabled &&
      _sameEntries<String>(other.models, models);

  @override
  int get hashCode => Object.hash(
    engine,
    fallbackEnabled,
    Object.hashAllUnordered(
      models.entries.map((MapEntry<String, String> e) => '${e.key}=${e.value}'),
    ),
  );

}

/// Map equality by content, for the two small maps this file holds.
bool _sameEntries<V>(Map<String, V> a, Map<String, V> b) {
  if (a.length != b.length) return false;
  for (final MapEntry<String, V> entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

/// How many answers each engine has produced, keyed by engine id.
///
/// **Diagnostics, not telemetry.** It never leaves the device (BR-06) and holds
/// counts alone — no prompt, no transcript, no timing. Its whole job is to let
/// a user who switched engines answer "is the one I chose actually the one
/// replying?", which is precisely the question a silent fallback makes
/// unanswerable (S07-E2E-01).
class AiEngineUsage {
  const AiEngineUsage([this.counts = const <String, int>{}]);

  /// Answers produced, per engine id.
  final Map<String, int> counts;

  /// How many answers [engineId] has produced.
  int of(String engineId) => counts[engineId] ?? 0;

  /// A copy with [engineId]'s count raised by one.
  AiEngineUsage increment(String engineId) {
    final Map<String, int> next = Map<String, int>.of(counts);
    next[engineId] = (next[engineId] ?? 0) + 1;
    return AiEngineUsage(next);
  }

  @override
  bool operator ==(Object other) =>
      other is AiEngineUsage && _sameEntries<int>(other.counts, counts);

  @override
  int get hashCode => Object.hashAllUnordered(
    counts.entries.map((MapEntry<String, int> e) => '${e.key}=${e.value}'),
  );
}
