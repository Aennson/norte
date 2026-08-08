import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/failures/failure.dart';

/// S01-UT-02 — the domain error hierarchy (`docs/project-rules.md` §6).
void main() {
  test('S01-UT-02: every failure carries a default diagnostic message', () {
    const List<Failure> failures = <Failure>[
      NetworkFailure(),
      AuthFailure(),
      NotFoundFailure(),
      RateLimitFailure(),
      TimeoutFailure(),
      EngineFailure(),
      ValidationFailure(),
      StorageFailure(),
    ];

    for (final Failure failure in failures) {
      expect(
        failure.message,
        isNotEmpty,
        reason: '${failure.runtimeType} must explain itself',
      );
      expect(failure.toString(), contains(failure.runtimeType.toString()));
      expect(failure.toString(), contains(failure.message));
    }
  });

  test('S01-UT-02: a message may be overridden without losing the type', () {
    const Failure failure = StorageFailure('saving task 7 failed');

    expect(failure.message, 'saving task 7 failed');
    expect(failure, isA<StorageFailure>());
  });

  test('S01-UT-02: RateLimitFailure can carry the retry delay', () {
    const RateLimitFailure withDelay = RateLimitFailure(
      'slow down',
      Duration(seconds: 30),
    );

    expect(withDelay.retryAfter, const Duration(seconds: 30));
    expect(const RateLimitFailure().retryAfter, isNull);
  });

  test('S01-UT-02: ValidationFailure can blame a single field', () {
    const ValidationFailure onField = ValidationFailure('required', 'title');

    expect(onField.field, 'title');
    expect(const ValidationFailure().field, isNull);
  });
}
