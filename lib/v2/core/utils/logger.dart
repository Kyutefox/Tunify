import 'dart:developer' as dev;

/// Simple logger utility
class Logger {
  Logger._();

  static const String _defaultTag = 'Tunify';

  static void debug(String message, {String? tag}) {
    dev.log(
      message,
      name: tag ?? _defaultTag,
      time: DateTime.now(),
    );
  }

  static void info(String message, {String? tag}) {
    dev.log(
      message,
      name: tag ?? _defaultTag,
      time: DateTime.now(),
    );
  }

  static void warning(String message, {String? tag}) {
    dev.log(
      message,
      name: tag ?? _defaultTag,
      time: DateTime.now(),
      level: 1000,
    );
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    dev.log(
      message,
      name: tag ?? _defaultTag,
      time: DateTime.now(),
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
