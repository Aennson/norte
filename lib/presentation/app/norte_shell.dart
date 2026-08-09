import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/generated/app_localizations.dart';
import '../shared/theme/norte_colors.dart';
import '../shared/theme/norte_spacing.dart';
import '../voice/voice_button.dart';

/// One navigation destination of the shell.
@immutable
class NorteDestination {
  const NorteDestination({required this.icon, required this.label});

  final IconData icon;

  /// Localized label (BR-11).
  final String label;
}

/// Responsive navigation chrome (`docs/design-system.md` §5).
///
/// * `< 900px` — bottom navigation with the four destinations and a centre
///   floating voice button.
/// * `>= 900px` — 72px navigation rail on the left, voice button on the rail.
///
/// The shell owns no state: [currentIndex] and [onDestinationSelected] are
/// driven by `go_router`'s stateful shell branches.
class NorteShell extends StatelessWidget {
  const NorteShell({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.child,
    super.key,
    this.onVoicePressed,
    this.voicePanel,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  /// Starts a voice session. `null` leaves the button inert, which is what the
  /// navigation golden test renders.
  final VoidCallback? onVoicePressed;

  /// The `VoiceOverlay` or `ConfirmSheet`, when a session is running.
  ///
  /// Anchored to the bottom **over** the content rather than replacing it: a
  /// voice command is something the user does while looking at their tasks,
  /// and a full-screen takeover would hide the very list they are talking
  /// about (`docs/design-system.md` §4).
  final Widget? voicePanel;

  /// Destinations in branch order: Tasks, Meetings, Reminders, Settings.
  static List<NorteDestination> destinationsOf(AppLocalizations l10n) =>
      <NorteDestination>[
        NorteDestination(icon: LucideIcons.listChecks, label: l10n.navTasks),
        NorteDestination(icon: LucideIcons.users, label: l10n.navMeetings),
        NorteDestination(icon: LucideIcons.bell, label: l10n.navReminders),
        NorteDestination(icon: LucideIcons.settings, label: l10n.navSettings),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = NorteColors.of(context);
    final destinations = destinationsOf(l10n);
    final isDesktop =
        MediaQuery.sizeOf(context).width >= NorteSpacing.desktopBreakpoint;

    // The Stack is always here, even with nothing to put in it. Wrapping the
    // shell only when a panel exists would re-parent the whole navigation
    // subtree the moment the user speaks — rebuilding every screen, dropping
    // their scroll positions, and re-subscribing every database stream behind
    // them. An empty second child costs one `SizedBox`.
    final content = Stack(
      children: <Widget>[
        Positioned.fill(child: child),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: voicePanel ?? const SizedBox.shrink(),
        ),
      ],
    );

    if (isDesktop) {
      return Scaffold(
        backgroundColor: colors.bg,
        body: Row(
          children: <Widget>[
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              minWidth: NorteSpacing.railWidth,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: NorteSpacing.lg),
                child: VoiceButton(
                  semanticLabel: l10n.voiceCommandLabel,
                  onPressed: onVoicePressed,
                ),
              ),
              destinations: <NavigationRailDestination>[
                for (final destination in destinations)
                  NavigationRailDestination(
                    icon: Icon(destination.icon),
                    label: Text(destination.label),
                  ),
              ],
            ),
            VerticalDivider(
              width: NorteSpacing.borderWidth,
              thickness: NorteSpacing.borderWidth,
              color: colors.border,
            ),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.bg,
      body: content,
      floatingActionButton: VoiceButton(
        semanticLabel: l10n.voiceCommandLabel,
        onPressed: onVoicePressed,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colors.border,
              width: NorteSpacing.borderWidth,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onDestinationSelected,
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: <NavigationDestination>[
            for (final destination in destinations)
              NavigationDestination(
                icon: Icon(destination.icon),
                label: destination.label,
              ),
          ],
        ),
      ),
    );
  }
}
