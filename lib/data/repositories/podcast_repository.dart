import 'package:tunify/data/models/audiobook.dart';
import 'package:tunify/data/models/playback_position.dart';
import 'package:tunify/data/models/podcast.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/data/models/track.dart';
import 'package:tunify_database/tunify_database.dart';

/// Repository for podcast subscriptions, saved audiobooks, and playback positions.
/// All persistence goes through [DatabaseBridge] (SQLite).
class PodcastRepository {
  PodcastRepository(this._bridge);
  final DatabaseBridge _bridge;

  // ── Podcast Subscriptions ─────────────────────────────────────────────────

  Future<List<Podcast>> loadSubscriptions() async {
    final rows = await _bridge.loadPodcastSubscriptions();
    return rows.map(_rowToPodcast).toList();
  }

  Future<void> subscribe(Podcast podcast) async {
    await _bridge.upsertPodcastSubscription({
      'id': podcast.id,
      'title': podcast.title,
      'author': podcast.author ?? '',
      'thumbnail_url': podcast.thumbnailUrl,
      'browse_id': podcast.browseId,
      'subscribed_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> unsubscribe(String id) async {
    await _bridge.deletePodcastSubscription(id);
  }

  Future<void> updatePodcast(Podcast podcast) async {
    await _bridge.upsertPodcastSubscription({
      'id': podcast.id,
      'title': podcast.title,
      'author': podcast.author ?? '',
      'thumbnail_url': podcast.thumbnailUrl,
      'browse_id': podcast.browseId,
      'is_pinned': podcast.isPinned ? 1 : 0,
      'subscribed_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ── Saved Audiobooks ──────────────────────────────────────────────────────

  Future<List<Audiobook>> loadSavedAudiobooks() async {
    final rows = await _bridge.loadSavedAudiobooks();
    return rows.map(_rowToAudiobook).toList();
  }

  Future<void> saveAudiobook(Audiobook audiobook) async {
    await _bridge.upsertSavedAudiobook({
      'id': audiobook.id,
      'title': audiobook.title,
      'author': audiobook.author ?? '',
      'thumbnail_url': audiobook.thumbnailUrl,
      'browse_id': audiobook.browseId,
      'saved_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> removeSavedAudiobook(String id) async {
    await _bridge.deleteSavedAudiobook(id);
  }

  Future<void> updateAudiobook(Audiobook audiobook) async {
    await _bridge.upsertSavedAudiobook({
      'id': audiobook.id,
      'title': audiobook.title,
      'author': audiobook.author ?? '',
      'thumbnail_url': audiobook.thumbnailUrl,
      'browse_id': audiobook.browseId,
      'is_pinned': audiobook.isPinned ? 1 : 0,
      'saved_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ── Episodes For Later ────────────────────────────────────────────────────

  Future<List<Song>> loadEpisodesForLater() async {
    final rows = await _bridge.loadEpisodesForLater();
    return rows.map(_rowToSong).toList();
  }

  Future<void> saveEpisodeForLater(Song song) async {
    await _bridge.upsertEpisodeForLater({
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'thumbnail_url': song.thumbnailUrl,
      'duration_seconds': song.duration.inSeconds,
      'saved_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> removeEpisodeForLater(String id) async {
    await _bridge.deleteEpisodeForLater(id);
  }

  Future<void> updateEpisodesForLaterOrder(List<String> orderedIds) async {
    await _bridge.updateEpisodesForLaterOrder(orderedIds);
  }

  // ── Playback Positions ────────────────────────────────────────────────────

  Future<PlaybackPosition?> getPosition(
      String contentId, PlaybackContentType type) async {
    final row =
        await _bridge.getPlaybackPosition(contentId, type.name);
    if (row == null) return null;
    return _rowToPosition(row);
  }

  Future<Map<String, PlaybackPosition>> loadAllPositions() async {
    final rows = await _bridge.loadAllPlaybackPositions();
    return {
      for (final row in rows)
        '${row['content_id']}_${row['content_type']}': _rowToPosition(row)
    };
  }

  Future<void> savePosition(PlaybackPosition pos) async {
    await _bridge.upsertPlaybackPosition({
      'content_id': pos.contentId,
      'content_type': pos.contentType.name,
      'position_seconds': pos.positionSeconds,
      'duration_seconds': pos.durationSeconds,
      'completed': (pos.completed ?? false) ? 1 : 0,
      'last_played_at': pos.lastPlayedAt.toUtc().toIso8601String(),
    });
  }

  Future<void> clearPosition(String contentId, PlaybackContentType type) async {
    await _bridge.deletePlaybackPosition(contentId, type.name);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static Podcast _rowToPodcast(Map<String, dynamic> row) => Podcast(
        id: row['id'] as String,
        title: row['title'] as String,
        author: row['author'] as String?,
        thumbnailUrl: row['thumbnail_url'] as String?,
        browseId: row['browse_id'] as String?,
        isPinned: (row['is_pinned'] as int?) == 1,
      );

  static Audiobook _rowToAudiobook(Map<String, dynamic> row) => Audiobook(
        id: row['id'] as String,
        title: row['title'] as String,
        author: row['author'] as String?,
        thumbnailUrl: row['thumbnail_url'] as String?,
        browseId: row['browse_id'] as String?,
        isPinned: (row['is_pinned'] as int?) == 1,
      );

  static PlaybackPosition _rowToPosition(Map<String, dynamic> row) =>
      PlaybackPosition(
        contentId: row['content_id'] as String,
        contentType: PlaybackContentType.values
            .firstWhere((e) => e.name == row['content_type']),
        positionSeconds: row['position_seconds'] as int,
        durationSeconds: row['duration_seconds'] as int,
        completed: (row['completed'] as int) == 1,
        lastPlayedAt: DateTime.parse(row['last_played_at'] as String),
      );

  static Song _rowToSong(Map<String, dynamic> row) => Song.fromTrack(Track(
        id: row['id'] as String,
        title: row['title'] as String,
        artist: row['artist'] as String? ?? '',
        thumbnailUrl: row['thumbnail_url'] as String? ?? '',
        duration: Duration(seconds: row['duration_seconds'] as int? ?? 0),
      ));
}
