import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/failures/failure.dart';
import '../../domain/ports/transcription_credential_store.dart';

/// [TranscriptionCredentialStore] backed by the platform's secure store —
/// Keychain on iOS, Keystore on Android, DPAPI on Windows
/// (`docs/architecture.md` §2.1).
///
/// **BR-08** — the only place in the app that touches a transcription key.
///
/// **There are two of them, under two storage keys**, and the distinction is
/// load-bearing: batch transcription is Whisper (OpenAI) and realtime is Scribe
/// (ElevenLabs). They are different services with different credentials, and a
/// user may hold one and not the other. Sharing a slot would mean configuring
/// voice commands silently broke meeting transcription — which is exactly what
/// Sprint 05 shipped in its first draft, because the composition root handed
/// the Whisper store to both engines and no test exercised that wiring.
///
/// Construct through [SecureTranscriptionCredentialStore.whisper] or
/// [SecureTranscriptionCredentialStore.scribe]; there is no default, so a
/// caller cannot get the wrong one by omission.
class SecureTranscriptionCredentialStore
    implements TranscriptionCredentialStore {
  const SecureTranscriptionCredentialStore._(this._storage, this.storageKey);

  /// The batch transcription key (Whisper).
  const SecureTranscriptionCredentialStore.whisper(FlutterSecureStorage storage)
    : this._(storage, whisperKey);

  /// The realtime transcription key (Scribe).
  const SecureTranscriptionCredentialStore.scribe(FlutterSecureStorage storage)
    : this._(storage, scribeKey);

  final FlutterSecureStorage _storage;

  /// Where this instance files its key.
  final String storageKey;

  /// Slot of the Whisper key.
  static const String whisperKey = 'transcription.whisper.apiKey';

  /// Slot of the Scribe key.
  static const String scribeKey = 'transcription.scribe.apiKey';

  @override
  Future<String?> read() async {
    try {
      final String? key = await _storage.read(key: storageKey);
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
      await _storage.write(key: storageKey, value: apiKey.trim());
    } catch (_) {
      throw const StorageFailure('storing the transcription API key failed');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: storageKey);
    } catch (_) {
      throw const StorageFailure('clearing the transcription API key failed');
    }
  }
}
