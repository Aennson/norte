import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/generated/app_localizations.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/norte_screen.dart';

/// Settings destination — placeholder until Sprint 07.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Route path of this destination.
  static const String routePath = '/settings';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return NorteScreen(
      title: l10n.navSettings,
      child: EmptyState(
        icon: LucideIcons.settings,
        message: l10n.settingsEmptyMessage,
      ),
    );
  }
}
