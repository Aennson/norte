import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../shared/theme/norte_theme.dart';
import 'norte_router.dart';

/// Root widget of Norte.
///
/// Follows the device locale across the three supported languages and falls
/// back to English for anything else (BR-11).
///
/// Dark is *the* default theme (`docs/design-system.md` §1.3), not merely the
/// dark-mode variant — the app opens dark regardless of the platform setting.
/// The light theme is fully built and golden-tested, and becomes reachable
/// when the appearance preference lands with the settings screen.
class NorteApp extends StatefulWidget {
  const NorteApp({super.key, this.router, this.themeMode = ThemeMode.dark});

  /// Overridable so tests can render the light theme through the real app.
  final ThemeMode themeMode;

  /// Injectable router — tests start on a specific destination without
  /// driving the UI first. `null` builds the production router.
  final GoRouter? router;

  @override
  State<NorteApp> createState() => _NorteAppState();
}

class _NorteAppState extends State<NorteApp> {
  late final GoRouter _router = widget.router ?? buildNorteRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: NorteTheme.light,
      darkTheme: NorteTheme.dark,
      themeMode: widget.themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveNorteLocale,
      routerConfig: _router,
    );
  }
}

/// Resolves [deviceLocale] against the supported locales, matching by language
/// code so `pt-BR` and `pt-PT` both land on the Portuguese resources.
///
/// Anything unsupported — and a device that reports no locale — resolves to
/// English, the template and fallback locale (BR-11).
Locale resolveNorteLocale(Locale? deviceLocale, Iterable<Locale> supported) {
  const Locale fallback = Locale('en');
  if (deviceLocale == null) return fallback;
  for (final Locale locale in supported) {
    if (locale.languageCode == deviceLocale.languageCode) return locale;
  }
  return fallback;
}
