import 'dart:async';

import 'package:flutter/foundation.dart';

class Debouncer {
  Debouncer([this.delay = const Duration(milliseconds: 300)]);

  final Duration delay;
  VoidCallback? _action;
  bool _disposed = false;
  Timer? _timer;

  void run(VoidCallback action) {
    _action = action;
    _timer?.cancel();
    _timer = Timer(delay, () {
      if (!_disposed) _action?.call();
    });
  }

  void cancel() {
    _timer?.cancel();
    _action = null;
  }

  void dispose() {
    _timer?.cancel();
    _disposed = true;
    _action = null;
  }
}
