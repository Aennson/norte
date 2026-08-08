import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/jira_credentials.dart';
import '../../domain/failures/failure.dart';
import '../../domain/ports/jira_credential_store.dart';

/// [JiraCredentialStore] backed by the platform's secure store — Keychain on
/// iOS, Keystore on Android, DPAPI on Windows (`docs/architecture.md` §2.1).
///
/// **BR-08** — this class is the only place in the app that touches a Jira
/// token, and the store behind it is the only place one is written. Note what
/// this rules out: the token is not in Drift, so a database dump does not
/// contain it; not in a preferences file; and never interpolated into a
/// message, which is why the [StorageFailure]s below say what failed without
/// saying what it was operating on.
///
/// The three fields are stored under separate keys rather than as one encoded
/// blob, so a partially written set is detectable instead of silently
/// unparseable.
class SecureJiraCredentialStore implements JiraCredentialStore {
  const SecureJiraCredentialStore(this._storage);

  final FlutterSecureStorage _storage;

  static const String siteUrlKey = 'jira.siteUrl';
  static const String emailKey = 'jira.email';
  static const String apiTokenKey = 'jira.apiToken';
  static const String deploymentKey = 'jira.deployment';

  @override
  Future<JiraCredentials?> read() async {
    try {
      final String? siteUrl = await _storage.read(key: siteUrlKey);
      final String? email = await _storage.read(key: emailKey);
      final String? apiToken = await _storage.read(key: apiTokenKey);
      if (siteUrl == null || email == null || apiToken == null) return null;
      final String? deployment = await _storage.read(key: deploymentKey);
      return JiraCredentials(
        siteUrl: siteUrl,
        email: email,
        apiToken: apiToken,
        // A set written before DEC-012 has no deployment recorded, and
        // Cloud is what it was: the default keeps it readable.
        deployment: JiraDeployment.values.firstWhere(
          (JiraDeployment value) => value.name == deployment,
          orElse: () => JiraDeployment.cloud,
        ),
      );
    } catch (_) {
      throw const StorageFailure('reading the Jira credentials failed');
    }
  }

  @override
  Future<void> write(JiraCredentials credentials) async {
    try {
      await _storage.write(key: siteUrlKey, value: credentials.siteUrl);
      await _storage.write(key: emailKey, value: credentials.email);
      await _storage.write(key: apiTokenKey, value: credentials.apiToken);
      await _storage.write(
        key: deploymentKey,
        value: credentials.deployment.name,
      );
    } catch (_) {
      throw const StorageFailure('storing the Jira credentials failed');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: siteUrlKey);
      await _storage.delete(key: emailKey);
      await _storage.delete(key: apiTokenKey);
      await _storage.delete(key: deploymentKey);
    } catch (_) {
      throw const StorageFailure('clearing the Jira credentials failed');
    }
  }
}
