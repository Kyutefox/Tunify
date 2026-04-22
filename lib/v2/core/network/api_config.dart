/// Tunify HTTP API base URL (no trailing slash).
///
/// **APK + bundled Rust backend on the same device:** default is loopback on the phone
/// (`http://127.0.0.1:8080`). [main] starts the bundled binary when the asset is present.
///
/// **Dev / emulator talking to a backend on your Mac:** override compile-time, e.g.
/// `--dart-define=TUNIFY_API_BASE_URL=http://10.0.2.2:8080` (Android emulator → host).
class ApiConfig {
  const ApiConfig({required this.baseUrl});

  final String baseUrl;

  static ApiConfig fromEnvironment() {
    const raw = String.fromEnvironment(
      'TUNIFY_API_BASE_URL',
      defaultValue: 'http://127.0.0.1:8080',
    );
    final trimmed = raw.trim();
    final noSlash = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    return ApiConfig(baseUrl: noSlash);
  }
}
