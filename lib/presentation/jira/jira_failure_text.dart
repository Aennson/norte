import '../../domain/failures/failure.dart';
import '../../l10n/generated/app_localizations.dart';

/// What to tell the user about [failure].
///
/// Every branch names something the user could act on — check the key, get a
/// connection, fix the credentials, wait a moment. `Failure.message` itself is
/// diagnostic English for the log and never reaches the screen, which is also
/// how BR-11 stays satisfied: what the user reads always comes from an ARB
/// resource.
String jiraFailureText(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      JiraIssueNotFoundFailure(:final String issueKey) =>
        l10n.jiraErrorIssueNotFound(issueKey),
      NetworkFailure() || TimeoutFailure() => l10n.jiraErrorOffline,
      AuthFailure() => l10n.jiraErrorAuth,
      RateLimitFailure() => l10n.jiraErrorRateLimited,
      _ => l10n.jiraErrorGeneric,
    };
