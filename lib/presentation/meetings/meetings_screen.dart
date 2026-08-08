import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/generated/app_localizations.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/norte_screen.dart';

/// Meetings destination — placeholder until Sprint 03.
class MeetingsScreen extends StatelessWidget {
  const MeetingsScreen({super.key});

  /// Route path of this destination.
  static const String routePath = '/meetings';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return NorteScreen(
      title: l10n.navMeetings,
      child: EmptyState(
        icon: LucideIcons.users,
        message: l10n.meetingsEmptyMessage,
      ),
    );
  }
}
