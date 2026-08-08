import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:norte/presentation/shared/theme/norte_colors.dart';

import '../../support/contrast.dart';

/// Token tables copied verbatim from `docs/design-system.md` §2.
/// Any drift between the document and the code fails here.
const Map<String, int> darkTokens = <String, int>{
  'bg': 0xFF1F1E1D,
  'surface': 0xFF262624,
  'surfaceRaised': 0xFF30302E,
  'border': 0xFF3E3E3A,
  'textPrimary': 0xFFF5F4EF,
  'textSecondary': 0xFFA8A79E,
  'textMuted': 0xFF6E6D66,
  'accent': 0xFFD97757,
  'onAccent': 0xFF1F1E1D,
  'accentHover': 0xFFE08B6D,
  'accentSubtle': 0xFF3A2A22,
  'success': 0xFF7BAE7F,
  'warning': 0xFFD9A45B,
  'error': 0xFFC4553D,
  'info': 0xFF6A9BCC,
};

const Map<String, int> lightTokens = <String, int>{
  'bg': 0xFFFAF9F5,
  'surface': 0xFFFFFFFF,
  'surfaceRaised': 0xFFF0EEE6,
  'border': 0xFFE3E1D9,
  'textPrimary': 0xFF191919,
  'textSecondary': 0xFF5E5D59,
  'textMuted': 0xFF9B9A94,
  'accent': 0xFFBA5B3B,
  'onAccent': 0xFFFFFFFF,
  'accentHover': 0xFFD97757,
  'accentSubtle': 0xFFF6E3DB,
  'success': 0xFF4E7D52,
  'warning': 0xFFA97B2F,
  'error': 0xFFB03A24,
  'info': 0xFF3E6C99,
};

Map<String, Color> tokensOf(NorteColors palette) => <String, Color>{
  'bg': palette.bg,
  'surface': palette.surface,
  'surfaceRaised': palette.surfaceRaised,
  'border': palette.border,
  'textPrimary': palette.textPrimary,
  'textSecondary': palette.textSecondary,
  'textMuted': palette.textMuted,
  'accent': palette.accent,
  'onAccent': palette.onAccent,
  'accentHover': palette.accentHover,
  'accentSubtle': palette.accentSubtle,
  'success': palette.success,
  'warning': palette.warning,
  'error': palette.error,
  'info': palette.info,
};

void main() {
  group('S00-UT-01', () {
    test('S00-UT-01: dark palette matches every hex in design-system §2.1', () {
      final Map<String, Color> actual = tokensOf(NorteColors.dark);

      expect(
        actual.keys.toSet(),
        darkTokens.keys.toSet(),
        reason: 'the dark palette must expose exactly the documented tokens',
      );
      for (final MapEntry<String, int> token in darkTokens.entries) {
        expect(
          actual[token.key]!.toARGB32(),
          token.value,
          reason:
              'dark.${token.key} must be '
              '#${token.value.toRadixString(16).toUpperCase()}',
        );
      }
    });
  });

  group('S00-UT-02', () {
    test(
      'S00-UT-02: light palette matches every hex in design-system §2.2',
      () {
        final Map<String, Color> actual = tokensOf(NorteColors.light);

        expect(
          actual.keys.toSet(),
          lightTokens.keys.toSet(),
          reason: 'the light palette must expose exactly the documented tokens',
        );
        for (final MapEntry<String, int> token in lightTokens.entries) {
          expect(
            actual[token.key]!.toARGB32(),
            token.value,
            reason:
                'light.${token.key} must be '
                '#${token.value.toRadixString(16).toUpperCase()}',
          );
        }
      },
    );
  });

  group('S00-UT-03', () {
    const NorteColors dark = NorteColors.dark;
    const NorteColors light = NorteColors.light;

    test('S00-UT-03: lerp at the midpoint leaves no token null', () {
      final NorteColors mid = dark.lerp(light, 0.5);

      for (final MapEntry<String, Color> token in tokensOf(mid).entries) {
        expect(
          token.value,
          isNotNull,
          reason: '${token.key} must survive the transition',
        );
      }
      expect(tokensOf(mid).length, darkTokens.length);
    });

    test('S00-UT-03: lerp(a, b, 0) == a and lerp(a, b, 1) == b', () {
      expect(dark.lerp(light, 0), dark);
      expect(dark.lerp(light, 1), light);
      expect(light.lerp(dark, 0), light);
      expect(light.lerp(dark, 1), dark);
    });

    test('S00-UT-03: copyWith() with no override returns an equal palette', () {
      expect(dark.copyWith(), dark);
      expect(light.copyWith(), light);
    });

    test('S00-UT-03: copyWith replaces only the token it is given', () {
      final NorteColors patched = dark.copyWith(accent: light.accent);

      expect(patched.accent, light.accent);
      expect(patched.bg, dark.bg);
      expect(patched.textPrimary, dark.textPrimary);
      expect(patched, isNot(dark));
    });
  });

  group('S00-UT-04', () {
    /// The pairs the UI actually renders. `onAccent`/`accent` replaces the
    /// literal white of the original specification — see DEC-001.
    List<(String, Color, Color)> pairsOf(NorteColors palette) =>
        <(String, Color, Color)>[
          ('textPrimary/bg', palette.textPrimary, palette.bg),
          ('textPrimary/surface', palette.textPrimary, palette.surface),
          ('textSecondary/surface', palette.textSecondary, palette.surface),
          ('onAccent/accent', palette.onAccent, palette.accent),
        ];

    for (final (String name, NorteColors palette) in <(String, NorteColors)>[
      ('dark', NorteColors.dark),
      ('light', NorteColors.light),
    ]) {
      test('S00-UT-04: $name palette reaches WCAG AA (>= 4.5:1)', () {
        for (final (String label, Color fg, Color bg) in pairsOf(palette)) {
          final double ratio = contrastRatio(fg, bg);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                '$name $label is ${ratio.toStringAsFixed(2)}:1 — '
                'WCAG AA requires 4.5:1 for normal text',
          );
        }
      });
    }

    test('S00-UT-04: the contrast helper matches known WCAG anchors', () {
      // Guards the assertions above: a broken helper would pass everything.
      expect(
        contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21, 0.001),
      );
      expect(
        contrastRatio(const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)),
        closeTo(1, 0.001),
      );
    });
  });
}
