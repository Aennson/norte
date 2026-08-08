import 'failure.dart';

/// The outcome of a use case: either a value or a [Failure].
///
/// Layers never throw across a boundary (`docs/project-rules.md` §6), so every
/// use case returns a [Result] and the caller pattern-matches on it:
///
/// ```dart
/// switch (await createTask(title: title)) {
///   case Ok<Task>(:final value) => _show(value),
///   case Err<Task>(:final failure) => _showError(failure),
/// }
/// ```
///
/// The type is sealed, so the analyzer rejects a `switch` that forgets a case.
sealed class Result<T> {
  const Result();

  /// `true` for [Ok].
  bool get isOk => this is Ok<T>;

  /// The value, or `null` when this is an [Err].
  T? get valueOrNull => switch (this) {
    Ok<T>(:final T value) => value,
    Err<T>() => null,
  };

  /// The failure, or `null` when this is an [Ok].
  Failure? get failureOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(:final Failure failure) => failure,
  };
}

/// A successful outcome carrying [value].
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      other is Ok<T> &&
      other.runtimeType == runtimeType &&
      other.value == value;

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => 'Ok($value)';
}

/// A failed outcome carrying [failure]. Nothing was written.
final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) =>
      other is Err<T> &&
      other.runtimeType == runtimeType &&
      other.failure == failure;

  @override
  int get hashCode => Object.hash(runtimeType, failure);

  @override
  String toString() => 'Err($failure)';
}
