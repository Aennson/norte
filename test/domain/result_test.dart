import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/failures/result.dart';

/// S01-UT-02 — the outcome type every use case returns.
void main() {
  const Failure failure = ValidationFailure('bad input', 'title');

  test('S01-UT-02: Ok exposes its value and no failure', () {
    const Result<int> result = Ok<int>(7);

    expect(result.isOk, isTrue);
    expect(result.valueOrNull, 7);
    expect(result.failureOrNull, isNull);
    expect(result.toString(), 'Ok(7)');
  });

  test('S01-UT-02: Err exposes its failure and no value', () {
    const Result<int> result = Err<int>(failure);

    expect(result.isOk, isFalse);
    expect(result.valueOrNull, isNull);
    expect(result.failureOrNull, same(failure));
    expect(result.toString(), contains('ValidationFailure'));
  });

  test('S01-UT-02: results compare by content, not by identity', () {
    expect(const Ok<int>(7), const Ok<int>(7));
    expect(const Ok<int>(7).hashCode, const Ok<int>(7).hashCode);
    expect(const Ok<int>(7), isNot(const Ok<int>(8)));

    expect(const Err<int>(failure), const Err<int>(failure));
    expect(const Err<int>(failure).hashCode, const Err<int>(failure).hashCode);
    expect(const Err<int>(failure), isNot(const Err<int>(NetworkFailure())));

    // A value and a failure are never equal, whatever they carry.
    expect(const Ok<int>(7), isNot(const Err<int>(failure)));
  });

  test('S01-UT-02: a switch over Result is exhaustive without a default', () {
    String describe(Result<int> result) => switch (result) {
      Ok<int>(:final int value) => 'ok:$value',
      Err<int>(:final Failure failure) => 'err:${failure.message}',
    };

    expect(describe(const Ok<int>(7)), 'ok:7');
    expect(describe(const Err<int>(failure)), 'err:bad input');
  });
}
