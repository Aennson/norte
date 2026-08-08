import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// S00-UT-06 — ARB key parity (BR-11).
///
/// Runs in **every** sprint from now on: adding a UI string to fewer than the
/// three files fails here, before the string can reach a screen.
void main() {
  const String arbDir = 'lib/l10n';
  const Map<String, String> arbFiles = <String, String>{
    'en': '$arbDir/app_en.arb',
    'pt': '$arbDir/app_pt.arb',
    'it': '$arbDir/app_it.arb',
  };

  /// Placeholders referenced by an ICU message, e.g. `{count}`.
  final RegExp placeholderPattern = RegExp(r'\{(\w+)\}');

  late Map<String, Map<String, String>> messages;

  setUpAll(() {
    messages = <String, Map<String, String>>{};
    for (final MapEntry<String, String> entry in arbFiles.entries) {
      final File file = File(entry.value);
      expect(
        file.existsSync(),
        isTrue,
        reason: '${entry.value} must exist (BR-11 requires all three locales)',
      );
      final Map<String, Object?> raw =
          jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      messages[entry.key] = <String, String>{
        for (final MapEntry<String, Object?> message in raw.entries)
          // `@@locale` and the `@key` metadata blocks are not translations.
          if (!message.key.startsWith('@'))
            message.key: message.value! as String,
      };
    }
  });

  test('S00-UT-06: the three locales expose an identical key set', () {
    final Set<String> template = messages['en']!.keys.toSet();
    expect(template, isNotEmpty);

    for (final String locale in <String>['pt', 'it']) {
      final Set<String> actual = messages[locale]!.keys.toSet();
      expect(
        actual.difference(template),
        isEmpty,
        reason: 'app_$locale.arb has keys missing from the app_en.arb template',
      );
      expect(
        template.difference(actual),
        isEmpty,
        reason: 'app_$locale.arb is missing keys present in app_en.arb',
      );
    }
  });

  test(
    'S00-UT-06: every key declares the same placeholders in all three files',
    () {
      Set<String> placeholdersOf(String value) => placeholderPattern
          .allMatches(value)
          .map((RegExpMatch match) => match.group(1)!)
          .toSet();

      for (final String key in messages['en']!.keys) {
        final Set<String> expected = placeholdersOf(messages['en']![key]!);
        for (final String locale in <String>['pt', 'it']) {
          expect(
            placeholdersOf(messages[locale]![key]!),
            expected,
            reason: 'placeholders of "$key" diverge in app_$locale.arb',
          );
        }
      }
    },
  );

  test('S00-UT-06: no value is empty or whitespace-only', () {
    for (final MapEntry<String, Map<String, String>> locale
        in messages.entries) {
      for (final MapEntry<String, String> message in locale.value.entries) {
        expect(
          message.value.trim(),
          isNotEmpty,
          reason: '${message.key} is empty in app_${locale.key}.arb',
        );
      }
    }
  });

  test('S00-UT-06: each file declares its own @@locale', () {
    for (final MapEntry<String, String> entry in arbFiles.entries) {
      final Map<String, Object?> raw =
          jsonDecode(File(entry.value).readAsStringSync())
              as Map<String, Object?>;
      expect(
        raw['@@locale'],
        entry.key,
        reason: '${entry.value} must declare "@@locale": "${entry.key}"',
      );
    }
  });
}
