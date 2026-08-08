/// Domain errors.
///
/// Layers never throw raw exceptions across a boundary — adapters translate
/// transport errors into a [Failure] and the use cases decide what the user
/// sees (`docs/project-rules.md` §6).
sealed class Failure {
  const Failure(this.message);

  /// Diagnostic message. Never carries a token, transcript or request body —
  /// logs redact payloads (`docs/architecture.md` §10).
  final String message;

  @override
  String toString() => '$runtimeType($message)';
}

/// No network, DNS failure, or the connection dropped mid-request.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'network unavailable']);
}

/// Credentials rejected or missing (HTTP 401/403).
final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'unauthorized']);
}

/// The requested resource does not exist (HTTP 404).
final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'not found']);
}

/// The Jira site has no issue with the key the user typed.
///
/// Distinct from [NotFoundFailure] because the user's next move is different:
/// there is nothing to retry and nothing to queue — the key is wrong, and the
/// UI says so next to the input (`sprint-02` validation rules, S02-UT-02).
final class JiraIssueNotFoundFailure extends Failure {
  const JiraIssueNotFoundFailure(this.issueKey)
    : super('no Jira issue with key $issueKey');

  /// The key that was not found.
  final String issueKey;
}

/// The site answered successfully with something that is not the API's JSON.
///
/// Almost always one thing: a self-hosted Jira behind single sign-on replies
/// to an unauthenticated REST call with **200 and an HTML login page** instead
/// of a 401. Distinct from [AuthFailure] because the fix is different — the
/// token is not wrong, it is not being allowed through — and distinct from
/// [EngineFailure] because the user can act on it.
final class JiraUnreadableResponseFailure extends Failure {
  const JiraUnreadableResponseFailure([
    super.message = 'the site did not answer with the REST API',
  ]);
}

/// An operation that needs Jira was attempted while the task carries no link.
///
/// A programming error rather than something the user can act on: the UI only
/// offers Jira actions on linked tasks.
final class NotLinkedFailure extends Failure {
  const NotLinkedFailure([super.message = 'task is not linked to Jira']);
}

/// The remote service is throttling us (HTTP 429).
final class RateLimitFailure extends Failure {
  const RateLimitFailure([super.message = 'rate limited', this.retryAfter]);

  /// How long the caller should wait before retrying, when the service says so.
  final Duration? retryAfter;
}

/// The operation exceeded its deadline.
final class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'timed out']);
}

/// An AI or transcription engine failed or returned an unusable response.
final class EngineFailure extends Failure {
  const EngineFailure([super.message = 'engine failure']);
}

/// The caller's input does not satisfy a use case's precondition — an empty
/// task title, a due date the entity cannot hold, an unknown id.
///
/// Raised **before** any port is touched: a use case that returns this has
/// written nothing (`sprint-01` S01-UT-02).
final class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'invalid input', this.field]);

  /// Name of the offending field, when a single one can be blamed — the UI
  /// uses it to place the error next to the right input. `null` when the
  /// failure is not attributable to one field.
  final String? field;
}

/// The local database could not complete an operation.
final class StorageFailure extends Failure {
  const StorageFailure([super.message = 'local storage failure']);
}

/// The user has not supplied a key for the remote AI engine.
///
/// Norte is BYOK in v1.0 (`docs/architecture.md` §7.2): there is no key until
/// the user pastes one into Settings. Distinct from [AuthFailure], which means
/// a key exists and was rejected — the two send the user to different places,
/// so the UI must be able to tell them apart (`sprint-03` validation rules).
final class MissingApiKeyFailure extends Failure {
  const MissingApiKeyFailure([
    super.message = 'no Claude API key is configured — add one in Settings',
  ]);
}

/// The engine answered, but not with a summary this app can read.
///
/// Raised only after the retry the policy allows has also failed
/// (`sprint-03` validation rules, S03-UT-06). A partial or invented summary is
/// never returned in its place: a meeting summary that quietly dropped half a
/// retro is worse than no summary at all, because nothing about it looks wrong.
final class AiResponseFailure extends Failure {
  const AiResponseFailure([
    super.message = 'the AI engine returned an unreadable summary',
  ]);
}

/// The transcription engine failed, or answered with something unreadable.
///
/// Distinct from [EngineFailure] because of what the UI owes the user when it
/// happens: the recording is still on disk and the operation can be retried
/// without speaking it all again, which is the whole point of the sprint's
/// retry rule (S04-UT-02). A generic engine failure carries no such promise.
final class TranscriptionFailure extends Failure {
  const TranscriptionFailure([
    super.message = 'the audio could not be transcribed',
  ]);
}

/// The user has not granted access to the microphone.
///
/// Not an error to retry: nothing the app does changes the answer until the
/// user changes it. The UI explains why the permission is needed and offers a
/// way into the system settings — and, because [isPermanentlyDenied] tells the
/// two apart, it can ask again in-place when asking again would actually
/// produce a prompt (S04-E2E-02).
final class MicrophonePermissionFailure extends Failure {
  const MicrophonePermissionFailure({this.isPermanentlyDenied = false})
    : super('microphone access was not granted');

  /// `true` when the platform will no longer show its prompt, so the only
  /// route left is the system settings.
  final bool isPermanentlyDenied;
}

/// Audio capture itself failed — no input device, the encoder refused, or the
/// platform ended the session.
///
/// Separate from [MicrophonePermissionFailure] because permission is the
/// user's to give and this is not: there is nothing for them to grant, so the
/// UI offers a retry rather than a trip to settings.
final class RecordingFailure extends Failure {
  const RecordingFailure([super.message = 'the recording could not be made']);
}

/// The action item already produced a task.
///
/// Conversion is one-way and once-only: the item records the id of the task it
/// created, and a second attempt is refused rather than silently making a
/// duplicate (S03-UT-05).
final class AlreadyConvertedFailure extends Failure {
  const AlreadyConvertedFailure(this.taskId)
    : super('this action item is already task $taskId');

  /// The task the item produced the first time.
  final String taskId;
}
