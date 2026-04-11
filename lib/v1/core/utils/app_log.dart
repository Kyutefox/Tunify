import 'dart:developer' as developer;

String _withTag(String message, String? tag) {
  if (tag != null && tag.isNotEmpty) return '[$tag] $message';
  return message;
}

/// Debug / diagnostic logging (no extra package). Uses [developer.log] so output
/// appears in DevTools and debug consoles.
void log(String message, {String level = 'INFO', String? tag, DateTime? when}) {
  final text = _withTag(message, tag);
  final t = when ?? DateTime.now();
  switch (level.toUpperCase()) {
    case 'TRACE':
    case 'DEBUG':
      developer.log(text, name: tag ?? 'Tunify', time: t, level: 500);
    case 'WARN':
    case 'WARNING':
      developer.log(text, name: tag ?? 'Tunify', time: t, level: 900);
    case 'ERROR':
    case 'FATAL':
      developer.log(text, name: tag ?? 'Tunify', time: t, level: 1000);
    default:
      developer.log(text, name: tag ?? 'Tunify', time: t);
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
