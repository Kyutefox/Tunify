import '../constants/storage_keys.dart';
import '../sqlite/primary_database.dart';
import '../supabase/supabase_remote.dart';

/// Single entry point for app data: all reads and writes go to SQLite. Call
/// [pullFromSupabase] once on login to seed SQLite; background sync calls
/// [pushToSupabase] for logged-in users. Guests use SQLite only.
class DatabaseBridge {
  DatabaseBridge() : _db = PrimaryDatabase(), _remote = SupabaseRemote();

  final PrimaryDatabase _db;
  final SupabaseRemote _remote;

  /// Loads full library from SQLite.
  Future<Map<String, dynamic>> loadLibraryData() async => _db.loadLibraryData();

  /// Saves full library to SQLite.
  Future<void> saveLibraryData(Map<String, dynamic> data) async => _db.saveLibraryData(data);

  /// Loads recently played from SQLite.
  Future<List<Map<String, dynamic>>> loadRecentlyPlayed() async => _db.loadRecentlyPlayed();

  /// Saves recently played to SQLite.
  Future<void> saveRecentlyPlayed(List<Map<String, dynamic>> songs) async => _db.saveRecentlyPlayed(songs);

  /// Reads a setting by [key] from SQLite.
  Future<String?> getSetting(String key) async => _db.getSetting(key);

  /// Writes a setting [key]=[value] to SQLite.
  Future<void> setSetting(String key, String value) async => _db.setSetting(key, value);

  /// Loads playback settings from SQLite (volume, explicit, shuffle, crossfade, gapless).
  Future<Map<String, dynamic>> loadPlaybackSettings() async {
    final keys = [
      PlaybackSettingKeys.volumeNormalization,
      PlaybackSettingKeys.showExplicitContent,
      PlaybackSettingKeys.smartRecommendationShuffle,
      PlaybackSettingKeys.gaplessPlayback,
      PlaybackSettingKeys.crossfadeDurationSeconds,
    ];
    final out = <String, dynamic>{};
    for (final k in keys) {
      final v = await _db.getSetting(k);
      if (v != null) {
        if (k == PlaybackSettingKeys.crossfadeDurationSeconds) {
          out[k] = int.tryParse(v) ?? 0;
        } else {
          out[k] = v == 'true';
        }
      }
    }
    return out;
  }

  /// Saves a single playback setting [key]=[value] to SQLite.
  Future<void> savePlaybackSetting(String key, dynamic value) async {
    await _db.setSetting(key, value.toString());
  }

  /// Loads recent searches from SQLite.
  Future<List<String>> loadRecentSearches() async => _db.loadRecentSearches();

  /// Saves recent searches to SQLite.
  Future<void> saveRecentSearches(List<String> queries) async => _db.saveRecentSearches(queries);

  /// Loads downloaded song IDs from SQLite.
  Future<List<String>> loadDownloadedSongIds() async => _db.loadDownloadedSongIds();

  /// Saves downloaded song IDs to SQLite.
  Future<void> saveDownloadedSongIds(List<String> ids) async => _db.saveDownloadedSongIds(ids);

  /// Loads YT personalization from SQLite.
  Future<Map<String, dynamic>> loadYtPersonalization() async => _db.loadYtPersonalization();

  /// Saves YT personalization to SQLite.
  Future<void> saveYtPersonalization(Map<String, dynamic> data) async => _db.saveYtPersonalization(data);

  /// Pulls all data from Supabase into SQLite. Call once after login (or clear data + re-login).
  /// After this, SQLite is the source of truth until next login.
  Future<void> pullFromSupabase(String userId) async {
    try {
      final library = await _remote.fetchLibraryData(userId);
      if (library != null) await _db.saveLibraryData(library);

      final recent = await _remote.fetchRecentlyPlayed(userId);
      if (recent != null && recent.isNotEmpty) await _db.saveRecentlyPlayed(recent);

      final playback = await _remote.fetchPlaybackSettings(userId);
      if (playback != null) {
        for (final e in playback.entries) {
          await _db.setSetting(e.key, e.value.toString());
        }
      }

      final searches = await _remote.fetchRecentSearches(userId);
      if (searches != null && searches.isNotEmpty) await _db.saveRecentSearches(searches);

      final downloaded = await _remote.fetchDownloadedSongIds(userId);
      if (downloaded != null && downloaded.isNotEmpty) await _db.saveDownloadedSongIds(downloaded);

      final yt = await _remote.fetchYtPersonalization(userId);
      if (yt != null && (yt['visitor_data']?.toString().isNotEmpty == true || yt['api_key'] != null)) {
        await _db.saveYtPersonalization(yt);
      }
    } catch (_) {}
  }

  /// Pushes current SQLite state to Supabase. Used by background sync for logged-in users.
  Future<void> pushToSupabase(String userId) async {
    try {
      final library = await _db.loadLibraryData();
      await _remote.pushLibraryData(userId, library);

      final recent = await _db.loadRecentlyPlayed();
      await _remote.pushRecentlyPlayed(userId, recent);

      final playback = await loadPlaybackSettings();
      await _remote.pushPlaybackSettings(userId, playback);

      final searches = await _db.loadRecentSearches();
      await _remote.pushRecentSearches(userId, searches);

      final downloaded = await _db.loadDownloadedSongIds();
      await _remote.pushDownloadedSongIds(userId, downloaded);

      final yt = await _db.loadYtPersonalization();
      if ((yt['visitor_data']?.toString().isNotEmpty ?? false) || yt['api_key'] != null) {
        await _remote.pushYtPersonalization(userId, yt);
      }
    } catch (_) {}
  }

  /// Closes the primary database.
  Future<void> close() async => _db.close();
}
