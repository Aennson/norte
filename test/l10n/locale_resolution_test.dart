import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/l10n/generated/app_localizations.dart';
import 'package:norte/presentation/app/norte_app.dart';

/// S00-UT-05 — locale resolution and fallback (BR-11).
///
/// `navTasks` is the sample key: it carries a distinct value in each of the
/// three ARB files, so a wrong resolution is visible rather than ambiguous.
void main() {
  const Locale english = Locale('en');
  const Locale brazilianPortuguese = Locale('pt', 'BR');
  const Locale italian = Locale('it');
  const Locale unsupported = Locale('fr');

  test(
    'S00-UT-05: en, pt-BR and it each resolve to their own translation',
    () async {
      final AppLocalizations en = await AppLocalizations.delegate.load(english);
      final AppLocalizations pt = await AppLocalizations.delegate.load(
        brazilianPortuguese,
      );
      final AppLocalizations it = await AppLocalizations.delegate.load(italian);

      expect(en.navTasks, 'Tasks');
      expect(pt.navTasks, 'Tarefas');
      expect(it.navTasks, 'Attività');

      expect(
        <String>{en.navTasks, pt.navTasks, it.navTasks}.length,
        3,
        reason: 'the sample key must differ across the three locales',
      );
    },
  );

  test('S00-UT-05: the three documented locales are the supported set', () {
    expect(
      AppLocalizations.supportedLocales
          .map((Locale l) => l.languageCode)
          .toSet(),
      <String>{'en', 'pt', 'it'},
    );
  });

  test('S00-UT-05: an unsupported locale resolves to English', () {
    expect(
      resolveNorteLocale(unsupported, AppLocalizations.supportedLocales),
      english,
    );
    expect(
      AppLocalizations.delegate.isSupported(unsupported),
      isFalse,
      reason: 'fr must not be advertised as supported',
    );
  });

  test('S00-UT-05: pt-BR resolves by language code, not by exact match', () {
    expect(
      resolveNorteLocale(
        brazilianPortuguese,
        AppLocalizations.supportedLocales,
      ).languageCode,
      'pt',
    );
  });

  test('S00-UT-05: a device that reports no locale resolves to English', () {
    expect(
      resolveNorteLocale(null, AppLocalizations.supportedLocales),
      english,
    );
  });

  testWidgets(
    'S00-UT-05: the running app falls back to English on an unsupported device locale',
    (WidgetTester tester) async {
      tester.platformDispatcher.localesTestValue = <Locale>[unsupported];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await tester.pumpWidget(const NorteApp());
      await tester.pumpAndSettle();

      expect(find.text('Tasks'), findsWidgets);
      expect(find.text('Tarefas'), findsNothing);
      expect(find.text('Attività'), findsNothing);
    },
  );

  testWidgets('S00-UT-05: the running app follows a supported device locale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.localesTestValue = <Locale>[brazilianPortuguese];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const NorteApp());
    await tester.pumpAndSettle();

    expect(find.text('Tarefas'), findsWidgets);
    expect(find.text('Tasks'), findsNothing);
  });
}
