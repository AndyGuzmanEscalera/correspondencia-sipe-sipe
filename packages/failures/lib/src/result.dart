import 'package:equatable/equatable.dart';

/// Result<T, F> - a Rust-style enum.
///
/// Use [when] to handle both cases explicitly:
/// ```dart
/// result.when(
///   ok: (value) => ...,
///   err: (failure) => ...,
/// );
/// ```
sealed class Result<T, F> extends Equatable {
  const Result();

  bool get isOk => this is Ok<T, F>;
  bool get isErr => this is Err<T, F>;

  /// Pattern-match on the result.
  R when<R>({
    required R Function(T value) ok,
    required R Function(F failure) err,
  }) {
    final self = this;
    if (self is Ok<T, F>) return ok(self.value);
    if (self is Err<T, F>) return err(self.failure);
    throw StateError('Result.when: unreachable');
  }

  /// Returns the success value or null.
  T? valueOrNull() {
    final self = this;
    return self is Ok<T, F> ? self.value : null;
  }

  /// Returns the failure or null.
  F? failureOrNull() {
    final self = this;
    return self is Err<T, F> ? self.failure : null;
  }

  @override
  List<Object?> get props => const [];
}

class Ok<T, F> extends Result<T, F> {
  const Ok(this.value);
  final T value;

  @override
  List<Object?> get props => [value];
}

class Err<T, F> extends Result<T, F> {
  const Err(this.failure);
  final F failure;

  @override
  List<Object?> get props => [failure];
}

Result<T, F> ok<T, F>(T value) => Ok<T, F>(value);
Result<T, F> err<T, F>(F failure) => Err<T, F>(failure);
