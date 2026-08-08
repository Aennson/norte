import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/voice_settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../shared/theme/norte_colors.dart';
import '../shared/theme/norte_spacing.dart';
import '../shared/theme/norte_typography.dart';
import '../shared/widgets/norte_card.dart';
import '../voice/voice_providers.dart';

/// Where the user decides how cautious spoken commands are
/// (`docs/architecture.md` §6.2).
///
/// One switch, and its description says the thing a switch alone cannot: BR-04
/// still applies when it is off. A user who turns this off is choosing to skip
/// confirmation on commands the app is *sure* about — not to let a doubtful
/// parse through, which is not on offer.
class VoiceSettingsSection extends ConsumerWidget {
  const VoiceSettingsSection({super.key});

  /// Key the tests and the E2E suite drive this switch by.
  static const Key alwaysConfirmSwitchKey = Key('voice.alwaysConfirmJira');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);
    // Defaults until the store answers: the safe setting, never the lax one.
    final VoiceSettings settings =
        ref.watch(voiceSettingsProvider).valueOrNull ?? const VoiceSettings();

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
                onChanged: (bool value) => ref
                    .read(voiceSettingsStoreProvider)
                    .write(settings.copyWith(alwaysConfirmJiraWrites: value)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
