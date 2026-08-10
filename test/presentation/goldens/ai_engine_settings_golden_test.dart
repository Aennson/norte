import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/application/ai/ai_engine_selection.dart';
import 'package:norte/domain/entities/ai_engine_settings.dart';
import 'package:norte/presentation/settings/ai_engine_providers.dart';
import 'package:norte/presentation/settings/ai_engine_settings_section.dart';
import 'package:norte/presentation/shared/theme/norte_theme.dart';

import '../../fakes/fakes.dart';
import '../../support/golden_harness.dart';
import '../../support/platform_goldens.dart';
import '../../support/test_fonts.dart';

/// S07-GT-01 — the AI Engine section, per platform.
///
/// **The two platforms are two different sections, not one section with a row
/// hidden.** `architecture.md` §7.2 says Android and iOS hide the CLI options,
/// and hiding is the right verb — a greyed-out row invites the user to work out
/// how to un-grey it, and there is no answer, because a phone has no subprocess
/// to start. What a phone shows is a section with one engine and no choice to
/// make.
///
/// **The mobile assertion is made twice, on purpose.** The golden pins the
/// pixels, but a golden alone would let the rows come back as an off-screen
/// widget, or as a row rendered in the background colour, and still match. The
/// `find.byKey` expectations below say the widgets are *absent from the tree*,
/// which is the claim §7.2 actually makes. The handoff for this sprint is
/// explicit that this is the assertion and not a side effect of the layout.
///
/// The Windows renders pick the Copilot engine rather than the default, because
/// the default engine has no model picker and a golden of the default would not
/// show the control the sprint's exit criteria name. Both usage counts are
/// non-zero for the same reason: `0` and `12` render differently, and a counter
/// that only ever showed `0` in a golden could stop counting without any golden
/// noticing.
void main() {
  setUpAll(() async {
    usePlatformGoldens();
    await loadNorteFonts();
  });

  final List<(String, ThemeData)> themes = <(String, ThemeData)>[
    ('dark', NorteTheme.dark),
    ('light', NorteTheme.light),
  ];

  /// Settings with a CLI engine chosen and no model pinned — "Automatic",
  /// which is the absence of a choice rather than a value.
  const AiEngineSettings onCopilot = AiEngineSettings(
    engine: EnginePref.copilotCli,
  );

  /// A history in which the chosen engine has answered and the remote one has
  /// answered too — which is what a user who has been falling back would see,
  /// and the only reason the counter is on the screen (BR-10).
  const AiEngineUsage answered = AiEngineUsage(<String, int>{
    AiEngineSelection.copilotCliId: 12,
    AiEngineSelection.claudeApiId: 3,
  });

  Future<void> pump(
    WidgetTester tester,
    ThemeData theme, {
    required bool isWindows,
    AiEngineSettings settings = const AiEngineSettings(),
    AiEngineUsage usage = const AiEngineUsage(),
    Size size = const Size(560, 560),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          // The one place the app is told which platform it is on. Overriding
          // it is what lets this file render a phone's Settings on a desktop
          // (S07-UT-05 makes the same substitution at the adapter).
          isWindowsProvider.overrideWithValue(isWindows),
          aiEngineSettingsStoreProvider.overrideWithValue(
            FakeAiEngineSettingsStore(settings, usage),
          ),
        ],
        child: goldenHarness(
          theme: theme,
          child: const AiEngineSettingsSection(),
        ),
      ),
    );
    // Twice: the section's first frame is the defaults, and the second is the
    // store's answer. A golden taken on the first frame would pin the
    // placeholder and pass whatever the store later said.
    await tester.pumpAndSettle();
  }

  for (final (String name, ThemeData theme) in themes) {
    testWidgets('S07-GT-01: engine settings on Windows ($name)', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        theme,
        isWindows: true,
        settings: onCopilot,
        usage: answered,
      );

      // The exit criteria, asserted before the pixels are pinned: the choice,
      // the model picker for the selected engine, the fallback toggle, and the
      // counter.
      expect(
        find.byKey(
          AiEngineSettingsSection.engineRadioKey(EnginePref.copilotCli),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          AiEngineSettingsSection.engineRadioKey(EnginePref.claudeCodeCli),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          AiEngineSettingsSection.modelDropdownKey(
            AiEngineSelection.copilotCliId,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(AiEngineSettingsSection.fallbackSwitchKey),
        findsOneWidget,
      );
      expect(find.textContaining('12'), findsOneWidget);

      await expectLater(
        find.byKey(AiEngineSettingsSection.sectionKey),
        matchesGoldenFile('images/ai_engine_settings_windows_$name.png'),
      );
    });

    testWidgets('S07-GT-01: engine settings on mobile ($name)', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        theme,
        isWindows: false,
        // The preference survives the platform that cannot honour it — a user
        // who chose Copilot on their desktop has not chosen anything
        // impossible, and rewriting it here would forget the desktop choice
        // (S07-UT-01). The row is still absent.
        settings: onCopilot,
        usage: answered,
        // Shorter than the Windows render, because it has less to draw. The
        // difference in height is itself part of what the golden records.
        size: const Size(560, 360),
      );

      // **The assertion, not a side effect of the layout.** §7.2 says the
      // options are hidden on a platform with no subprocess, and "hidden"
      // means not in the tree.
      expect(
        find.byKey(
          AiEngineSettingsSection.engineRadioKey(EnginePref.copilotCli),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          AiEngineSettingsSection.engineRadioKey(EnginePref.claudeCodeCli),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          AiEngineSettingsSection.modelDropdownKey(
            AiEngineSelection.copilotCliId,
          ),
        ),
        findsNothing,
      );
      // The remote engine is still offered, and so is the fallback toggle —
      // a phone that hid the whole section would be a different bug.
      expect(
        find.byKey(AiEngineSettingsSection.engineRadioKey(EnginePref.claudeApi)),
        findsOneWidget,
      );
      expect(
        find.byKey(AiEngineSettingsSection.fallbackSwitchKey),
        findsOneWidget,
      );

      await expectLater(
        find.byKey(AiEngineSettingsSection.sectionKey),
        matchesGoldenFile('images/ai_engine_settings_mobile_$name.png'),
      );
    });
  }
}
