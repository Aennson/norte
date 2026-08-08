import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/generated/app_localizations.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/norte_screen.dart';

/// Reminders destination — placeholder until Sprint 06.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  /// Route path of this destination.
  static const String routePath = '/reminders';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return NorteScreen(
      title: l10n.navReminders,
      child: EmptyState(
        icon: LucideIcons.bell,
        message: l10n.remindersEmptyMessage,
      ),
    );
  }
}
