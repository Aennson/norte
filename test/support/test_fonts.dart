import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the bundled families so golden tests render real glyphs instead of
/// the test harness's placeholder font (S00-GT-01 entry criterion).
///
/// Call once from `setUpAll` in any golden test.
Future<void> loadNorteFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  const Map<String, List<String>> families = <String, List<String>>{
    'Inter': <String>[
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
    ],
    'JetBrainsMono': <String>[
      'assets/fonts/JetBrainsMono-Regular.ttf',
      'assets/fonts/JetBrainsMono-Medium.ttf',
      'assets/fonts/JetBrainsMono-SemiBold.ttf',
    ],
    // The icon set from docs/design-system.md §5 — without it every Icon
    // renders as an empty box in goldens. A font shipped by a package is
    // registered under its package-scoped family name, which is what
    // `IconData.fontPackage` resolves to at paint time.
    'packages/lucide_icons_flutter/Lucide': <String>[
      'packages/lucide_icons_flutter/assets/lucide.ttf',
    ],
  };

  for (final MapEntry<String, List<String>> family in families.entries) {
    final FontLoader loader = FontLoader(family.key);
    for (final String asset in family.value) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
}

/// Fixed rendering surface for golden tests.
extension GoldenSurface on WidgetTester {
  /// Pins the test view to [size] logical pixels at device pixel ratio 1, so
  /// golden files come out byte-identical on every machine. Restored on
  /// teardown.
  void setSurfaceSize(Size size) {
    view.physicalSize = size;
    view.devicePixelRatio = 1;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });
  }
}
