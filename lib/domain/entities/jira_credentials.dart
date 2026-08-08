/// The Basic-auth pair the Jira Cloud REST API v3 expects
/// (`docs/architecture.md` §4.2 — API token in v1.0, OAuth later).
///
/// **BR-08** — an instance of this class may exist in memory and in secure
/// storage, and nowhere else: never in Drift, never in a preference file,
/// never in a log line. [toString] is overridden so that an accidental
/// interpolation cannot leak the token.
class JiraCredentials {
  const JiraCredentials({
    required this.siteUrl,
    required this.email,
    required this.apiToken,
  });

  /// Site base URL, e.g. `https://acme.atlassian.net`, without a trailing
  /// slash.
  final String siteUrl;

  /// Atlassian account e-mail — the Basic-auth username.
  final String email;

  /// Atlassian API token — the Basic-auth password.
  final String apiToken;

  /// `true` when all three fields carry something usable.
  bool get isComplete =>
      siteUrl.trim().isNotEmpty &&
      email.trim().isNotEmpty &&
      apiToken.trim().isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is JiraCredentials &&
      other.siteUrl == siteUrl &&
      other.email == email &&
      other.apiToken == apiToken;

  @override
  int get hashCode => Object.hash(siteUrl, email, apiToken);

  /// Deliberately redacted (BR-08).
  @override
  String toString() => 'JiraCredentials($siteUrl, $email, [REDACTED])';
}
