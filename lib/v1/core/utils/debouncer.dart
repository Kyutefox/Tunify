import 'dart:async';

import 'package:flutter/foundation.dart';

/// Delays execution of an action until after a specified duration has elapsed
/// without the action being triggered again.
///
/// Useful for search input debouncing, scroll event throttling, and other
/// scenarios where rapid successive events should be coalesced.
class Debouncer {
  /// Creates a debouncer with the specified [delay].
  /// Defaults to 300 milliseconds.
  Debouncer([this.delay = const Duration(milliseconds: 300)]);

  final Duration delay;
  VoidCallback? _action;
  bool _disposed = false;
  Timer? _timer;

  /// Schedules [action] to run after [delay], cancelling any pending action.
  void run(VoidCallback action) {
    _action = action;
    _timer?.cancel();
    _timer = Timer(delay, () {
      if (!_disposed) _action?.call();
    });
  }

  /// Cancels any pending action without running it.
  void cancel() {
    _timer?.cancel();
    _action = null;
  }

  /// Permanently disables this debouncer and releases resources.
  void dispose() {
    _timer?.cancel();
    _disposed = true;
    _action = null;
  }
}
