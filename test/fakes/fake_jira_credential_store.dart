import 'package:norte/domain/entities/jira_credentials.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/jira_credential_store.dart';

/// In-memory [JiraCredentialStore].
///
/// Stands in for the platform secure store, which no test may touch: a widget
/// test has no Keychain, and a CI runner has no DPAPI. Holding the credentials
/// in a field is also the point of the port — BR-08 is about where the *app*
/// puts a token, and here the answer is "nowhere that outlives the test".
class FakeJiraCredentialStore implements JiraCredentialStore {
  FakeJiraCredentialStore([this._credentials]);

  /// A store already holding usable synthetic credentials.
  factory FakeJiraCredentialStore.configured({
    String siteUrl = 'https://example.atlassian.net',
    String email = 'dev@example.com',
    String apiToken = 'synthetic-token',
  }) => FakeJiraCredentialStore(
    JiraCredentials(siteUrl: siteUrl, email: email, apiToken: apiToken),
  );

  JiraCredentials? _credentials;

  /// Number of times [write] has been called.
  int writes = 0;

  /// Number of times [clear] has been called.
  int clears = 0;

  /// When set, every call throws it.
  Failure? failWith;

  @override
  Future<JiraCredentials?> read() async {
    _guard();
    return _credentials;
  }

  @override
  Future<void> write(JiraCredentials credentials) async {
    _guard();
    writes++;
    _credentials = credentials;
  }

  @override
  Future<void> clear() async {
    _guard();
    clears++;
    _credentials = null;
  }

  void _guard() {
    final Failure? failure = failWith;
    if (failure != null) throw failure;
  }
}
