import 'bundled_backend_launcher_stub.dart'
    if (dart.library.io) 'bundled_backend_launcher_io.dart' as bundled_impl;

/// Starts the packaged Rust backend when its asset exists (Android APK / desktop).
///
/// Same-device HTTP base URL: `http://127.0.0.1:8080` — see [ApiConfig.fromEnvironment].
Future<void> ensureBundledBackendIfPresent() =>
    bundled_impl.ensureBundledBackendIfPresent();
