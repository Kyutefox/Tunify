/// Row ↔ map conversions and helpers shared by Supabase get/create controllers.
class SupabaseMappers {
  SupabaseMappers._();

  /// Converts a Supabase track row to the app song map format.
  static Map<String, dynamic> trackRowToSongMap(Map<String, dynamic> r) {
    final durSec = r['duration_seconds'] as int? ?? 0;
    return {
      'id': r['song_id'] ?? r['id'] ?? '',
      'title': r['title'] ?? '',
      'artist': r['artist'] ?? '',
      'thumbnailUrl': r['thumbnail_url'] ?? '',
      'durationMs': durSec * 1000,
      'albumName': r['album_name'],
      'artistBrowseId': r['artist_browse_id'],
      'albumBrowseId': r['album_browse_id'],
      'isExplicit': r['is_explicit'] as bool? ?? false,
    };
  }

  /// Converts an app song map to a Supabase track row for [userId], [playlistId], [position].
  static Map<String, dynamic> songMapToTrackRow(
      String userId, String? playlistId, int position, Map<String, dynamic> s) {
    final durMs = s['durationMs'] as int? ?? 0;
    return {
      if (playlistId != null) 'playlist_id': playlistId,
      'user_id': userId,
      'song_id': s['id'] ?? '',
      'position': position,
      'title': s['title'] ?? '',
      'artist': s['artist'] ?? '',
      'thumbnail_url': s['thumbnailUrl'] ?? '',
      'duration_seconds': durMs ~/ 1000,
      'album_name': s['albumName'],
      'artist_browse_id': s['artistBrowseId'],
      'album_browse_id': s['albumBrowseId'],
      'is_explicit': s['isExplicit'] as bool? ?? false,
      'added_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Returns true if [a] and [b] have the same length and elements in order.
  static bool listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
