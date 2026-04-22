import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _assetPath = 'assets/bundled_backend/tunify_rust_backend';
const _listenHost = '127.0.0.1';
const _listenPort = 8080;
const _bundledDbFilename = 'tunify.db';

Process? _backendProcess;

/// When the APK (or desktop build) ships `assets/bundled_backend/tunify_rust_backend`,
/// extract it and start the Tunify Rust server on this device so the app can use
/// `http://127.0.0.1:8080` as [ApiConfig] base URL.
Future<void> ensureBundledBackendIfPresent() async {
  if (kIsWeb) return;

  // iOS App Store builds cannot generally ship and exec arbitrary HTTP server binaries;
  // Android + desktop are supported here.
  if (Platform.isIOS) {
    return;
  }

  // Android: [TunifyApplication] starts the binary from nativeLibraryDir (SELinux allows
  // exec there). Asset extraction + Process.start from app data is blocked on many devices.
  if (Platform.isAndroid) {
    await _pollBundledHealth();
    return;
  }

  ByteData data;
  try {
    data = await rootBundle.load(_assetPath);
  } catch (_) {
    // Asset not packaged — dev builds or CI without a bundled binary.
    return;
  }

  if (_backendProcess != null) {
    return;
  }

  final supportDir = await getApplicationSupportDirectory();
  final execFile = File(p.join(supportDir.path, 'tunify_rust_backend'));
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  await execFile.writeAsBytes(bytes, flush: true);

  if (!Platform.isWindows) {
    final chmod = Platform.isAndroid ? '/system/bin/chmod' : 'chmod';
    final r = await Process.run(chmod, ['755', execFile.path]);
    if (r.exitCode != 0) {
      debugPrint(
        'BundledBackendLauncher: chmod failed: ${r.stderr} ${r.stdout}',
      );
    }
  }

  final env = Map<String, String>.from(Platform.environment);
  env['APP_RUNTIME_KIND'] = 'bundled';
  env['APP_HOST'] = _listenHost;
  env['APP_PORT'] = '$_listenPort';
  // Local YouTube catalog until user configures a hosted URL via Settings → gateway.
  env['APP_HOME_PROVIDER'] = 'youtube';
  final localDbFile = File(p.join(supportDir.path, _bundledDbFilename));
  env['DATABASE_URL'] = 'sqlite:${localDbFile.path}';

  try {
    _backendProcess = await Process.start(
      execFile.path,
      const <String>[],
      environment: env,
      workingDirectory: supportDir.path,
      mode: ProcessStartMode.detached,
    );
    final proc = _backendProcess!;
    final pid = proc.pid;
    proc.exitCode.then((code) {
      debugPrint('BundledBackendLauncher: process exited with code $code');
      if (_backendProcess?.pid == pid) {
        _backendProcess = null;
      }
    });
  } catch (e, st) {
    debugPrint('BundledBackendLauncher: failed to start process: $e\n$st');
    return;
  }

  await _pollBundledHealth();
}

Future<void> _pollBundledHealth() async {
  const healthUri = 'http://$_listenHost:$_listenPort/health';
  for (var i = 0; i < 60; i++) {
    try {
      final response = await http
          .get(Uri.parse(healthUri))
          .timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        debugPrint('BundledBackendLauncher: healthy at $healthUri');
        return;
      }
    } catch (_) {
      // still starting
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  debugPrint(
    'BundledBackendLauncher: timed out waiting for $healthUri — '
    'check that the binary was built for this OS/arch (e.g. aarch64-linux-android for most phones).',
  );
}
