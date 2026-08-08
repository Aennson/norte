import 'package:flutter/material.dart';

import 'norte_colors.dart';
import 'norte_spacing.dart';
import 'norte_typography.dart';

/// Builds the Material themes from the design-system tokens.
///
/// Every colour comes from [NorteColors]; no widget in `presentation/` is
/// allowed to hard-code one (`docs/design-system.md` §7).
abstract final class NorteTheme {
  /// Dark theme — the product default (`docs/design-system.md` §1.3).
  static ThemeData get dark => _build(NorteColors.dark, Brightness.dark);

  /// Light theme.
  static ThemeData get light => _build(NorteColors.light, Brightness.light);

  static ThemeData _build(NorteColors colors, Brightness brightness) {
    final textTheme = NorteTypography.textTheme(
      textPrimary: colors.textPrimary,
      textSecondary: colors.textSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.bg,
      canvasColor: colors.bg,
      dividerColor: colors.border,
      fontFamily: NorteTypography.sansFamily,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[colors],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.accent,
        onPrimary: colors.onAccent,
        secondary: colors.info,
        onSecondary: colors.bg,
        error: colors.error,
        onError: colors.bg,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        surfaceContainerHighest: colors.surfaceRaised,
        outline: colors.border,
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: NorteSpacing.borderWidth,
        space: NorteSpacing.borderWidth,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bg,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: colors.bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: NorteTypography.display.copyWith(
          color: colors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: colors.border,
            width: NorteSpacing.borderWidth,
          ),
          borderRadius: BorderRadius.circular(NorteSpacing.radius),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.accentSubtle,
        surfaceTintColor: colors.surface,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => NorteTypography.caption.copyWith(
            color: states.contains(WidgetState.selected)
                ? colors.accent
                : colors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 20,
            color: states.contains(WidgetState.selected)
                ? colors.accent
                : colors.textSecondary,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.accentSubtle,
        elevation: 0,
        selectedIconTheme: IconThemeData(size: 20, color: colors.accent),
        unselectedIconTheme: IconThemeData(
          size: 20,
          color: colors.textSecondary,
        ),
        selectedLabelTextStyle: NorteTypography.caption.copyWith(
          color: colors.accent,
        ),
        unselectedLabelTextStyle: NorteTypography.caption.copyWith(
          color: colors.textSecondary,
        ),
      ),
      iconTheme: IconThemeData(color: colors.textSecondary, size: 20),
      splashFactory: NoSplash.splashFactory,
      highlightColor: colors.surfaceRaised,
      hoverColor: colors.surfaceRaised,
    );
  }
}
