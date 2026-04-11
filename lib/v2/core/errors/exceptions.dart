/// Base exception class
abstract class AppException implements Exception {
  final String message;
  final int? code;

  AppException(this.message, {this.code});

  @override
  String toString() => 'AppException: $message';
}

/// Network exception
class NetworkException extends AppException {
  NetworkException(super.message, {super.code});
}

/// Server exception
class ServerException extends AppException {
  ServerException(super.message, {super.code});
}

/// Cache exception
class CacheException extends AppException {
  CacheException(super.message);
}

/// Validation exception
class ValidationException extends AppException {
  ValidationException(super.message);
}
