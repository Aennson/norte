import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/voice_settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../shared/theme/norte_colors.dart';
import '../shared/theme/norte_spacing.dart';
import '../shared/theme/norte_typography.dart';
import '../shared/widgets/norte_button.dart';
import '../shared/widgets/norte_card.dart';
import '../shared/widgets/norte_text_field.dart';
import '../voice/voice_providers.dart';

/// Where the user supplies the realtime transcription key and decides how
/// cautious spoken commands are (`docs/architecture.md` §6.2, §9.2).
///
/// **A third key field, not a second use of the second one.** Meetings go to
/// Whisper and spoken commands go to Scribe: different services, different
/// credentials, and a user may hold one and not the other. Sprint 05's first
/// draft handed the Whisper store to both engines, which meant configuring
/// voice commands silently broke meeting transcription — the reason this
/// section grew a form rather than staying a lone switch.
///
/// **BR-08 shapes it as it shaped the other three key forms.** The field is
/// masked; the stored key is never read back into it. A configured install
/// shows *that* a key is present, never the key.
///
/// The switch's description says the thing a switch alone cannot: BR-04 still
/// applies when it is off. Turning it off skips confirmation on commands the
/// app is *sure* about — letting a doubtful parse through is not on offer.
class VoiceSettingsSection extends ConsumerStatefulWidget {
  const VoiceSettingsSection({super.key});

  /// Keys the tests and the E2E suite drive this form by.
  static const Key alwaysConfirmSwitchKey = Key('voice.alwaysConfirmJira');
  static const Key apiKeyFieldKey = Key('voice.scribeKey');
  static const Key saveButtonKey = Key('voice.scribeSave');
  static const Key clearButtonKey = Key('voice.scribeClear');

  @override
  ConsumerState<VoiceSettingsSection> createState() =>
      _VoiceSettingsSectionState();
}

class _VoiceSettingsSectionState extends ConsumerState<VoiceSettingsSection> {
  final TextEditingController _apiKey = TextEditingController();
  bool _showEmpty = false;

  @override
  void dispose() {
    _apiKey.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String key = _apiKey.text.trim();
    if (key.isEmpty) {
      setState(() => _showEmpty = true);
      return;
    }

    await ref.read(realtimeCredentialStoreProvider).write(key);
    // The key leaves the widget tree the moment it is stored.
    _apiKey.clear();
    setState(() => _showEmpty = false);
    ref.invalidate(realtimeConfiguredProvider);
  }

  Future<void> _clear() async {
    await ref.read(realtimeCredentialStoreProvider).clear();
    _apiKey.clear();
    setState(() => _showEmpty = false);
    ref.invalidate(realtimeConfiguredProvider);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);
    // Defaults until the store answers: the safe setting, never the lax one.
    final VoiceSettings settings =
        ref.watch(voiceSettingsProvider).valueOrNull ?? const VoiceSettings();
    final bool configured =
        ref.watch(realtimeConfiguredProvider).valueOrNull ?? false;

    return NorteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.settingsVoiceSection,
            style: NorteTypography.title.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: NorteSpacing.xs),
          Text(
            l10n.settingsVoiceDescription,
            style: NorteTypography.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: NorteSpacing.lg),
          Text(
            l10n.settingsScribeDescription,
            style: NorteTypography.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: NorteSpacing.md),
          Text(
            configured
                ? l10n.settingsScribeConfigured
                : l10n.settingsScribeNotConfigured,
            style: NorteTypography.mono.copyWith(
              color: configured ? colors.success : colors.textMuted,
            ),
          ),
          const SizedBox(height: NorteSpacing.lg),
          NorteTextField(
            key: VoiceSettingsSection.apiKeyFieldKey,
            label: l10n.settingsScribeKeyField,
            hint: l10n.aiKeyFieldHint,
            controller: _apiKey,
            isSecret: true,
            errorText: _showEmpty ? l10n.aiKeyRequired : null,
          ),
          const SizedBox(height: NorteSpacing.lg),
          Wrap(
            spacing: NorteSpacing.sm,
            runSpacing: NorteSpacing.sm,
            children: <Widget>[
              NorteButton(
                key: VoiceSettingsSection.saveButtonKey,
                label: l10n.actionSave,
                onPressed: _save,
              ),
              if (configured)
                NorteButton(
                  key: VoiceSettingsSection.clearButtonKey,
                  label: l10n.aiClearKey,
                  variant: NorteButtonVariant.secondary,
                  onPressed: _clear,
                ),
            ],
          ),
          const SizedBox(height: NorteSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.settingsAlwaysConfirmJira,
                      style: NorteTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: NorteSpacing.xs),
                    Text(
                      l10n.settingsAlwaysConfirmJiraDescription,
                      style: NorteTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: NorteSpacing.md),
              Switch(
                key: VoiceSettingsSection.alwaysConfirmSwitchKey,
                value: settings.alwaysConfirmJiraWrites,
                onChanged: (bool value) async {
                  await ref
                      .read(voiceSettingsStoreProvider)
                      .write(settings.copyWith(alwaysConfirmJiraWrites: value));
                  ref.invalidate(voiceSettingsProvider);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
