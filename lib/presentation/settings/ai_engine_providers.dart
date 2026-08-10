import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/ai/ai_engine_selection.dart';
import '../../domain/entities/ai_engine_settings.dart';
import '../../domain/ports/ai_engine.dart';
import '../../domain/ports/ai_engine_settings_store.dart';

/// Builds one CLI engine with the model the user pinned, or `null` for the
/// engine's own routing.
///
/// A function rather than an engine, because the model is a preference that can
/// change while the app is running: an engine built once at startup would go on
/// using the model that was selected then.
typedef CliEngineBuilder = AiEngine Function(String? model);

/// Whether this device is the platform the CLI engines exist for.
///
/// **The one place `Platform.isWindows` is allowed to reach**, via an override
/// in the composition root. The sprint forbids platform code outside the root
/// and the adapters, and a provider is how the rest of the app asks the
/// question without importing `dart:io` — which is also what lets a widget test
/// render the Settings screen "as Android" without being on Android
/// (S07-UT-05, S07-GT-01).
final Provider<bool> isWindowsProvider = Provider<bool>(
  (Ref ref) => throw UnimplementedError(
    'isWindowsProvider must be overridden in the composition root',
  ),
);

/// Storage for the engine preference and the usage counter.
final Provider<AiEngineSettingsStore> aiEngineSettingsStoreProvider =
    Provider<AiEngineSettingsStore>(
      (Ref ref) => throw UnimplementedError(
        'aiEngineSettingsStoreProvider must be overridden in the '
        'composition root',
      ),
    );

/// The remote engine. Always available, on every platform.
final Provider<AiEngine> remoteAiEngineProvider = Provider<AiEngine>(
  (Ref ref) => throw UnimplementedError(
    'remoteAiEngineProvider must be overridden in the composition root',
  ),
);

/// Builds the Copilot CLI engine.
final Provider<CliEngineBuilder> copilotCliBuilderProvider =
    Provider<CliEngineBuilder>(
      (Ref ref) => throw UnimplementedError(
        'copilotCliBuilderProvider must be overridden in the composition root',
      ),
    );

/// Builds the Claude Code CLI engine (DEC-038).
final Provider<CliEngineBuilder> claudeCodeCliBuilderProvider =
    Provider<CliEngineBuilder>(
      (Ref ref) => throw UnimplementedError(
        'claudeCodeCliBuilderProvider must be overridden in the '
        'composition root',
      ),
    );

/// Where the diagnostics log lines go. Silent unless the root wires it up.
final Provider<void Function(String)?> aiEngineLogProvider =
    Provider<void Function(String)?>((Ref ref) => null);

/// The user's engine choices.
final FutureProvider<AiEngineSettings> aiEngineSettingsProvider =
    FutureProvider<AiEngineSettings>(
      (Ref ref) => ref.watch(aiEngineSettingsStoreProvider).read(),
    );

/// How many answers each engine has produced.
final FutureProvider<AiEngineUsage> aiEngineUsageProvider =
    FutureProvider<AiEngineUsage>(
      (Ref ref) => ref.watch(aiEngineSettingsStoreProvider).readUsage(),
    );

/// The engine chain the app actually calls (`docs/architecture.md` §7.3).
///
/// **Computed rather than injected, and that is the change Sprint 07 makes.**
/// Until now the composition root built one engine and handed it over; a
/// preference that can be changed in Settings cannot work that way, because the
/// engine would keep being the one chosen at launch. Watching the settings
/// means the next summary goes to the engine the user just picked, with no
/// restart and no invalidation to remember.
///
/// **The defaults stand in while the store is answering.** That window is one
/// database read, and landing in it means the remote engine — the one that
/// works everywhere. A window that resolved to a CLI engine instead could
/// briefly offer a subprocess on a phone.
final Provider<AiEngine> aiEngineProvider = Provider<AiEngine>((Ref ref) {
  final AiEngineSettings settings =
      ref.watch(aiEngineSettingsProvider).valueOrNull ??
      const AiEngineSettings();

  return AiEngineSelection.resolve(
    settings: settings,
    isWindows: ref.watch(isWindowsProvider),
    claudeApi: () => ref.watch(remoteAiEngineProvider),
    copilotCli: () => ref.watch(copilotCliBuilderProvider)(
      settings.modelFor(AiEngineSelection.copilotCliId),
    ),
    claudeCodeCli: () => ref.watch(claudeCodeCliBuilderProvider)(
      settings.modelFor(AiEngineSelection.claudeCodeCliId),
    ),
    usage: ref.watch(aiEngineSettingsStoreProvider),
    log: ref.watch(aiEngineLogProvider),
  );
});
