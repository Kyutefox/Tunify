import 'dart:io' show File;

/// Writes the raw `next` API JSON response to a local debug file.
///
/// This is only used in IO builds to aid troubleshooting by persisting the
/// last response body. Errors while writing are silently ignored to avoid
/// impacting application behaviour.
void writeNextResponseDebugFile(String jsonStr) {
  try {
    final f = File('next_api_response_debug.json');
    f.writeAsStringSync(jsonStr);
  } catch (_) {
    // Silently ignore write errors; debug file is best-effort.
  }
}
