import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/presentation/app/norte_app.dart';
import 'package:norte/presentation/voice/voice_button.dart';

import '../../support/test_fonts.dart';

/// S00-GT-02 — responsive layout of the navigation shell
/// (`docs/design-system.md` §5).
void main() {
  setUpAll(loadNorteFonts);

  const Size mobile = Size(390, 844);
  const Size desktop = Size(1280, 800);

  setUp(() {
    // Goldens are generated against the English resources so a translation
    // change never rewrites an unrelated image (BR-11).
    final TestWidgetsFlutterBinding binding =
        TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.localesTestValue = <Locale>[const Locale('en')];
    addTearDown(binding.platformDispatcher.clearLocalesTestValue);
  });

  Future<void> pumpApp(
    WidgetTester tester,
    Size size, {
    ThemeMode themeMode = ThemeMode.dark,
  }) async {
    tester.setSurfaceSize(size);
    await tester.pumpWidget(NorteApp(themeMode: themeMode));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'S00-GT-02: mobile (390x844) shows the bottom nav with 4 items and the '
    'voice button',
    (WidgetTester tester) async {
      await pumpApp(tester, mobile);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).destinations,
        hasLength(4),
      );
      expect(find.byType(VoiceButton), findsOneWidget);

      for (final String label in <String>[
        'Tasks',
        'Meetings',
        'Reminders',
        'Settings',
      ]) {
        expect(
          find.text(label),
          findsWidgets,
          reason: '$label must be reachable from the bottom navigation',
        );
      }

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('images/navigation_shell_mobile.png'),
      );
    },
    tags: 'golden',
  );

  testWidgets(
    'S00-GT-02: desktop (1280x800) shows the navigation rail with the voice '
    'button',
    (WidgetTester tester) async {
      await pumpApp(tester, desktop);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).destinations,
        hasLength(4),
      );
      expect(find.byType(VoiceButton), findsOneWidget);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('images/navigation_shell_desktop.png'),
      );
    },
    tags: 'golden',
  );

  testWidgets('S00-GT-02: mobile in the light theme', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, mobile, themeMode: ThemeMode.light);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('images/navigation_shell_mobile_light.png'),
    );
  }, tags: 'golden');

  testWidgets('S00-GT-02: the layout switches at the 900px breakpoint', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, const Size(899, 800));
    expect(find.byType(NavigationBar), findsOneWidget);

    tester.view.physicalSize = const Size(900, 800);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
