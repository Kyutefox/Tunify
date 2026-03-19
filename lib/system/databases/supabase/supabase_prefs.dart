import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/supabase_config.dart';

const String _keySupabaseUrl = 'supabase_custom_url';
const String _keySupabaseAnonKey = 'supabase_custom_anon_key';

/// Returns the Supabase URL to use: custom if stored, otherwise default.
Future<String> getEffectiveSupabaseUrl() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_keySupabaseUrl) ?? SupabaseConfig.url;
}

/// Returns the Supabase anon key to use: custom if stored, otherwise default.
Future<String> getEffectiveSupabaseAnonKey() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_keySupabaseAnonKey) ?? SupabaseConfig.anonKey;
}

/// True if the user has saved a custom Supabase URL and anon key.
Future<bool> hasCustomSupabaseConfig() async {
  final prefs = await SharedPreferences.getInstance();
  final url = prefs.getString(_keySupabaseUrl);
  final key = prefs.getString(_keySupabaseAnonKey);
  return (url != null && url.trim().isNotEmpty) &&
      (key != null && key.trim().isNotEmpty);
}

/// Tests that the given [url] and [key] can reach the Supabase project (auth health).
Future<bool> testSupabaseConnection(String url, String key) async {
  try {
    final base = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    final uri = Uri.parse('$base/auth/v1/health');
    final r = await http.get(uri, headers: {'apikey': key});
    return r.statusCode == 200;
  } catch (_) {
    return false;
  }
}

/// Removes custom Supabase URL and anon key from preferences.
Future<void> clearSupabaseConfig() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_keySupabaseUrl);
  await prefs.remove(_keySupabaseAnonKey);
}

/// Saves custom Supabase [url] and [key] to preferences.
Future<void> saveSupabaseConfig(String url, String key) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_keySupabaseUrl, url.trim());
  await prefs.setString(_keySupabaseAnonKey, key.trim());
}
