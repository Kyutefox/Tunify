import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify_logger/tunify_logger.dart';

/// Provides real-time network connectivity status.
/// Emits true when device is connected, false when offline.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  final initialResult = await connectivity.checkConnectivity();
  yield _isConnected(initialResult);

  await for (final result in connectivity.onConnectivityChanged) {
    final isConnected = _isConnected(result);
    logInfo('Connectivity changed: isConnected=$isConnected', tag: 'Connectivity');
    yield isConnected;
  }
});

bool _isConnected(List<ConnectivityResult> results) {
  return !results.contains(ConnectivityResult.none);
}

/// One-shot connectivity check. Use [connectivityProvider] to watch live changes.
/// Defaults to true on error to avoid blocking the user when the API is unreachable.
final isOnlineProvider = FutureProvider<bool>((ref) async {
  try {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    return _isConnected(result);
  } catch (e) {
    logWarning('Connectivity check failed: $e', tag: 'Connectivity');
    return true; // Assume online on error to avoid blocking user
  }
});
