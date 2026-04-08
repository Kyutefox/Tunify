/// Result type for explicit success/failure handling instead of try/catch.
/// Use [Result.ok] / [Result.err] or [Result.guard] for async.
sealed class Result<T, E> {
  const Result._();

  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  T? get okOrNull => switch (this) {
        Ok(:final value) => value,
        Err() => null,
      };

  E? get errOrNull => switch (this) {
        Ok() => null,
        Err(:final error) => error,
      };

  /// Pattern-matches on the result, calling [ok] for success or [err] for failure.
  R when<R>(
          {required R Function(T value) ok,
          required R Function(E error) err}) =>
      switch (this) {
        Ok(:final value) => ok(value),
        Err(:final error) => err(error),
      };

  /// Wrap a future: success -> Ok, exception -> Err with message.
  static Future<Result<T, String>> guard<T>(Future<T> Function() fn) async {
    try {
      final value = await fn();
      return Ok(value);
    } catch (e) {
      return Err('$e');
    }
  }
}

/// Successful result carrying [value].
final class Ok<T, E> extends Result<T, E> {
  const Ok(this.value) : super._();
  final T value;
}

/// Failed result carrying [error].
final class Err<T, E> extends Result<T, E> {
  const Err(this.error) : super._();
  final E error;
}
