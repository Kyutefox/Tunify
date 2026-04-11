import 'package:tunify/v2/core/errors/failures.dart';

/// Result type for error handling
class Result<T> {
  final T? _data;
  final Failure? _failure;

  const Result._(this._data, this._failure);

  factory Result.success(T data) => Result._(data, null);
  factory Result.failure(Failure failure) => Result._(null, failure);

  bool get isSuccess => _failure == null;
  bool get isFailure => _failure != null;

  T get dataOrThrow {
    if (isFailure) {
      throw Exception(_failure?.message);
    }
    return _data as T;
  }

  T? get data => _data;
  Failure? get failure => _failure;

  R fold<R>(
    R Function(T data) onSuccess,
    R Function(Failure failure) onFailure,
  ) {
    if (isSuccess) {
      return onSuccess(_data as T);
    }
    return onFailure(_failure!);
  }

  Result<R> map<R>(R Function(T data) mapper) {
    if (isSuccess) {
      return Result.success(mapper(_data as T));
    }
    return Result.failure(_failure!);
  }
}
