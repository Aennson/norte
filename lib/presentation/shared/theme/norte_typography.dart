import 'package:flutter/material.dart';

/// Typographic scale of the design system (`docs/design-system.md` §3).
///
/// Sans (Inter) for prose, mono (JetBrains Mono) for technical data —
/// issue keys, statuses, timestamps, transcripts and recognised commands.
/// Both families are bundled, so rendering is identical on every platform
/// and in golden tests.
abstract final class NorteTypography {
  /// Bundled sans family.
  static const String sansFamily = 'Inter';

  /// Bundled mono family.
  static const String monoFamily = 'JetBrainsMono';

  /// Screen title — 24 / w600.
  static const TextStyle display = TextStyle(
    fontFamily: sansFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  /// Card/section title — 17 / w600.
  static const TextStyle title = TextStyle(
    fontFamily: sansFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  /// Running text — 14.5 / w400.
  static const TextStyle body = TextStyle(
    fontFamily: sansFamily,
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  /// Metadata and relative timestamps — 12 / w400 (rendered in
  /// `textSecondary`, applied by [NorteTypography.textTheme]).
  static const TextStyle caption = TextStyle(
    fontFamily: sansFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  /// Issue keys, statuses, transcripts — 13 / w400 mono.
  static const TextStyle mono = TextStyle(
    fontFamily: monoFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// Status badges — 11 / w500 mono, uppercase, letter-spacing 0.6.
  ///
  /// The uppercase transform is applied by the widget that renders the label,
  /// never by mutating the localized string in the ARB resources (BR-11).
  static const TextStyle monoSmall = TextStyle(
    fontFamily: monoFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.6,
    height: 1.2,
  );

  /// Maps the scale onto Material's [TextTheme] so framework widgets inherit
  /// the design system instead of Material defaults.
  static TextTheme textTheme({
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return TextTheme(
      headlineMedium: display.copyWith(color: textPrimary),
      headlineSmall: display.copyWith(color: textPrimary),
      titleMedium: title.copyWith(color: textPrimary),
      titleSmall: title.copyWith(color: textPrimary),
      bodyMedium: body.copyWith(color: textPrimary),
      bodyLarge: body.copyWith(color: textPrimary),
      bodySmall: caption.copyWith(color: textSecondary),
      labelLarge: body.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: mono.copyWith(color: textPrimary),
      labelSmall: monoSmall.copyWith(color: textSecondary),
    );
  }
}
