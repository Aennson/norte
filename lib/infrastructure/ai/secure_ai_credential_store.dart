import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/failures/failure.dart';
import '../../domain/ports/ai_credential_store.dart';

/// [AiCredentialStore] backed by the platform's secure store — Keychain on
/// iOS, Keystore on Android, DPAPI on Windows (`docs/architecture.md` §2.1).
///
/// **BR-08** — the only place in the app that touches the Claude key. Not in
/// Drift, so a database dump does not contain it; not in a preferences file;
/// never interpolated into a message, which is why the [StorageFailure]s below
/// say what failed without saying what it was operating on.
class SecureAiCredentialStore implements AiCredentialStore {
  const SecureAiCredentialStore(this._storage);

  final FlutterSecureStorage _storage;

  /// Key the Claude API key is filed under.
  static const String apiKeyKey = 'ai.claude.apiKey';

  @override
  Future<String?> read() async {
    try {
      final String? key = await _storage.read(key: apiKeyKey);
      // An empty string is not a key. Returning it would turn "no key
      // configured" into "key rejected", which points the user at the wrong
      // problem.
      if (key == null || key.trim().isEmpty) return null;
      return key;
    } catch (_) {
      throw const StorageFailure('reading the Claude API key failed');
    }
  }

  @override
  Future<void> write(String apiKey) async {
    try {
      await _storage.write(key: apiKeyKey, value: apiKey.trim());
    } catch (_) {
      throw const StorageFailure('storing the Claude API key failed');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: apiKeyKey);
    } catch (_) {
      throw const StorageFailure('clearing the Claude API key failed');
    }
  }
}
