import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../shared/theme/norte_spacing.dart';
import '../shared/widgets/norte_screen.dart';
import 'ai_settings_section.dart';
import 'jira_settings_section.dart';
import 'template_settings_section.dart';
import 'transcription_settings_section.dart';
import 'voice_settings_section.dart';

/// Settings destination.
///
/// Holds the Jira connection from Sprint 02, and from Sprint 03 the Claude key
/// and the summarization templates. Choosing between engines arrives in
/// Sprint 07, when there is a second one to choose.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Route path of this destination.
  static const String routePath = '/settings';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return NorteScreen(
      title: l10n.navSettings,
      child: ListView(
        padding: EdgeInsets.zero,
        children: const <Widget>[
          JiraSettingsSection(),
          SizedBox(height: NorteSpacing.lg),
          AiSettingsSection(),
          SizedBox(height: NorteSpacing.lg),
          TranscriptionSettingsSection(),
          SizedBox(height: NorteSpacing.lg),
          TemplateSettingsSection(),
          SizedBox(height: NorteSpacing.lg),
          VoiceSettingsSection(),
          SizedBox(height: NorteSpacing.lg),
        ],
      ),
    );
  }
}
