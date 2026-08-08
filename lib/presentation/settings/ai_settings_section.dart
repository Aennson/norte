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

/// Where the user supplies their Claude API key (BYOK,
/// `docs/architecture.md` §7.2).
///
/// **BR-08 shapes this form exactly as it shaped the Jira one.** The field is
/// masked and excluded from autofill; the stored key is never read back into
/// it. A configured install shows *that* a key is present, never the key —
/// there is no legitimate reason for the app to display a secret it already
/// holds, and every reason not to render one on a screen someone may be
/// sharing.
class AiSettingsSection extends ConsumerStatefulWidget {
  const AiSettingsSection({super.key});

  /// Keys the tests and the E2E suite drive this form by.
  static const Key apiKeyFieldKey = Key('ai.apiKey');
  static const Key saveButtonKey = Key('ai.save');
  static const Key clearButtonKey = Key('ai.clear');

  @override
  ConsumerState<AiSettingsSection> createState() => _AiSettingsSectionState();
}

class _AiSettingsSectionState extends ConsumerState<AiSettingsSection> {
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

    await ref.read(aiCredentialStoreProvider).write(key);
    // The key leaves the widget tree the moment it is stored.
    _apiKey.clear();
    setState(() => _showEmpty = false);
    ref.invalidate(aiConfiguredProvider);
  }

  Future<void> _clear() async {
    await ref.read(aiCredentialStoreProvider).clear();
    _apiKey.clear();
    setState(() => _showEmpty = false);
    ref.invalidate(aiConfiguredProvider);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);
    final bool configured =
        ref.watch(aiConfiguredProvider).valueOrNull ?? false;

    return NorteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.aiSectionTitle,
            style: NorteTypography.title.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: NorteSpacing.xs),
          Text(
            l10n.aiSectionDescription,
            style: NorteTypography.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: NorteSpacing.md),
          Text(
            configured ? l10n.aiKeyConfigured : l10n.aiKeyNotConfigured,
            style: NorteTypography.mono.copyWith(
              color: configured ? colors.success : colors.textMuted,
            ),
          ),
          const SizedBox(height: NorteSpacing.lg),
          NorteTextField(
            key: AiSettingsSection.apiKeyFieldKey,
            label: l10n.aiKeyField,
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
                key: AiSettingsSection.saveButtonKey,
                label: l10n.actionSave,
                onPressed: _save,
              ),
              if (configured)
                NorteButton(
                  key: AiSettingsSection.clearButtonKey,
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
