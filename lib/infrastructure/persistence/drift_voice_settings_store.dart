import 'dart:convert';

import '../../domain/entities/voice_settings.dart';
import '../../domain/failures/failure.dart';
import '../../domain/ports/voice_settings_store.dart';
import 'norte_database.dart';

/// Drift-backed [VoiceSettingsStore], one JSON row in the `settings` table.
///
/// **An absent row reads as the defaults, and a corrupt one reads as the
/// defaults too.** Both are the same question — "what should the app do when
/// it does not know what the user chose?" — and the answer is the safe
/// setting, which is to confirm. Refusing to start over an unreadable
/// preference would be an app that locks the user out of their tasks because
/// a checkbox failed to parse.
class DriftVoiceSettingsStore implements VoiceSettingsStore {
  const DriftVoiceSettingsStore(this._database);

  final NorteDatabase _database;

  /// Key this store owns in the shared preferences table.
  static const String key = 'voice';

  @override
  Future<VoiceSettings> read() async {
    final SettingsRow? row = await _guard(
      () => (_database.select(
        _database.settingsRows,
      )..where(($SettingsRowsTable s) => s.key.equals(key))).getSingleOrNull(),
      'reading the voice settings failed',
    );
    return _decode(row?.value);
  }

  @override
  Future<void> write(VoiceSettings settings) {
    return _guard(
      () => _database
          .into(_database.settingsRows)
          .insertOnConflictUpdate(
            SettingsRowsCompanion.insert(key: key, value: _encode(settings)),
          ),
      'saving the voice settings failed',
    );
  }

  String _encode(VoiceSettings settings) => jsonEncode(<String, Object?>{
    'alwaysConfirmJiraWrites': settings.alwaysConfirmJiraWrites,
  });

  VoiceSettings _decode(String? raw) {
    if (raw == null) return const VoiceSettings();
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return const VoiceSettings();
      return VoiceSettings(
        alwaysConfirmJiraWrites: switch (decoded['alwaysConfirmJiraWrites']) {
          final bool value => value,
          // A key that is present but not a boolean is a key this app did not
          // write. The default stands rather than being coerced.
          _ => true,
        },
      );
    } on FormatException {
      return const VoiceSettings();
    }
  }

  Future<T> _guard<T>(Future<T> Function() operation, String message) async {
    try {
      return await operation();
    } on Failure {
      rethrow;
    } catch (_) {
      throw StorageFailure(message);
    }
  }
}
