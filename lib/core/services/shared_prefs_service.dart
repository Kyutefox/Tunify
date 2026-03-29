import 'package:shared_preferences/shared_preferences.dart';
import 'package:tunify_logger/tunify_logger.dart';

/// Centralized SharedPreferences management to prevent repeated getInstance() calls.
/// The instance is cached and reused throughout the app lifetime.
class SharedPrefsService {
  static SharedPrefsService? _instance;
  static SharedPrefsService get instance => _instance ??= SharedPrefsService._();

  SharedPrefsService._();

  SharedPreferences? _prefs;

  /// Initialize SharedPreferences at app startup
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      logWarning('SharedPrefsService: Failed to initialize - $e', tag: 'SharedPrefs');
    }
  }

  SharedPreferences? get prefs => _prefs;

  /// Get a string value
  String? getString(String key) => _prefs?.getString(key);

  /// Set a string value
  Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  /// Get an int value
  int? getInt(String key) => _prefs?.getInt(key);

  /// Set an int value
  Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }

  /// Get a bool value
  bool? getBool(String key) => _prefs?.getBool(key);

  /// Set a bool value
  Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }

  /// Get a double value
  double? getDouble(String key) => _prefs?.getDouble(key);

  /// Set a double value
  Future<bool> setDouble(String key, double value) async {
    return await _prefs?.setDouble(key, value) ?? false;
  }

  /// Remove a value
  Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  /// Clear all values
  Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }
}
