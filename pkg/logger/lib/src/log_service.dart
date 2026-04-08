import 'logger_config_stub.dart' if (dart.library.io) 'logger_config_io.dart'
    as logger_config;

import 'package:logger/logger.dart';

final Logger _logger = logger_config.createAppLogger();

String _withTag(String message, String? tag) {
  if (tag != null && tag.isNotEmpty) return '[$tag] $message';
  return message;
}

void log(String message, {String level = 'INFO', String? tag, DateTime? when}) {
  final text = _withTag(message, tag);
  switch (level.toUpperCase()) {
    case 'TRACE':
      _logger.t(text);
      break;
    case 'DEBUG':
      _logger.d(text);
      break;
    case 'INFO':
      _logger.i(text);
      break;
    case 'WARN':
    case 'WARNING':
      _logger.w(text);
      break;
    case 'ERROR':
      _logger.e(text);
      break;
    case 'FATAL':
      _logger.f(text);
      break;
    default:
      _logger.i(text);
  }
}

void logDebug(String message, {String? tag}) =>
    log(message, level: 'DEBUG', tag: tag);

void logInfo(String message, {String? tag}) =>
    log(message, level: 'INFO', tag: tag);

void logWarning(String message, {String? tag}) =>
    log(message, level: 'WARN', tag: tag);

void logError(String message, {String? tag}) =>
    log(message, level: 'ERROR', tag: tag);
