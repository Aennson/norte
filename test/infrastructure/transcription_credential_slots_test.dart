import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/infrastructure/ai/secure_ai_credential_store.dart';
import 'package:norte/infrastructure/transcription/secure_transcription_credential_store.dart';

/// The three BYOK credentials occupy three distinct slots (BR-08).
///
/// Not a documented sprint case — added under `docs/project-rules.md` §5.4,
/// as the regression test for a bug Sprint 05 shipped in its first draft: the
/// composition root handed the **Whisper** store to `ScribeRealtimeEngine`, so
/// configuring voice commands would have silently overwritten the meeting
/// transcription key. Nothing caught it, because every other test injects a
/// store directly and no test exercised the wiring.
///
/// This suite pins the **slots**, and the named constructors are what pin the
/// wiring: `SecureTranscriptionCredentialStore` has no default constructor, so
/// the composition root cannot hand the wrong store to an engine by omission
/// the way it did. `main()` itself stays untested — it opens the real database
/// and the platform secure store — which is precisely why the mistake had to
/// be made impossible to express rather than merely asserted against.
void main() {
  // Never used: these tests read the store's slot and nothing else, so no
  // platform channel is ever touched.
  const FlutterSecureStorage storage = FlutterSecureStorage();

  test('Whisper, Scribe and Claude each have their own storage key', () {
    const Set<String> slots = <String>{
      SecureTranscriptionCredentialStore.whisperKey,
      SecureTranscriptionCredentialStore.scribeKey,
      SecureAiCredentialStore.apiKeyKey,
    };

    // Three providers, three slots. Two entries here would mean one key
    // overwrites another.
    expect(slots, hasLength(3));
  });

  test('the named constructors file under the slot they name', () {
    // There is no default constructor, so a caller cannot get the wrong store
    // by omission — the point of the named pair.
    expect(
      const SecureTranscriptionCredentialStore.whisper(storage).storageKey,
      SecureTranscriptionCredentialStore.whisperKey,
    );
    expect(
      const SecureTranscriptionCredentialStore.scribe(storage).storageKey,
      SecureTranscriptionCredentialStore.scribeKey,
    );
  });

  test('the slots are namespaced by provider, not by role', () {
    // `transcription.apiKey` would have been the shape that caused the bug:
    // a name describing what the key is *for* rather than which service it
    // belongs to invites exactly one slot for two providers.
    expect(SecureTranscriptionCredentialStore.whisperKey, contains('whisper'));
    expect(SecureTranscriptionCredentialStore.scribeKey, contains('scribe'));
  });
}
