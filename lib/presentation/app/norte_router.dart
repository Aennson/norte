import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../meetings/meetings_screen.dart';
import '../reminders/reminders_screen.dart';
import '../settings/settings_screen.dart';
import '../tasks/tasks_screen.dart';
import 'norte_shell.dart';

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
              return NorteShell(
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
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: NorteRoutes.reminders,
                builder: (_, _) => const RemindersScreen(),
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
