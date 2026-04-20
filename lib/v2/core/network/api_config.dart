/// Tunify HTTP API base URL (no trailing slash).
///
/// Override at compile time, e.g. Android emulator → host loopback:
/// `--dart-define=TUNIFY_API_BASE_URL=http://10.0.2.2:8080`
class ApiConfig {
  const ApiConfig({required this.baseUrl});

  final String baseUrl;

  static ApiConfig fromEnvironment() {
    const raw = String.fromEnvironment(
      'TUNIFY_API_BASE_URL',
      defaultValue: 'http://192.168.1.6:8080',
    );
    final trimmed = raw.trim();
    final noSlash = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    return ApiConfig(baseUrl: noSlash);
  }
}
