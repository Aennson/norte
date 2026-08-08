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
