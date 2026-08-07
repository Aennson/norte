import 'package:flutter/material.dart';
import 'package:norte/l10n/generated/app_localizations.dart';
import 'package:norte/presentation/shared/theme/norte_colors.dart';
import 'package:norte/presentation/shared/theme/norte_spacing.dart';

/// Wraps [child] in the minimum app chrome a component needs: the Norte theme
/// and the English localizations (BR-11 — no component holds a literal).
///
/// Golden tests pin the locale to `en` so a translation change never rewrites
/// an unrelated golden.
Widget goldenHarness({required Widget child, required ThemeData theme}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (BuildContext context) {
        final NorteColors colors = NorteColors.of(context);
        // A Material ancestor is required, otherwise Text falls back to the
        // framework's debug style (red on a yellow underline) in the golden.
        return Material(
          color: colors.bg,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(NorteSpacing.lg),
              child: child,
            ),
          ),
        );
      },
    ),
  );
}
