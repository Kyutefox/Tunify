import 'dart:async';

import '../bridge/database_bridge.dart';

/// Event-driven sync to Supabase: call [requestSync] after mutations; pushes are
/// debounced so rapid changes trigger one push. A 1-minute fallback timer runs
/// if a sync was missed. Call [start] after login and [stop] on logout.
class SyncManager {
  SyncManager({required DatabaseBridge bridge}) : _bridge = bridge;

  final DatabaseBridge _bridge;
  Timer? _debounceTimer;
  Timer? _fallbackTimer;
  String? _userId;

  /// Delay after last [requestSync] before a push runs.
  static const Duration debounceDuration = Duration(seconds: 2);
  /// Interval for fallback push when no requestSync occurred.
  static const Duration fallbackInterval = Duration(minutes: 1);

  /// Starts sync for [userId]: enables fallback timer and [requestSync].
  void start(String userId) {
    if (_userId == userId) return;
    stop();
    _userId = userId;
    _fallbackTimer = Timer.periodic(fallbackInterval, (_) => _sync());
  }

  /// Stops sync and cancels timers.
  void stop() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    _userId = null;
  }

  /// Schedules a single push after [debounceDuration]. Call after any mutation.
  void requestSync() {
    if (_userId == null || _userId!.isEmpty) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      _debounceTimer = null;
      _sync();
    });
  }

  Future<void> _sync() async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return;
    try {
      await _bridge.pushToSupabase(uid);
    } catch (_) {}
  }
}
