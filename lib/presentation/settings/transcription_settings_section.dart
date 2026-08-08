import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../meetings/meeting_providers.dart';
import '../shared/theme/norte_colors.dart';
import '../shared/theme/norte_spacing.dart';
import '../shared/theme/norte_typography.dart';
import '../shared/widgets/norte_button.dart';
import '../shared/widgets/norte_card.dart';
import '../shared/widgets/norte_text_field.dart';

/// Where the user supplies their transcription API key (BYOK,
/// `docs/architecture.md` §9.2).
///
/// **A second section rather than a second field in the AI one.** They are
/// different providers with different keys and different lifetimes: a user may
/// summarize pasted transcripts for months before recording anything, and a
/// rejected Whisper key must not read as a broken Claude one.
///
/// **BR-08 shapes this form exactly as it shaped the other two.** The field is
/// masked; the stored key is never read back into it. A configured install
/// shows *that* a key is present, never the key.
class TranscriptionSettingsSection extends ConsumerStatefulWidget {
  const TranscriptionSettingsSection({super.key});

  /// Keys the tests and the E2E suite drive this form by.
  static const Key apiKeyFieldKey = Key('transcription.apiKey');
  static const Key saveButtonKey = Key('transcription.save');
  static const Key clearButtonKey = Key('transcription.clear');

  @override
  ConsumerState<TranscriptionSettingsSection> createState() =>
      _TranscriptionSettingsSectionState();
}

class _TranscriptionSettingsSectionState
    extends ConsumerState<TranscriptionSettingsSection> {
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

    await ref.read(transcriptionCredentialStoreProvider).write(key);
    // The key leaves the widget tree the moment it is stored.
    _apiKey.clear();
    setState(() => _showEmpty = false);
    ref.invalidate(transcriptionConfiguredProvider);
  }

  Future<void> _clear() async {
    await ref.read(transcriptionCredentialStoreProvider).clear();
    _apiKey.clear();
    setState(() => _showEmpty = false);
    ref.invalidate(transcriptionConfiguredProvider);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);
    final bool configured =
        ref.watch(transcriptionConfiguredProvider).valueOrNull ?? false;

    return NorteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.settingsWhisperSection,
            style: NorteTypography.title.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: NorteSpacing.xs),
          Text(
            l10n.settingsWhisperDescription,
            style: NorteTypography.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: NorteSpacing.md),
          Text(
            configured
                ? l10n.settingsWhisperConfigured
                : l10n.aiKeyNotConfigured,
            style: NorteTypography.mono.copyWith(
              color: configured ? colors.success : colors.textMuted,
            ),
          ),
          const SizedBox(height: NorteSpacing.lg),
          NorteTextField(
            key: TranscriptionSettingsSection.apiKeyFieldKey,
            label: l10n.settingsWhisperKeyField,
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
                key: TranscriptionSettingsSection.saveButtonKey,
                label: l10n.actionSave,
                onPressed: _save,
              ),
              if (configured)
                NorteButton(
                  key: TranscriptionSettingsSection.clearButtonKey,
                  label: l10n.aiClearKey,
                  variant: NorteButtonVariant.secondary,
                  onPressed: _clear,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
