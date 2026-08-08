import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/failures/failure.dart';
import '../../domain/ports/transcription_credential_store.dart';

/// [TranscriptionCredentialStore] backed by the platform's secure store —
/// Keychain on iOS, Keystore on Android, DPAPI on Windows
/// (`docs/architecture.md` §2.1).
///
/// **BR-08** — the only place in the app that touches the Whisper key. Filed
/// under its own storage key, so clearing one provider's credential never
/// silently clears the other's.
class SecureTranscriptionCredentialStore
    implements TranscriptionCredentialStore {
  const SecureTranscriptionCredentialStore(this._storage);

  final FlutterSecureStorage _storage;

  /// Key the transcription API key is filed under.
  static const String apiKeyKey = 'transcription.whisper.apiKey';

  @override
  Future<String?> read() async {
    try {
      final String? key = await _storage.read(key: apiKeyKey);
      // An empty string is not a key: returning it would turn "no key
      // configured" into "key rejected", which points the user at the wrong
      // problem.
      if (key == null || key.trim().isEmpty) return null;
      return key;
    } catch (_) {
      throw const StorageFailure('reading the transcription API key failed');
    }
  }

  @override
  Future<void> write(String apiKey) async {
    try {
      await _storage.write(key: apiKeyKey, value: apiKey.trim());
    } catch (_) {
      throw const StorageFailure('storing the transcription API key failed');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: apiKeyKey);
    } catch (_) {
      throw const StorageFailure('clearing the transcription API key failed');
    }
  }
}
