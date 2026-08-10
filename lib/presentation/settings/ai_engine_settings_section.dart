import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/ai/ai_engine_selection.dart';
import '../../domain/entities/ai_engine_settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../shared/theme/norte_colors.dart';
import '../shared/theme/norte_spacing.dart';
import '../shared/theme/norte_typography.dart';
import '../shared/widgets/norte_card.dart';
import 'ai_engine_providers.dart';

/// One engine as the settings list needs to show it.
class _EngineOption {
  const _EngineOption({
    required this.pref,
    required this.id,
    required this.label,
    required this.models,
    required this.windowsOnly,
  });

  final EnginePref pref;
  final String id;
  final String label;

  /// Models offered for this engine. Empty for the remote one, whose model is
  /// not the user's to pick in v1.0 — it is fixed by `ClaudeApiEngine`.
  final List<String> models;

  final bool windowsOnly;
}

/// Which AI engine answers, which model it uses, and what happens when it
/// cannot (`docs/architecture.md` §7.3, BR-10).
///
/// **The Copilot and Claude Code options are absent on mobile, not disabled.**
/// §7.2 says the UI hides them, and hiding is the right verb: a greyed-out row
/// invites the user to work out how to un-grey it, and there is no answer —
/// the platform has no subprocess. What a phone shows is a section with one
/// engine and no choice to make (S07-UT-05, S07-GT-01).
///
/// **The model picker is per engine.** `gpt-5-mini` means nothing to Claude
/// Code and `opus` means nothing to Copilot, so one shared field would carry
/// one engine's answer into another. Each engine keeps its own choice, and
/// "Automatic" is the absence of a choice rather than a value — an engine that
/// gains a better default later starts using it instead of holding this install
/// on whatever was current the day the box was ticked.
///
/// **The counter is the honest half of a transparent fallback.** BR-10 is
/// designed so the user cannot tell that their engine failed and another
/// answered; this is where they can find out, without reading a log.
class AiEngineSettingsSection extends ConsumerWidget {
  const AiEngineSettingsSection({super.key});

  /// Keys the widget, golden and E2E suites drive this section by.
  static const Key sectionKey = Key('aiEngine.section');
  static const Key fallbackSwitchKey = Key('aiEngine.fallback');
  static Key engineRadioKey(EnginePref pref) =>
      Key('aiEngine.pref.${pref.name}');
  static Key modelDropdownKey(String engineId) =>
      Key('aiEngine.model.$engineId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);
    final bool isWindows = ref.watch(isWindowsProvider);

    // Defaults while the store answers: one database read, and the default is
    // the engine that works everywhere.
    final AiEngineSettings settings =
        ref.watch(aiEngineSettingsProvider).valueOrNull ??
        const AiEngineSettings();
    final AiEngineUsage usage =
        ref.watch(aiEngineUsageProvider).valueOrNull ?? const AiEngineUsage();

    final List<_EngineOption> options = _optionsFor(l10n)
        .where((_EngineOption option) => isWindows || !option.windowsOnly)
        .toList(growable: false);

    return NorteCard(
      key: AiEngineSettingsSection.sectionKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.settingsEngineSection,
            style: NorteTypography.title.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: NorteSpacing.xs),
          Text(
            l10n.settingsEngineDescription,
            style: NorteTypography.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: NorteSpacing.lg),
          // One `RadioGroup` around the rows rather than a group value on each
          // `Radio`: the per-widget form is deprecated, and the ancestor form
          // is also the honest shape — these buttons are one choice, not three
          // independent ones that happen to agree.
          RadioGroup<EnginePref>(
            groupValue: settings.engine,
            onChanged: (EnginePref? pref) {
              if (pref == null) return;
              _writeSettings(ref, settings.copyWith(engine: pref));
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final _EngineOption option in options)
                  _EngineRow(
                    option: option,
                    settings: settings,
                    answers: usage.of(option.id),
                    onModel: (String? model) => _writeSettings(
                      ref,
                      settings.withModel(option.id, model),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: NorteSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.settingsEngineFallback,
                      style: NorteTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: NorteSpacing.xs),
                    Text(
                      l10n.settingsEngineFallbackDescription,
                      style: NorteTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: NorteSpacing.md),
              Switch(
                key: AiEngineSettingsSection.fallbackSwitchKey,
                value: settings.fallbackEnabled,
                onChanged: (bool value) => _writeSettings(
                  ref,
                  settings.copyWith(fallbackEnabled: value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Saves and re-reads, so the engine provider rebuilds on the new choice.
  Future<void> _writeSettings(WidgetRef ref, AiEngineSettings next) async {
    await ref.read(aiEngineSettingsStoreProvider).write(next);
    ref.invalidate(aiEngineSettingsProvider);
  }

  List<_EngineOption> _optionsFor(AppLocalizations l10n) => <_EngineOption>[
    _EngineOption(
      pref: EnginePref.claudeApi,
      id: AiEngineSelection.claudeApiId,
      label: l10n.settingsEngineClaudeApi,
      models: const <String>[],
      windowsOnly: false,
    ),
    _EngineOption(
      pref: EnginePref.copilotCli,
      id: AiEngineSelection.copilotCliId,
      label: l10n.settingsEngineCopilotCli,
      // Kept in step with `CopilotCliEngine.copilotProfile.knownModels`, and
      // duplicated rather than imported because `presentation/` may not reach
      // into `infrastructure/` (`docs/project-rules.md` §3). S07-UT-01 asserts
      // the two lists agree, so the duplication cannot rot silently.
      models: const <String>['claude-haiku-4.5', 'gpt-5-mini'],
      windowsOnly: true,
    ),
    _EngineOption(
      pref: EnginePref.claudeCodeCli,
      id: AiEngineSelection.claudeCodeCliId,
      label: l10n.settingsEngineClaudeCodeCli,
      models: const <String>['opus', 'sonnet', 'haiku'],
      windowsOnly: true,
    ),
  ];
}

/// One engine: the choice, its model, and how often it has answered.
class _EngineRow extends StatelessWidget {
  const _EngineRow({
    required this.option,
    required this.settings,
    required this.answers,
    required this.onModel,
  });

  final _EngineOption option;
  final AiEngineSettings settings;
  final int answers;
  final ValueChanged<String?> onModel;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);
    final bool selected = settings.engine == option.pref;

    return Padding(
      padding: const EdgeInsets.only(bottom: NorteSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Radio<EnginePref>(
                key: AiEngineSettingsSection.engineRadioKey(option.pref),
                value: option.pref,
              ),
              Expanded(
                child: Text(
                  option.label,
                  style: NorteTypography.body.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              // Mono, because it is a count — technical data, per the design
              // system's typography rule.
              Text(
                l10n.settingsEngineAnswers(answers),
                style: NorteTypography.mono.copyWith(color: colors.textMuted),
              ),
            ],
          ),
          // The model picker belongs to the engine that is selected. Showing
          // three open dropdowns would suggest three engines are in play.
          if (selected && option.models.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: NorteSpacing.xl,
                top: NorteSpacing.xs,
              ),
              child: DropdownButton<String?>(
                key: AiEngineSettingsSection.modelDropdownKey(option.id),
                value: settings.modelFor(option.id),
                isDense: true,
                items: <DropdownMenuItem<String?>>[
                  DropdownMenuItem<String?>(
                    child: Text(
                      l10n.settingsEngineModelAutomatic,
                      style: NorteTypography.body.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  for (final String model in option.models)
                    DropdownMenuItem<String?>(
                      value: model,
                      child: Text(
                        model,
                        style: NorteTypography.mono.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                ],
                onChanged: onModel,
              ),
            ),
        ],
      ),
    );
  }
}
