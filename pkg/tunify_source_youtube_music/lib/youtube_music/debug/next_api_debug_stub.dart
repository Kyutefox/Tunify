/// No‑op stub for [writeNextResponseDebugFile] used on non‑IO platforms.
///
/// This keeps the API surface consistent without performing any filesystem
/// access when running in environments such as Flutter Web.
void writeNextResponseDebugFile(String jsonStr) {}
