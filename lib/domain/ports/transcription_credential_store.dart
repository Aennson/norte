/// Storage for the user's transcription API key.
///
/// **BR-08** — the key lives in the platform's secure store and nowhere else.
/// Norte is BYOK (`docs/architecture.md` §7.2), and transcription is a second
/// provider with a second key: a user may hold a Claude key and no Whisper
/// key, or the reverse, and folding the two together would make configuring
/// one look like configuring both.
///
/// **Contract** — identical to `AiCredentialStore`, deliberately:
/// * [read] returns `null` when no key has been stored.
/// * [write] replaces whatever was there.
/// * [clear] is idempotent.
/// * A store error surfaces as a thrown `StorageFailure` whose message never
///   contains the key.
abstract interface class TranscriptionCredentialStore {
  /// The stored key, or `null` when the user has not configured one.
  Future<String?> read();

  /// Stores [apiKey], replacing any previous value.
  Future<void> write(String apiKey);

  /// Removes the stored key.
  Future<void> clear();
}
