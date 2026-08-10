import '../../domain/entities/ai_engine_settings.dart';
import '../../domain/ports/ai_engine.dart';
import '../../domain/ports/ai_engine_settings_store.dart';
import 'fallback_ai_engine.dart';

/// Builds the engine chain from the user's preference and the platform
/// (`docs/architecture.md` §7.3).
///
/// **A function, not a provider.** §7.3 sketches this as a Riverpod provider
/// and the composition root wires it up as one, but the decision itself is
/// policy and belongs where it can be tested without a container or a platform:
/// S07-UT-01 evaluates every combination of preference and platform in a plain
/// unit test, which is only possible because `isWindows` is an argument rather
/// than a call to `Platform.isWindows`.
///
/// That is also what keeps the sprint's rule — no platform code outside the
/// composition root and the adapter — true of the application layer.
///
/// **The preference is read, never corrected.** A user who chose a CLI engine
/// on their desktop and opened Norte on a phone gets the remote engine for this
/// session and keeps their choice for the next time they are at the desktop.
/// Writing `claudeApi` back would be the app silently forgetting something the
/// user did.
class AiEngineSelection {
  const AiEngineSelection._();

  /// The engine that should answer, wrapped in its BR-10 chain.
  ///
  /// [claudeApi] is always available, which is why it is the fallback in every
  /// chain and the answer whenever a CLI engine cannot run. The CLI builders
  /// are only ever called when their engine was both chosen and is runnable —
  /// so a platform without a subprocess never constructs one.
  static AiEngine resolve({
    required AiEngineSettings settings,
    required bool isWindows,
    required AiEngine Function() claudeApi,
    required AiEngine Function() copilotCli,
    required AiEngine Function() claudeCodeCli,
    AiEngineSettingsStore? usage,
    void Function(String line)? log,
  }) {
    final NamedEngine remote = NamedEngine(
      id: claudeApiId,
      label: 'Claude API',
      engine: claudeApi(),
    );

    // Every CLI engine is Windows-only in v1.0, so the platform check is one
    // condition rather than one per engine.
    final NamedEngine? chosen = !isWindows
        ? null
        : switch (settings.engine) {
            EnginePref.copilotCli => NamedEngine(
              id: copilotCliId,
              label: 'GitHub Copilot CLI',
              engine: copilotCli(),
            ),
            EnginePref.claudeCodeCli => NamedEngine(
              id: claudeCodeCliId,
              label: 'Claude Code CLI',
              engine: claudeCodeCli(),
            ),
            EnginePref.claudeApi => null,
          };

    if (chosen == null) {
      // The remote engine is the primary. It is still wrapped, because BR-10's
      // retry is not conditional on there being somewhere to fall back to — a
      // chain with no fallback still retries once, and then reports honestly
      // that there was nothing else to try.
      return FallbackAiEngine(
        primary: remote,
        fallback: null,
        fallbackEnabled: settings.fallbackEnabled,
        usage: usage,
        log: log,
      );
    }

    return FallbackAiEngine(
      primary: chosen,
      fallback: remote,
      fallbackEnabled: settings.fallbackEnabled,
      usage: usage,
      log: log,
    );
  }

  /// Ids the usage counter and the model preference are keyed by. Shipped.
  static const String claudeApiId = 'claude-api';
  static const String copilotCliId = 'copilot-cli';
  static const String claudeCodeCliId = 'claude-code-cli';
}
