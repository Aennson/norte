/// Which kind of Jira a site is.
///
/// The two products are not the same API, and the differences are exactly the
/// ones an HTTP client cannot paper over: the REST version in the path, the
/// authentication scheme, and whether a comment body is a document or a
/// string. So the app asks rather than guesses — a URL is not reliable
/// evidence either way, since a Data Center instance can live at any hostname
/// (see `docs/reports/decisions.md` — DEC-012).
enum JiraDeployment {
  /// Atlassian-hosted, `*.atlassian.net`. REST v3, Basic auth with an account
  /// e-mail and an API token, comment bodies in Atlassian Document Format.
  cloud,

  /// Self-hosted Jira Server or Data Center. REST v2, a Personal Access Token
  /// sent as `Bearer`, comment bodies as plain text.
  dataCenter;

  /// `true` when the account e-mail is part of the credential.
  ///
  /// A PAT authenticates on its own; asking a Data Center user for an e-mail
  /// would be asking for something the request will not carry.
  bool get needsEmail => this == JiraDeployment.cloud;

  /// Version segment of the REST path.
  String get restVersion => switch (this) {
    JiraDeployment.cloud => '3',
    JiraDeployment.dataCenter => '2',
  };
}

/// What the app needs in order to talk to one Jira site
/// (`docs/architecture.md` §4.2 — token in v1.0, OAuth later).
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
    this.deployment = JiraDeployment.cloud,
  });

  /// Site base URL, e.g. `https://acme.atlassian.net` or
  /// `https://jira.acme.com`, without a trailing slash.
  final String siteUrl;

  /// Atlassian account e-mail — the Basic-auth username on Cloud, and unused
  /// on Data Center.
  final String email;

  /// Cloud API token, or Data Center Personal Access Token.
  final String apiToken;

  /// Which product [siteUrl] is running.
  final JiraDeployment deployment;

  /// `true` when every field this deployment needs carries something usable.
  bool get isComplete =>
      siteUrl.trim().isNotEmpty &&
      apiToken.trim().isNotEmpty &&
      (!deployment.needsEmail || email.trim().isNotEmpty);

  /// Who the app is acting as, for display. Falls back to the site on Data
  /// Center, where a PAT names nobody.
  String get accountLabel => email.trim().isEmpty ? siteUrl : email;

  @override
  bool operator ==(Object other) =>
      other is JiraCredentials &&
      other.siteUrl == siteUrl &&
      other.email == email &&
      other.apiToken == apiToken &&
      other.deployment == deployment;

  @override
  int get hashCode => Object.hash(siteUrl, email, apiToken, deployment);

  /// Deliberately redacted (BR-08).
  @override
  String toString() =>
      'JiraCredentials($siteUrl, ${deployment.name}, $email, [REDACTED])';
}
