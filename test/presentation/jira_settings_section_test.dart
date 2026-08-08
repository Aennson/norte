import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/entities/jira_credentials.dart';
import 'package:norte/l10n/generated/app_localizations.dart';
import 'package:norte/presentation/jira/jira_providers.dart';
import 'package:norte/presentation/settings/jira_settings_section.dart';
import 'package:norte/presentation/settings/settings_screen.dart';
import 'package:norte/presentation/shared/theme/norte_theme.dart';

import '../fakes/fakes.dart';

/// The Jira connection form.
///
/// Most of what is asserted here is BR-08: where the token goes, where it does
/// not go, and that the screen never shows one back.
void main() {
  late FakeJiraCredentialStore store;

  setUp(() => store = FakeJiraCredentialStore());

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          jiraCredentialStoreProvider.overrideWithValue(store),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: NorteTheme.dark,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, Key field, String value) async {
    await tester.enterText(
      find.descendant(of: find.byKey(field), matching: find.byType(TextField)),
      value,
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillIn(WidgetTester tester) async {
    await type(
      tester,
      JiraSettingsSection.siteUrlFieldKey,
      'https://example.atlassian.net',
    );
    await type(tester, JiraSettingsSection.emailFieldKey, 'dev@example.com');
    await type(
      tester,
      JiraSettingsSection.apiTokenFieldKey,
      'synthetic-token-value',
    );
  }

  testWidgets('an unconfigured site says so', (WidgetTester tester) async {
    await pump(tester);

    expect(find.text('Not connected.'), findsOneWidget);
    expect(find.byKey(JiraSettingsSection.connectButtonKey), findsOneWidget);
    // Nothing to disconnect from yet.
    expect(find.byKey(JiraSettingsSection.disconnectButtonKey), findsNothing);
  });

  testWidgets('connecting stores the three fields', (
    WidgetTester tester,
  ) async {
    await pump(tester);
    await fillIn(tester);

    await tester.tap(find.byKey(JiraSettingsSection.connectButtonKey));
    await tester.pumpAndSettle();

    expect(store.writes, 1);
    final JiraCredentials stored = (await store.read())!;
    expect(stored.siteUrl, 'https://example.atlassian.net');
    expect(stored.email, 'dev@example.com');
    expect(stored.apiToken, 'synthetic-token-value');

    // The screen confirms the connection by naming the account, never the
    // token (BR-08).
    expect(find.text('Connected as dev@example.com'), findsOneWidget);
    expect(find.text('synthetic-token-value'), findsNothing);
  });

  testWidgets('the token field empties itself once stored', (
    WidgetTester tester,
  ) async {
    await pump(tester);
    await fillIn(tester);
    await tester.tap(find.byKey(JiraSettingsSection.connectButtonKey));
    await tester.pumpAndSettle();

    final TextField field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(JiraSettingsSection.apiTokenFieldKey),
        matching: find.byType(TextField),
      ),
    );
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('the token field is masked and out of the suggestion cache', (
    WidgetTester tester,
  ) async {
    await pump(tester);

    final TextField token = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(JiraSettingsSection.apiTokenFieldKey),
        matching: find.byType(TextField),
      ),
    );
    expect(token.obscureText, isTrue);
    expect(token.enableSuggestions, isFalse);
    expect(token.autocorrect, isFalse);

    // …and the e-mail field is an ordinary one, so the masking is a decision
    // rather than a default.
    final TextField email = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(JiraSettingsSection.emailFieldKey),
        matching: find.byType(TextField),
      ),
    );
    expect(email.obscureText, isFalse);
  });

  testWidgets('an incomplete set is refused with a message', (
    WidgetTester tester,
  ) async {
    await pump(tester);
    await type(
      tester,
      JiraSettingsSection.siteUrlFieldKey,
      'https://example.atlassian.net',
    );

    await tester.tap(find.byKey(JiraSettingsSection.connectButtonKey));
    await tester.pumpAndSettle();

    expect(
      find.text('Fill in the site, the e-mail and the token.'),
      findsOneWidget,
    );
    expect(store.writes, 0);
    expect(await store.read(), isNull);
  });

  testWidgets('a whitespace-only token counts as missing', (
    WidgetTester tester,
  ) async {
    await pump(tester);
    await type(
      tester,
      JiraSettingsSection.siteUrlFieldKey,
      'https://example.atlassian.net',
    );
    await type(tester, JiraSettingsSection.emailFieldKey, 'dev@example.com');
    await type(tester, JiraSettingsSection.apiTokenFieldKey, '    ');

    await tester.tap(find.byKey(JiraSettingsSection.connectButtonKey));
    await tester.pumpAndSettle();

    expect(store.writes, 0);
  });

  testWidgets('disconnecting clears the store and the form', (
    WidgetTester tester,
  ) async {
    store = FakeJiraCredentialStore.configured();
    await pump(tester);

    expect(find.byKey(JiraSettingsSection.disconnectButtonKey), findsOneWidget);

    await tester.tap(find.byKey(JiraSettingsSection.disconnectButtonKey));
    await tester.pumpAndSettle();

    expect(store.clears, 1);
    expect(await store.read(), isNull);
    expect(find.text('Not connected.'), findsOneWidget);
  });

  testWidgets('a configured site is never shown its token back', (
    WidgetTester tester,
  ) async {
    store = FakeJiraCredentialStore.configured(apiToken: 'secret-token-value');
    await pump(tester);

    expect(find.textContaining('secret-token-value'), findsNothing);
    final TextField token = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(JiraSettingsSection.apiTokenFieldKey),
        matching: find.byType(TextField),
      ),
    );
    expect(token.controller!.text, isEmpty);
  });

  testWidgets('the section explains where the token lives', (
    WidgetTester tester,
  ) async {
    await pump(tester);

    expect(find.text('Jira'), findsOneWidget);
    // Scoped to this section. Sprint 03 added a Claude key that makes the
    // same promise in the same words, so an unscoped search now finds two
    // — and the assertion this test is making is about the Jira one.
    expect(
      find.descendant(
        of: find.byType(JiraSettingsSection),
        matching: find.textContaining('secure storage'),
      ),
      findsOneWidget,
    );
  });

  group('Data Center (DEC-012)', () {
    Future<void> chooseDataCenter(WidgetTester tester) async {
      await tester.tap(find.byKey(JiraSettingsSection.dataCenterChipKey));
      await tester.pumpAndSettle();
    }

    testWidgets('Cloud is what a fresh form offers', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      expect(find.byKey(JiraSettingsSection.cloudChipKey), findsOneWidget);
      expect(find.byKey(JiraSettingsSection.dataCenterChipKey), findsOneWidget);
      // The e-mail field is there, because Cloud needs one.
      expect(find.byKey(JiraSettingsSection.emailFieldKey), findsOneWidget);
    });

    testWidgets('choosing it drops the e-mail field', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await chooseDataCenter(tester);

      // A personal access token authenticates on its own, so asking for an
      // e-mail would be asking for something the request will not carry.
      expect(find.byKey(JiraSettingsSection.emailFieldKey), findsNothing);
      expect(find.text('Personal access token'), findsOneWidget);
      expect(find.text('API token'), findsNothing);
    });

    testWidgets('a site and a token are enough to connect', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await chooseDataCenter(tester);
      await type(
        tester,
        JiraSettingsSection.siteUrlFieldKey,
        'https://jira.example.com',
      );
      await type(tester, JiraSettingsSection.apiTokenFieldKey, 'synthetic-pat');

      await tester.tap(find.byKey(JiraSettingsSection.connectButtonKey));
      await tester.pumpAndSettle();

      final JiraCredentials stored = (await store.read())!;
      expect(stored.deployment, JiraDeployment.dataCenter);
      expect(stored.siteUrl, 'https://jira.example.com');
      expect(stored.email, isEmpty);
      expect(stored.apiToken, 'synthetic-pat');

      // With no e-mail to name, the site stands in for the account.
      expect(
        find.text('Connected as https://jira.example.com'),
        findsOneWidget,
      );
    });

    testWidgets('a missing token is still refused', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await chooseDataCenter(tester);
      await type(
        tester,
        JiraSettingsSection.siteUrlFieldKey,
        'https://jira.example.com',
      );

      await tester.tap(find.byKey(JiraSettingsSection.connectButtonKey));
      await tester.pumpAndSettle();

      expect(store.writes, 0);
      expect(
        find.text('Fill in the site, the e-mail and the token.'),
        findsOneWidget,
      );
    });

    testWidgets('disconnecting returns the form to Cloud', (
      WidgetTester tester,
    ) async {
      store = FakeJiraCredentialStore.configured();
      await pump(tester);
      await chooseDataCenter(tester);
      expect(find.byKey(JiraSettingsSection.emailFieldKey), findsNothing);

      await tester.tap(find.byKey(JiraSettingsSection.disconnectButtonKey));
      await tester.pumpAndSettle();

      expect(find.byKey(JiraSettingsSection.emailFieldKey), findsOneWidget);
    });
  });
}
