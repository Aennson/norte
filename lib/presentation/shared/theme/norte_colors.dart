import 'package:flutter/material.dart';

/// Colour tokens of the Norte design system (`docs/design-system.md` §2).
///
/// This is the **only** place in the project allowed to hold literal colours —
/// `tool/check_imports.dart` fails the build on `Color(0x...)` anywhere else.
///
/// Exposed to widgets as a [ThemeExtension] so both palettes travel through
/// `Theme.of(context)` and animate correctly on theme changes.
@immutable
class NorteColors extends ThemeExtension<NorteColors> {
  const NorteColors({
    required this.bg,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.accentHover,
    required this.accentSubtle,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
  });

  /// Main app background.
  final Color bg;

  /// Cards, fields, panels.
  final Color surface;

  /// Hover, selected items, modals.
  final Color surfaceRaised;

  /// Separators and 1px borders.
  final Color border;

  /// Primary text.
  final Color textPrimary;

  /// Supporting text, metadata.
  final Color textSecondary;

  /// Placeholders, disabled content.
  final Color textMuted;

  /// The single brand accent — primary buttons, links, focus, active icon.
  final Color accent;

  /// Foreground drawn on top of [accent] (primary button label, icon).
  ///
  /// Per-theme because no single ink reaches WCAG AA on both accents:
  /// dark uses the near-black background ink, light uses white
  /// (see `docs/reports/decisions.md` — DEC-001).
  final Color onAccent;

  /// Accent hover/pressed.
  final Color accentHover;

  /// Background of accent chips/highlights.
  final Color accentSubtle;

  /// Completed task, sync ok.
  final Color success;

  /// Local×Jira divergence, low confidence.
  final Color warning;

  /// Failures, destructive actions.
  final Color error;

  /// Informational states, Jira links.
  final Color info;

  /// Dark palette — the default theme (`docs/design-system.md` §2.1).
  static const NorteColors dark = NorteColors(
    bg: Color(0xFF1F1E1D),
    surface: Color(0xFF262624),
    surfaceRaised: Color(0xFF30302E),
    border: Color(0xFF3E3E3A),
    textPrimary: Color(0xFFF5F4EF),
    textSecondary: Color(0xFFA8A79E),
    textMuted: Color(0xFF6E6D66),
    accent: Color(0xFFD97757),
    onAccent: Color(0xFF1F1E1D),
    accentHover: Color(0xFFE08B6D),
    accentSubtle: Color(0xFF3A2A22),
    success: Color(0xFF7BAE7F),
    warning: Color(0xFFD9A45B),
    error: Color(0xFFC4553D),
    info: Color(0xFF6A9BCC),
  );

  /// Light palette (`docs/design-system.md` §2.2).
  static const NorteColors light = NorteColors(
    bg: Color(0xFFFAF9F5),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF0EEE6),
    border: Color(0xFFE3E1D9),
    textPrimary: Color(0xFF191919),
    textSecondary: Color(0xFF5E5D59),
    textMuted: Color(0xFF9B9A94),
    accent: Color(0xFFBA5B3B),
    onAccent: Color(0xFFFFFFFF),
    accentHover: Color(0xFFD97757),
    accentSubtle: Color(0xFFF6E3DB),
    success: Color(0xFF4E7D52),
    warning: Color(0xFFA97B2F),
    error: Color(0xFFB03A24),
    info: Color(0xFF3E6C99),
  );

  @override
  NorteColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceRaised,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? onAccent,
    Color? accentHover,
    Color? accentSubtle,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
  }) {
    return NorteColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentHover: accentHover ?? this.accentHover,
      accentSubtle: accentSubtle ?? this.accentSubtle,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
    );
  }

  @override
  NorteColors lerp(covariant ThemeExtension<NorteColors>? other, double t) {
    if (other is! NorteColors) return this;
    // Exact identity at the endpoints — a lerped theme must never drift away
    // from the documented token values (S00-UT-03).
    if (t <= 0) return this;
    if (t >= 1) return other;
    return NorteColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      accentSubtle: Color.lerp(accentSubtle, other.accentSubtle, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NorteColors &&
        other.bg == bg &&
        other.surface == surface &&
        other.surfaceRaised == surfaceRaised &&
        other.border == border &&
        other.textPrimary == textPrimary &&
        other.textSecondary == textSecondary &&
        other.textMuted == textMuted &&
        other.accent == accent &&
        other.onAccent == onAccent &&
        other.accentHover == accentHover &&
        other.accentSubtle == accentSubtle &&
        other.success == success &&
        other.warning == warning &&
        other.error == error &&
        other.info == info;
  }

  @override
  int get hashCode => Object.hash(
    bg,
    surface,
    surfaceRaised,
    border,
    textPrimary,
    textSecondary,
    textMuted,
    accent,
    onAccent,
    accentHover,
    accentSubtle,
    success,
    warning,
    error,
    info,
  );

  /// The palette in scope for [context].
  static NorteColors of(BuildContext context) =>
      Theme.of(context).extension<NorteColors>()!;
}
