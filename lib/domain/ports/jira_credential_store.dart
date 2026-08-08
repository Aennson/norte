import '../entities/jira_credentials.dart';

/// Where the Jira API token lives.
///
/// **BR-08** — the only implementation allowed in production is backed by the
/// platform's secure store (Keychain / Keystore / DPAPI,
/// `docs/architecture.md` §2.1). This port exists so that no layer above
/// infrastructure has to know that, and so a test can supply an in-memory
/// stand-in without a token ever touching Drift or a preferences file.
///
/// **Contract**
/// * [read] returns `null` when the user has not configured a site yet — not
///   a failure.
/// * [write] replaces whatever was stored; there is one credential set.
/// * [clear] is idempotent.
/// * A store error surfaces as a thrown `StorageFailure`. The message never
///   contains the token.
abstract interface class JiraCredentialStore {
  /// The stored credentials, or `null` when Jira is not configured.
  Future<JiraCredentials?> read();

  /// Stores [credentials], replacing any previous set.
  Future<void> write(JiraCredentials credentials);

  /// Forgets the stored credentials.
  Future<void> clear();
}
