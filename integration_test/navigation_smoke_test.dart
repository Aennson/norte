import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:norte/presentation/app/norte_app.dart';
import 'package:norte/presentation/meetings/meetings_screen.dart';
import 'package:norte/presentation/reminders/reminders_screen.dart';
import 'package:norte/presentation/settings/ai_engine_providers.dart';
import 'package:norte/presentation/settings/settings_screen.dart';
import 'package:norte/presentation/tasks/tasks_screen.dart';
import 'package:norte/presentation/voice/voice_button.dart';

import '../test/fakes/fake_ai_engine_settings_store.dart';

/// S00-E2E-01 — the app boots and navigates across the four destinations.
///
/// Runs the real composition root: `ProviderScope` + `NorteApp`, exactly what
/// `main.dart` builds (`docs/testing-strategy.md` §4.2).
///
/// **Sprint 00's "no external adapter to override yet" stopped being true in
/// Sprint 07.** Settings now carries the AI Engine section, and that section
/// asks two questions only the composition root may answer: which platform this
/// is, and where the engine preference lives. Both providers throw when left
/// unoverridden — deliberately, since a silent default is how a phone comes to
/// be offered a subprocess — so opening the Settings destination threw
/// `UnimplementedError` here, while every other suite that renders that screen
/// had already been given the two overrides and nothing noticed the gap.
///
/// They are supplied rather than given defaults for the same reason `main.dart`
/// supplies them: `isWindowsProvider` is the one place `Platform.isWindows` is
/// allowed to reach, and the sprint forbids platform code anywhere else.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Pins the locale and the viewport before booting the app.
  ///
  /// The desktop host this suite runs on opens a window wider than the 900px
  /// breakpoint, which would give us the navigation rail; every scenario here
  /// drives the bottom navigation, so the size is fixed for all of them.
  Future<void> bootApp(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = <Locale>[const Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          // The host this suite runs on, which is what the real root passes.
          // On the Linux CI host that means the mobile arrangement — one
          // engine and no CLI rows — and this suite is only asking that the
          // destination opens, not which rows it drew (S07-GT-01 is where the
          // rows are pinned).
          isWindowsProvider.overrideWithValue(Platform.isWindows),
          aiEngineSettingsStoreProvider.overrideWithValue(
            FakeAiEngineSettingsStore(),
          ),
        ],
        child: const NorteApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('S00-E2E-01: every navigation destination opens its screen', (
    WidgetTester tester,
  ) async {
    await bootApp(tester);

    // The app boots on Tasks, with the voice affordance available everywhere.
    expect(find.byType(TasksScreen), findsOneWidget);
    expect(find.byType(VoiceButton), findsOneWidget);
    expect(tester.takeException(), isNull);

    final List<(String, Finder)> destinations = <(String, Finder)>[
      ('Meetings', find.byType(MeetingsScreen)),
      ('Reminders', find.byType(RemindersScreen)),
      ('Settings', find.byType(SettingsScreen)),
      ('Tasks', find.byType(TasksScreen)),
    ];

    for (final (String label, Finder screen) in destinations) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();

      expect(screen, findsOneWidget, reason: 'tapping $label must open it');
      expect(
        find.text(label),
        findsNWidgets(2),
        reason: '$label appears as the nav label and as the screen title',
      );
      expect(find.byType(VoiceButton), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'navigating to $label must not raise',
      );
    }
  });

  testWidgets('S00-E2E-01: each destination keeps its own navigation branch', (
    WidgetTester tester,
  ) async {
    await bootApp(tester);

    // Re-selecting the current destination is a no-op, not a crash.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Tasks'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TasksScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
