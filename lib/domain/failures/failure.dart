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
