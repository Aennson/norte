import 'dart:convert';

import '../../domain/entities/ai_engine_settings.dart';
import '../../domain/failures/failure.dart';
import '../../domain/ports/ai_engine_settings_store.dart';
import 'norte_database.dart';

/// Drift-backed [AiEngineSettingsStore], two JSON rows in the `settings` table.
///
/// **No migration.** `settings` is a key-value table and this store simply owns
/// two more keys, exactly as `DriftVoiceSettingsStore` owns one. A new column
/// per preference would have meant a schema version for every checkbox.
///
/// **Preferences and counts are separate rows on purpose.** They are written at
/// completely different rates — a preference when the user opens Settings, a
/// count after every single AI answer — and sharing a row would make each
/// answer rewrite the user's choices. A crash mid-write would then be able to
/// lose a preference to a counter increment, which is a bad trade in the
/// direction that matters.
///
/// Anything unreadable reads as the defaults, for the reason the voice store
/// gives: refusing to start over a malformed preference locks the user out of
/// their own data.
class DriftAiEngineSettingsStore implements AiEngineSettingsStore {
  const DriftAiEngineSettingsStore(this._database);

  final NorteDatabase _database;

  /// Key holding the user's choices.
  static const String settingsKey = 'aiEngine';

  /// Key holding the per-engine answer counts.
  static const String usageKey = 'aiEngineUsage';

  @override
  Future<AiEngineSettings> read() async {
    final String? raw = await _readRow(settingsKey, 'reading the AI engine settings failed');
    return _decodeSettings(raw);
  }

  @override
  Future<void> write(AiEngineSettings settings) {
    return _writeRow(
      settingsKey,
      jsonEncode(<String, Object?>{
        'engine': settings.engine.name,
        'fallbackEnabled': settings.fallbackEnabled,
        'models': settings.models,
      }),
      'saving the AI engine settings failed',
    );
  }

  @override
  Future<AiEngineUsage> readUsage() async {
    final String? raw = await _readRow(usageKey, 'reading the AI engine usage failed');
    return _decodeUsage(raw);
  }

  @override
  Future<void> recordAnswer(String engineId) async {
    // Read-modify-write rather than a SQL increment, because the row is JSON
    // and the alternative would be a column per engine — which would need a
    // migration every time an adapter is added.
    final AiEngineUsage current = await readUsage();
    final AiEngineUsage next = current.increment(engineId);
    await _writeRow(
      usageKey,
      jsonEncode(next.counts),
      'saving the AI engine usage failed',
    );
  }

  Future<String?> _readRow(String key, String message) async {
    final SettingsRow? row = await _guard(
      () => (_database.select(
        _database.settingsRows,
      )..where(($SettingsRowsTable s) => s.key.equals(key))).getSingleOrNull(),
      message,
    );
    return row?.value;
  }

  Future<void> _writeRow(String key, String value, String message) {
    return _guard(
      () => _database
          .into(_database.settingsRows)
          .insertOnConflictUpdate(
            SettingsRowsCompanion.insert(key: key, value: value),
          ),
      message,
    );
  }

  AiEngineSettings _decodeSettings(String? raw) {
    final Map<String, Object?>? decoded = _decodeMap(raw);
    if (decoded == null) return const AiEngineSettings();

    return AiEngineSettings(
      // An engine name this build does not know — a preference written by a
      // newer version, or a name that was renamed — falls back to the default
      // rather than throwing. The stored row is left alone, so downgrading and
      // upgrading again restores the choice.
      engine: _engineNamed(decoded['engine']),
      fallbackEnabled: switch (decoded['fallbackEnabled']) {
        final bool value => value,
        _ => true,
      },
      models: switch (decoded['models']) {
        final Map<String, Object?> map => <String, String>{
          for (final MapEntry<String, Object?> entry in map.entries)
            if (entry.value case final String model) entry.key: model,
        },
        _ => const <String, String>{},
      },
    );
  }

  /// The engine with this stored name, or the default.
  ///
  /// A name this build does not know — a preference written by a newer version
  /// — reads as the default rather than throwing, and the stored row is left
  /// untouched, so downgrading and upgrading again restores the choice.
  EnginePref _engineNamed(Object? stored) {
    for (final EnginePref pref in EnginePref.values) {
      if (pref.name == stored) return pref;
    }
    return EnginePref.claudeApi;
  }

  AiEngineUsage _decodeUsage(String? raw) {
    final Map<String, Object?>? decoded = _decodeMap(raw);
    if (decoded == null) return const AiEngineUsage();
    return AiEngineUsage(<String, int>{
      for (final MapEntry<String, Object?> entry in decoded.entries)
        if (entry.value case final num count) entry.key: count.toInt(),
    });
  }

  Map<String, Object?>? _decodeMap(String? raw) {
    if (raw == null) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      return decoded is Map<String, Object?> ? decoded : null;
    } on FormatException {
      return null;
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
