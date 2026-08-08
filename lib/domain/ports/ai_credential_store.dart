/// Storage for the user's Claude API key.
///
/// **BR-08** — the key lives in the platform's secure store and nowhere else:
/// not in Drift, not in a preferences file, not in a log, and not in a field
/// on the adapter that uses it. Norte is BYOK in v1.0
/// (`docs/architecture.md` §7.2), so this is the user's own key and the app
/// holds it on their behalf.
///
/// Modelled as its own port rather than folded into `JiraCredentialStore`:
/// they are different secrets with different lifetimes, and a user may
/// perfectly well configure one and not the other.
///
/// **Contract**
/// * [read] returns `null` when no key has been stored — that is the ordinary
///   state of a fresh install, not an error.
/// * [write] replaces whatever was there.
/// * [clear] is idempotent.
/// * A store error surfaces as a thrown `StorageFailure` whose message never
///   contains the key.
abstract interface class AiCredentialStore {
  /// The stored key, or `null` when the user has not configured one.
  Future<String?> read();

  /// Stores [apiKey], replacing any previous value.
  Future<void> write(String apiKey);

  /// Removes the stored key.
  Future<void> clear();
}
