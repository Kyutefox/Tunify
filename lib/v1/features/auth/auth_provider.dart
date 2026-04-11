import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tunify/v1/core/utils/app_log.dart';

/// Local-only app: no cloud account. This provider always yields null.
final currentUserProvider = Provider<Object?>((ref) => null);

/// Manages guest-mode state, persisted to [SharedPreferences] across launches.
///
/// Defaults to true so the app is fully usable without any sign-in flow.
class GuestModeNotifier extends Notifier<bool> {
  static const String _guestModeKey = 'guest_mode_enabled';

  @override
  bool build() {
    _restore();
    return true;
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_guestModeKey) ?? true;
    } catch (e) {
      logWarning('Auth: GuestMode _restore failed: $e', tag: 'Auth');
    }
  }

  Future<void> _persist(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_guestModeKey, value);
    } catch (e) {
      logWarning('Auth: GuestMode _persist failed: $e', tag: 'Auth');
    }
  }

  Future<void> enterGuestMode() async {
    state = true;
    await _persist(true);
  }

  Future<void> exitGuestMode() async {
    state = false;
    await _persist(false);
  }
}

final guestModeProvider =
    NotifierProvider<GuestModeNotifier, bool>(GuestModeNotifier.new);
