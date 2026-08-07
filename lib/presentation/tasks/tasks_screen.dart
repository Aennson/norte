import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/generated/app_localizations.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/norte_screen.dart';

/// Tasks destination — placeholder until Sprint 01.
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  /// Route path of this destination.
  static const String routePath = '/tasks';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return NorteScreen(
      title: l10n.navTasks,
      child: EmptyState(
        icon: LucideIcons.listChecks,
        message: l10n.tasksEmptyMessage,
      ),
    );
  }
}
