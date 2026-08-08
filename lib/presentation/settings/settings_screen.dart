import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../shared/theme/norte_spacing.dart';
import '../shared/widgets/norte_screen.dart';
import 'jira_settings_section.dart';

/// Settings destination.
///
/// Holds the Jira connection from Sprint 02; the AI engine settings arrive in
/// Sprint 07.
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
        ],
      ),
    );
  }
}
