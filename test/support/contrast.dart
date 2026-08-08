import 'dart:math' as math;
import 'dart:ui';

/// WCAG 2.1 relative luminance of [color] (sRGB, opaque).
double relativeLuminance(Color color) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// WCAG 2.1 contrast ratio between [a] and [b], in `1.0..21.0`.
///
/// AA requires ≥ 4.5:1 for normal text (`docs/design-system.md` §2).
double contrastRatio(Color a, Color b) {
  final double la = relativeLuminance(a);
  final double lb = relativeLuminance(b);
  final double lighter = math.max(la, lb);
  final double darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}
