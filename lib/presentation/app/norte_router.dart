import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../meetings/meetings_screen.dart';
import '../meetings/new_meeting_screen.dart';
import '../meetings/record_meeting_screen.dart';
import '../meetings/summary_screen.dart';
import '../reminders/reminder_detail_screen.dart';
import '../reminders/reminders_screen.dart';
import '../settings/settings_screen.dart';
import '../tasks/tasks_screen.dart';
import '../voice/voice_host.dart';

/// Application routes.
///
/// The four destinations live in a [StatefulShellRoute] so each branch keeps
/// its own navigation stack — deep links (opening a ticket from a
/// notification, Sprint 02) land inside the right branch.
abstract final class NorteRoutes {
  static const String tasks = TasksScreen.routePath;
  static const String meetings = MeetingsScreen.routePath;
  static const String reminders = RemindersScreen.routePath;
  static const String settings = SettingsScreen.routePath;
}

/// Builds the router. [initialLocation] is overridable so tests can start on
/// any destination without driving the UI first.
GoRouter buildNorteRouter({String initialLocation = NorteRoutes.tasks}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell shell,
            ) {
              // `VoiceHost` builds the shell and layers the voice panel over
              // it, so a command can be spoken from any destination without
              // each screen knowing the pipeline exists.
              return VoiceHost(
                currentIndex: shell.currentIndex,
                onDestinationSelected: (int index) => shell.goBranch(
                  index,
                  initialLocation: index == shell.currentIndex,
                ),
                child: shell,
              );
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: NorteRoutes.tasks,
                builder: (_, _) => const TasksScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: NorteRoutes.meetings,
                builder: (_, _) => const MeetingsScreen(),
                // Nested, so composing a meeting keeps the shell's navigation
                // and the branch's stack — and so leaving the composer is an
                // ordinary pop, which is what discards the transcript (BR-03).
                routes: <RouteBase>[
                  GoRoute(
                    path: 'new',
                    builder: (_, _) => const NewMeetingScreen(),
                  ),
                  GoRoute(
                    path: 'record',
                    builder: (_, _) => const RecordMeetingScreen(),
                  ),
                  GoRoute(
                    path: 'summary',
                    builder: (_, _) => const SummaryScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: NorteRoutes.reminders,
                builder: (_, _) => const RemindersScreen(),
                // Nested, so a notification tapped from another destination
                // lands inside the reminders branch with the list behind it —
                // a deep link that left the user nowhere to go back to would
                // be a dead end, which is the same reasoning as the meeting
                // composer above.
                routes: <RouteBase>[
                  GoRoute(
                    path: ReminderDetailScreen.routeSegment,
                    builder: (_, GoRouterState state) => ReminderDetailScreen(
                      reminderId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: NorteRoutes.settings,
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
