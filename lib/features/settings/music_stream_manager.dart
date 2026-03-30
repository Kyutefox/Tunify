import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tunify/core/utils/platform_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:scrapper/scrapper.dart' as scrapper;

import 'package:tunify_database/tunify_database.dart' hide StorageKeys;
import 'package:tunify_logger/tunify_logger.dart';

import 'package:tunify/core/constants/storage_keys.dart';

import 'package:tunify/data/models/audio_quality.dart';
import 'package:tunify/data/models/collection_result.dart';
import 'package:tunify/data/models/lyrics_result.dart';
import 'package:tunify/data/models/related_feed.dart';
import 'package:tunify/data/models/search_browse_ids_result.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/data/models/track.dart';

enum StreamQuality {
  low,
  medium,
  high,
  auto,
}

const String kYtVisitorDataKey = 'yt_visitor_data';

/// Target loudness in LUFS for volume normalization (e.g. -14.0).
const double kLufsTargetDb = -14.0;

typedef OnVisitorDataReceived = void Function(String? visitorData);

/// Converts scrapper Track to app Track.
Track _scrapperTrackToApp(scrapper.Track t) {
  return Track(
    id: t.id,
    title: t.title,
    artist: t.artist,
    thumbnailUrl: t.thumbnailUrl,
    duration: t.duration,
    artistBrowseId: t.artistBrowseId,
    albumBrowseId: t.albumBrowseId,
    albumName: t.albumName,
    isExplicit: t.isExplicit,
  );
}

/// Converts scrapper RelatedHomeFeed to app RelatedHomeFeed.
RelatedHomeFeed _scrapperFeedToApp(scrapper.RelatedHomeFeed f) {
  return RelatedHomeFeed(
    trackShelves: f.trackShelves
        .map((s) => RelatedTrackShelf(
              title: s.title,
              subtitle: s.subtitle,
              tracks: s.tracks.map(_scrapperTrackToApp).toList(),
            ))
        .toList(),
    playlistShelves: f.playlistShelves
        .map((s) => RelatedPlaylistShelf(
              title: s.title,
              subtitle: s.subtitle,
              playlists: s.playlists
                  .map((p) => RelatedPlaylist(
                        id: p.id,
                        title: p.title,
                        thumbnailUrl: p.thumbnailUrl,
                        curatorName: p.curatorName,
                        trackCount: p.trackCount,
                      ))
                  .toList(),
            ))
        .toList(),
    artistShelves: f.artistShelves
        .map((s) => RelatedArtistShelf(
              title: s.title,
              subtitle: s.subtitle,
              artists: s.artists
                  .map((a) => RelatedArtist(
                        id: a.id,
                        name: a.name,
                        thumbnailUrl: a.thumbnailUrl,
                        subtitle: a.subtitle,
                      ))
                  .toList(),
            ))
        .toList(),
    shelves: f.shelves
        .map((s) => RelatedHomeShelf(
              title: s.title,
              subtitle: s.subtitle,
              browseId: s.browseId,
              params: s.params,
            ))
        .toList(),
    moodItems: f.moodItems
        .map((m) => RelatedMoodItem(
              title: m.title,
              browseId: m.browseId,
              params: m.params,
              sectionTitle: m.sectionTitle,
            ))
        .toList(),
  );
}

StreamQuality _audioToStreamQuality(AudioQuality q) {
  switch (q) {
    case AudioQuality.low:
      return StreamQuality.low;
    case AudioQuality.medium:
      return StreamQuality.medium;
    case AudioQuality.high:
    case AudioQuality.auto:
      return StreamQuality.high;
  }
}

/// Parameters for stream fetch isolate
class _StreamFetchParams {
  final String videoId;
  final bool preferAac;
  
  _StreamFetchParams(this.videoId, this.preferAac);
}

/// Result from stream fetch isolate (serializable)
class _StreamFetchResult {
  final String url;
  final int bitrate;
  final String mimeType;
  
  _StreamFetchResult(this.url, this.bitrate, this.mimeType);
}

/// YouTube stream URLs expire after ~6 hours. Cache entries are considered
/// stale at 5h30m to leave a safe buffer before the URL actually expires.
const Duration _kStreamUrlTtl = Duration(hours: 5, minutes: 30);
const int _kMaxCacheEntries = 50;
const int _kMaxPrefetchItems = 5;
const int _kMaxPrefetchConcurrency = 2;

/// Wraps a [StreamResult] with its expiry timestamp for TTL-based eviction.
class _CachedStream {
  final StreamResult result;
  final DateTime expiresAt;

  _CachedStream(this.result) : expiresAt = DateTime.now().add(_kStreamUrlTtl);
  _CachedStream.withExpiry(this.result, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Central API facade over the `scrapper` package.
///
/// Responsibilities:
/// - Resolving YouTube stream URLs with LRU in-memory caching ([_streamCache]).
/// - Fetching and persisting the YT visitor data token for personalized results.
/// - Providing search, browse, lyrics, and watchtime-reporting APIs.
///
/// The internal [scrapper.YoutubeMusic] instance is recreated whenever
/// [setVisitorData] or [initFromSwJsData] changes the session identity.
/// A generation counter ([_ytMusicGen]) silences callbacks from stale instances.
class MusicStreamManager {
  String? _visitorData;

  /// InnerTube API key — fetched live from music.youtube.com HTML and cached
  /// in SharedPreferences. Falls back to YtConstants hardcoded value only when
  /// both the cache and live fetch have not yet provided a value.
  String? _apiKey;

  /// InnerTube client version — same lifecycle as [_apiKey].
  String? _clientVersion;

  /// Session cookies (VISITOR_INFO1_LIVE + YSC) forwarded with all InnerTube
  /// and tracking calls so YouTube can link watchtime to the browse session.
  String? _sessionCookies;

  /// Geographic locale fetched live from YouTube (e.g. 'NP'). Null until the
  /// first successful VisitorDataFetcher call — never hardcoded.
  String? _gl;

  /// Language locale fetched live from YouTube (e.g. 'en'). Null until the
  /// first successful VisitorDataFetcher call — never hardcoded.
  String? _hl;
  final scrapper.YTMusicAuth? _auth;
  late scrapper.YoutubeMusic _ytMusic;

  /// Monotonic generation counter incremented each time [_ytMusic] is replaced.
  /// Callbacks capture the generation at creation time and are discarded when they no longer match,
  /// preventing stale visitor-data responses from overwriting a more recent token.
  int _ytMusicGen = 0;
  late scrapper.YoutubeDirect _ytDirect;
  final ValueNotifier<StreamQuality> _qualityNotifier =
      ValueNotifier(StreamQuality.auto);

  /// LRU stream URL cache. Dart's default [Map] preserves insertion order (LinkedHashMap),
  /// so the first key is always the least-recently-used entry.
  final Map<String, _CachedStream> _streamCache = {};
  int _hits = 0;
  int _misses = 0;
  final DatabaseBridge? _db;
  Box<dynamic>? _hiveBox;

  MusicStreamManager({
    String? visitorData,
    String? apiKey,
    String? clientVersion,
    OnVisitorDataReceived? onVisitorDataReceived,
    scrapper.YTMusicAuth? auth,
    DatabaseBridge? db,
  })  : _visitorData = visitorData,
        _db = db,
        _apiKey = apiKey,
        _clientVersion = clientVersion,
        _auth = auth {
    final gen = ++_ytMusicGen;
    _ytMusic = scrapper.YoutubeMusic(
      visitorData: _visitorData,
      apiKey: _apiKey,
      clientVersion: _clientVersion,
      sessionCookies: _sessionCookies,
      auth: auth,
      onVisitorDataReceived: (vd) {
        if (gen == _ytMusicGen) _onVisitorDataChanged(vd);
      },
    );
    _ytDirect = scrapper.YoutubeDirect();
    // Skip persistence when no initial token was provided; writing null would erase
    // any token already in SharedPreferences before _restoreVisitorData reads it.
    if (_visitorData != null && _visitorData!.isNotEmpty) {
      (onVisitorDataReceived ?? _defaultOnVisitorDataReceived)(_visitorData);
    }
  }

  /// Fetches stream URL in background using compute to prevent UI blocking
  Future<_StreamFetchResult?> _fetchStreamInIsolate(String videoId, bool preferAac) async {
    try {
      // Use compute to run the network-heavy operation off the main thread
      return await compute(_fetchStreamIsolateFunction, _StreamFetchParams(videoId, preferAac));
    } catch (e) {
      log('PlayFlow: _fetchStreamInIsolate failed: $e', tag: 'PlayFlow');
      return null;
    }
  }

  /// Top-level function for compute isolate - returns serializable data
  static Future<_StreamFetchResult?> _fetchStreamIsolateFunction(_StreamFetchParams params) async {
    final ytDirect = scrapper.YoutubeDirect();
    final stream = await ytDirect.streams.fetchBestAudioStream(
      params.videoId,
      preferAac: params.preferAac,
    );
    if (stream == null) return null;
    return _StreamFetchResult(
      stream.url,
      stream.bitrate!,
      stream.mimeType,
    );
  }

  /// Visitor-data tokens longer than this are service-worker init blobs, not
  /// personalization tokens, and must be discarded to avoid poisoning the cache.
  static const int _kMaxVisitorDataLength = 200;

  /// Called whenever any API response (player, browse, next) returns an updated
  /// visitorData. Saves it so the next session restore uses the latest token.
  void _onVisitorDataChanged(String? vd) {
    if (vd == null || vd.isEmpty || vd == _visitorData) return;
    // Reject long service-worker blobs — only persist short personalisation tokens.
    if (vd.length > _kMaxVisitorDataLength) return;
    _visitorData = vd;
    SharedPreferences.getInstance()
        .then((p) => p.setString(kYtVisitorDataKey, vd));
  }

  static void _defaultOnVisitorDataReceived(String? v) {
    SharedPreferences.getInstance()
        .then((p) => p.setString(kYtVisitorDataKey, v ?? ''));
  }

  void setVisitorData(String? value) {
    final normalized = value?.isNotEmpty == true ? value : null;
    // Skip recreation when the token is unchanged to preserve session state
    // accumulated in the current client instance (e.g. from a recent player call).
    if (normalized == _visitorData) return;
    _visitorData = normalized;
    final gen = ++_ytMusicGen;
    _ytMusic = scrapper.YoutubeMusic(
      visitorData: _visitorData,
      apiKey: _apiKey,
      clientVersion: _clientVersion,
      sessionCookies: _sessionCookies,
      gl: _gl,
      hl: _hl,
      auth: _auth,
      onVisitorDataReceived: (vd) {
        if (gen == _ytMusicGen) _onVisitorDataChanged(vd);
      },
    );
  }

  /// Fetches live visitor data, API key, client version, locale, and session
  /// cookies from YouTube Music's main page and rebuilds [YoutubeMusic].
  /// Persists apiKey and clientVersion to SharedPreferences so future launches
  /// can use cached values without waiting for the live fetch.
  /// Call this when visitorData is missing or stale.
  Future<void> initFromSwJsData() async {
    final swData = await scrapper.VisitorDataFetcher.fetch();
    if (swData.visitorData != null) _visitorData = swData.visitorData;
    if (swData.sessionCookies != null) _sessionCookies = swData.sessionCookies;
    if (swData.gl != null) _gl = swData.gl;
    if (swData.hl != null) _hl = swData.hl;
    if (swData.apiKey?.isNotEmpty == true) {
      _apiKey = swData.apiKey;
      SharedPreferences.getInstance()
          .then((p) => p.setString(StorageKeys.prefsYtApiKey, _apiKey!));
    }
    if (swData.clientVersion?.isNotEmpty == true) {
      _clientVersion = swData.clientVersion;
      SharedPreferences.getInstance().then((p) =>
          p.setString(StorageKeys.prefsYtClientVersion, _clientVersion!));
    }
    final gen = ++_ytMusicGen;
    _ytMusic = scrapper.YoutubeMusic(
      visitorData: _visitorData,
      apiKey: swData.apiKey,
      clientVersion: swData.clientVersion,
      sessionCookies: _sessionCookies,
      gl: _gl,
      hl: _hl,
      auth: _auth,
      onVisitorDataReceived: (vd) {
        if (gen == _ytMusicGen) _onVisitorDataChanged(vd);
      },
    );
  }

  String? get visitorData => _visitorData;

  /// Opens the Hive stream-URL box, restores non-expired entries into the
  /// in-memory LRU cache, and clears expired SQLite entries. Call once after construction.
  Future<void> init() async {
    await Future.wait([
      _restoreStreamUrlsFromHive(),
      _db?.clearExpiredStreamUrlCache() ?? Future.value(),
    ]);
  }

  Future<void> _restoreStreamUrlsFromHive() async {
    try {
      _hiveBox = await Hive.openBox<dynamic>('stream_urls');
      final box = _hiveBox!;
      final now = DateTime.now();
      final toDelete = <dynamic>[];
      for (final key in box.keys) {
        final entry = box.get(key);
        if (entry is! Map) continue;
        final expiresAtMs = entry['expiresAt'] as int?;
        if (expiresAtMs == null) {
          toDelete.add(key);
          continue;
        }
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtMs);
        if (now.isAfter(expiresAt)) {
          toDelete.add(key);
          continue;
        }
        final url = entry['url'] as String?;
        final bitrate = entry['bitrate'] as int? ?? 128;
        if (url == null || url.isEmpty) {
          toDelete.add(key);
          continue;
        }
        final audioQuality = bitrate >= 160
            ? AudioQuality.high
            : bitrate >= 80
                ? AudioQuality.medium
                : AudioQuality.low;
        final stream = AudioStream(
          url: url,
          bitrate: bitrate,
          quality: audioQuality,
          codec: 'opus',
          headers: Map<String, String>.from(scrapper.streamHeaders),
        );
        final result = StreamResult(
          trackId: key as String,
          highQuality: audioQuality == AudioQuality.high ? stream : null,
          mediumQuality: audioQuality == AudioQuality.medium ? stream : null,
          lowQuality: audioQuality == AudioQuality.low ? stream : null,
        );
        if (_streamCache.length < _kMaxCacheEntries) {
          _streamCache[key] = _CachedStream.withExpiry(result, expiresAt);
        }
      }
      if (toDelete.isNotEmpty) await box.deleteAll(toDelete);
    } catch (e) {
      logWarning('StreamManager: _restoreStreamUrlsFromHive failed: $e',
          tag: 'PlayFlow');
    }
  }

  /// True once a live apiKey + clientVersion have been loaded from cache or
  /// from a successful VisitorDataFetcher fetch. When false, the first API
  /// call is using the hardcoded fallback constants — a fresh fetch is needed.
  bool get hasApiConfig => _apiKey != null || _clientVersion != null;

  /// Applies apiKey and clientVersion loaded from SharedPreferences cache.
  /// Call this before [setVisitorData] so the rebuilt [YoutubeMusic] instance
  /// already has the cached config baked in.
  void applyCachedApiConfig(String? apiKey, String? clientVersion) {
    if (apiKey?.isNotEmpty == true) _apiKey = apiKey;
    if (clientVersion?.isNotEmpty == true) _clientVersion = clientVersion;
    // No rebuild here — the fields will be picked up by the next
    // setVisitorData() call or initFromSwJsData().
  }

  ValueNotifier<StreamQuality> get qualityNotifier => _qualityNotifier;

  StreamQuality get recommendedQuality => StreamQuality.high;

  /// Returns only stream URL and quality (bitrate, quality label, headers).
  /// All metadata (title, thumbnail, artist, duration, etc.) must be fetched
  /// from YouTube Music /player API via [getSongFromPlayer].
  Future<Map<String, dynamic>> getStreamUrl(String videoId) async {
    final apiSw = Stopwatch()..start();
    try {
      final cached = _streamCache[videoId];
      if (cached != null && !cached.isExpired) {
        _hits++;
        final stream = cached.result.best;
        if (stream != null) {
          // Re-insert to mark as most-recently-used for LRU ordering.
          _streamCache.remove(videoId);
          _streamCache[videoId] = cached;
          log('PlayFlow: getStreamUrl CACHE HIT videoId=$videoId (${apiSw.elapsedMilliseconds}ms)',
              tag: 'PlayFlow');
          return {
            'stream_url': stream.url,
            'bitrate': stream.bitrate,
            'quality': stream.quality.label,
            'headers': stream.headers,
          };
        }
      } else if (cached != null) {
        // Expired entry — remove proactively before fetching fresh.
        _streamCache.remove(videoId);
      }
      _misses++;
      log('PlayFlow: getStreamUrl CACHE MISS videoId=$videoId calling youtube_direct.fetchBestAudioStream',
          tag: 'PlayFlow');
      // L2: SQLite cache check
      final sqliteCached = await _db?.getStreamUrlCache(videoId);
      if (sqliteCached != null) {
        log('PlayFlow: getStreamUrl SQLITE HIT videoId=$videoId',
            tag: 'PlayFlow');
        final url = sqliteCached['url'] as String;
        final headers = sqliteCached['headers'] as Map<String, String>? ?? {};
        final bitrate = sqliteCached['bitrate'] as int? ?? 0;
        final quality = sqliteCached['quality'] as String? ?? '';
        // Populate L1 from L2
        final audioQuality = bitrate >= 160
            ? AudioQuality.high
            : bitrate >= 80
                ? AudioQuality.medium
                : AudioQuality.low;
        final stream = AudioStream(
          url: url,
          bitrate: bitrate,
          quality: audioQuality,
          codec: 'opus',
          headers: Map<String, String>.from(scrapper.streamHeaders),
        );
        final result = StreamResult(
          trackId: videoId,
          highQuality: audioQuality == AudioQuality.high ? stream : null,
          mediumQuality: audioQuality == AudioQuality.medium ? stream : null,
          lowQuality: audioQuality == AudioQuality.low ? stream : null,
        );
        if (_streamCache.length >= _kMaxCacheEntries) {
          _streamCache.remove(_streamCache.keys.first);
        }
        _streamCache[videoId] = _CachedStream(result);
        return {
          'stream_url': url,
          'bitrate': bitrate,
          'quality': quality,
          'headers': headers,
        };
      }
      final fetchT0 = apiSw.elapsedMilliseconds;
      
      // Run network-heavy operation in isolate to prevent UI blocking
      final ytStream = await _fetchStreamInIsolate(videoId, isApplePlatform);
      
      log('PlayFlow: getStreamUrl fetchBestAudioStream (youtube_explode_dart getManifest) done in ${apiSw.elapsedMilliseconds - fetchT0}ms',
          tag: 'PlayFlow');
      if (ytStream == null) {
        throw Exception('No audio stream available for $videoId');
      }
      final bitrate = ytStream.bitrate;
      final quality = bitrate >= 160
          ? AudioQuality.high
          : bitrate >= 80
              ? AudioQuality.medium
              : AudioQuality.low;
      _qualityNotifier.value = _audioToStreamQuality(quality);
      final stream = AudioStream(
        url: ytStream.url,
        bitrate: bitrate,
        quality: quality,
        codec: 'opus',
        headers: Map<String, String>.from(scrapper.streamHeaders),
      );
      final result = StreamResult(
        trackId: videoId,
        highQuality: quality == AudioQuality.high ? stream : null,
        mediumQuality: quality == AudioQuality.medium ? stream : null,
        lowQuality: quality == AudioQuality.low ? stream : null,
      );
      // Evict the least-recently-used entry when at the cap.
      if (_streamCache.length >= _kMaxCacheEntries) {
        _streamCache.remove(_streamCache.keys.first);
      }
      _streamCache[videoId] = _CachedStream(result);
      // Persist to L2: Hive (fast, survives restarts) + SQLite (shared with other layers).
      final expiresAt = DateTime.now().toUtc().add(_kStreamUrlTtl);
      _hiveBox?.put(videoId, {
        'url': ytStream.url,
        'bitrate': bitrate,
        'quality': quality.label,
        'expiresAt': expiresAt.millisecondsSinceEpoch,
      }).ignore();
      final db = _db;
      if (db != null) {
        db
            .trimStreamUrlCacheIfNeeded()
            .then((_) => db.upsertStreamUrlCache(
                  videoId,
                  ytStream.url,
                  Map<String, String>.from(scrapper.streamHeaders),
                  bitrate,
                  quality.label,
                  expiresAt,
                ))
            .ignore();
      }
      log('PlayFlow: getStreamUrl total (fetch+cache) ${apiSw.elapsedMilliseconds}ms',
          tag: 'PlayFlow');
      log('PlayFlow: getStreamUrl mimeType=${ytStream.mimeType} bitrate=${bitrate}kbps',
          tag: 'PlayFlow');
      return {
        'stream_url': ytStream.url,
        'bitrate': bitrate,
        'quality': quality.label,
        'headers': Map<String, String>.from(scrapper.streamHeaders),
      };
    } catch (e) {
      log('PlayFlow: getStreamUrl FAILED after ${apiSw.elapsedMilliseconds}ms',
          tag: 'PlayFlow');
      rethrow;
    }
  }

  StreamResult? getCached(String videoId) {
    final entry = _streamCache[videoId];
    if (entry == null || entry.isExpired) return null;
    return entry.result;
  }

  bool isCached(String videoId) {
    final entry = _streamCache[videoId];
    return entry != null && !entry.isExpired;
  }

  /// Full player response (track, metadata, playbackTracking) for e.g. playback tracking.
  /// Pass [cpn] so YouTube links this player call to subsequent watchtime reports.
  Future<Map<String, dynamic>> getPlayerResponseForTracking(String videoId,
      {String? cpn}) async {
    return _ytMusic.player.fetchPlayer(videoId, cpn: cpn);
  }

  /// Reports playback watchtime to YouTube; delegates to scrapper.
  Future<void> reportPlaybackWatchtime(
    String atrUrl,
    String cpn,
    int playbackSeconds, {
    int? lengthSeconds,
  }) =>
      _ytMusic.reportPlaybackWatchtime(atrUrl, cpn, playbackSeconds,
          lengthSeconds: lengthSeconds);

  /// Reports that playback started (videostatsPlaybackUrl); call once per track.
  Future<void> reportPlaybackStart(String videostatsPlaybackUrl, String cpn) =>
      _ytMusic.reportPlaybackStart(videostatsPlaybackUrl, cpn);

  /// Reports ptracking ping; call once at playback start.
  Future<void> reportPtracking(String ptrackingUrl, String cpn) =>
      _ytMusic.reportPtracking(ptrackingUrl, cpn);

  /// Fetches full track metadata from YouTube Music /player API (title,
  /// thumbnail, artist, duration, etc.). Use this for all display and metadata;
  /// use [getStreamUrl] only for stream URL and quality.
  Future<Song?> getSongFromPlayer(String videoId) async {
    try {
      final data = await _ytMusic.player.fetchPlayer(videoId);
      final track = data['track'];
      if (track == null) return null;
      final appTrack = _scrapperTrackToApp(track as scrapper.Track);
      return Song.fromTrack(appTrack);
    } catch (_) {
      return null;
    }
  }

  Future<double?> getLoudnessDbForVideo(String videoId) async {
    try {
      final data = await _ytMusic.player.fetchPlayer(videoId);
      final loudness = data['metadata']?['loudnessDb'] ??
          data['metadata']?['perceptualLoudnessDb'];
      if (loudness is num) return loudness.toDouble();
      return null;
    } catch (_) {
      return null;
    }
  }

  void putCached(String videoId, StreamResult result) {
    if (_streamCache.length >= _kMaxCacheEntries) {
      _streamCache.remove(_streamCache.keys.first);
    }
    _streamCache[videoId] = _CachedStream(result);
  }

  void clearCacheFor(String videoId) {
    _streamCache.remove(videoId);
    _db?.deleteStreamUrlCache(videoId).ignore();
    _hiveBox?.delete(videoId).ignore();
  }

  Future<void> prefetch(List<String> videoIds) async {
    // Cap items and run in batches of [_kMaxPrefetchConcurrency] to avoid
    // hammering YouTube's servers with unbounded concurrent requests.
    final ids = videoIds
        .where((id) => !isCached(id))
        .take(_kMaxPrefetchItems)
        .toList(growable: false);

    for (var i = 0; i < ids.length; i += _kMaxPrefetchConcurrency) {
      final batch = ids.skip(i).take(_kMaxPrefetchConcurrency);
      await Future.wait(
        batch.map((id) => getStreamUrl(id).then((_) {}).catchError((_) {})),
      );
    }
  }

  Future<List<Track>> searchTracks(String query, {int maxResults = 20}) async {
    try {
      final list =
          await _ytMusic.search.searchMusic(query, maxResults: maxResults);
      return list.map(_scrapperTrackToApp).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchPodcasts(String query,
      {int maxResults = 24}) async {
    try {
      return await _ytMusic.search
          .searchPodcasts(query, maxResults: maxResults);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchAudiobooks(String query,
      {int maxResults = 24}) async {
    try {
      return await _ytMusic.search
          .searchAudiobooks(query, maxResults: maxResults);
    } catch (_) {
      return [];
    }
  }

  Future<List<Track>> fetchPodcastShowContent(String browseId, {int maxTracks = 50}) async {
    try {
      final raw = await _ytMusic.browse.fetchPodcastShowContent(browseId, maxTracks: maxTracks);
      return raw.map(_scrapperTrackToApp).toList();
    } catch (_) {
      return [];
    }
  }

  Future<({List<Track> tracks, String? continuationToken})> fetchPlaylistTracksWithContinuation(
    String browseId, {
    String? continuationToken,
    int maxTracks = 200,
  }) async {
    try {
      final result = await _ytMusic.browse.fetchPlaylistOrAlbumWithContinuation(
        browseId,
        continuationToken: continuationToken,
        maxTracks: maxTracks,
      );
      return (
        tracks: result.tracks.map(_scrapperTrackToApp).toList(),
        continuationToken: result.continuationToken,
      );
    } catch (_) {
      return (tracks: <Track>[], continuationToken: null);
    }
  }

  Future<List<Track>> fetchPlaylistTracks(String browseId,
      {int maxTracks = 200}) async {
    final result = await fetchPlaylistTracksWithContinuation(browseId, maxTracks: maxTracks);
    return result.tracks;
  }

  Future<List<Track>> getRecommendedQueue(
    String videoId, {
    String? playlistId,
    int maxResults = 50,
  }) async {
    try {
      // Prime visitor data with a player request so the next API returns the full queue
      // (YouTube Music often returns minimal/empty queue when visitorData is missing).
      // Fire-and-forget — we don't need the result and don't want to block queue loading.
      getSongFromPlayer(videoId).ignore();

      var list = await _ytMusic.next.fetchNext(
        videoId: videoId,
        playlistId: playlistId,
      );
      if (list.isEmpty) {
        log('getRecommendedQueue: first fetchNext returned 0 tracks, retrying once',
            tag: 'Queue');
        await Future<void>.delayed(const Duration(milliseconds: 400));
        list = await _ytMusic.next.fetchNext(
          videoId: videoId,
          playlistId: playlistId,
        );
      }
      if (list.isEmpty) {
        log('getRecommendedQueue: next.fetchNext returned 0 tracks for videoId=$videoId',
            tag: 'Queue');
      }
      return list.take(maxResults).map(_scrapperTrackToApp).toList();
    } catch (e, st) {
      log('getRecommendedQueue error: $e', tag: 'Queue');
      log('getRecommendedQueue stack: $st', tag: 'Queue');
      return [];
    }
  }

  Future<MoodDetailResult> getMoodDetail(
    String browseId, {
    String? params,
  }) async {
    try {
      final detail = await _ytMusic.browse.fetchMoodDetail(
        browseId,
        params: params,
      );
      return MoodDetailResult(
        subCategories: detail.subCategories
            .map((m) => RelatedMoodItem(
                  title: m.title,
                  browseId: m.browseId,
                  params: m.params,
                  sectionTitle: m.sectionTitle,
                ))
            .toList(),
        playlists: detail.playlists
            .map((p) => MoodPlaylist(
                  id: p.id,
                  title: p.title,
                  thumbnailUrl: p.thumbnailUrl,
                  subtitle: p.subtitle,
                ))
            .toList(),
      );
    } catch (_) {
      return const MoodDetailResult();
    }
  }

  Future<CollectionResult> getCollectionTracks(
    String browseId, {
    String? params,
    int maxResults = 0,
  }) async {
    try {
      final maxTracks = maxResults > 0 ? maxResults : 500;
      final tracks = await _ytMusic.browse.fetchPlaylistOrAlbum(
        browseId,
        params: params,
        maxTracks: maxTracks,
      );
      return CollectionResult(
        tracks: tracks.map(_scrapperTrackToApp).toList(),
      );
    } catch (_) {
      return const CollectionResult();
    }
  }

  Future<RelatedHomeFeed> getRelatedHomeFeed(
    String seedVideoId, {
    int maxTracks = 30,
    int maxPlaylists = 12,
    int maxArtists = 12,
    int maxMoodItems = 100,
  }) async {
    final feed = await _ytMusic.browse.fetchHomeFeed(
      maxTracks: maxTracks,
      maxPlaylists: maxPlaylists,
      maxArtists: maxArtists,
      maxMoodItems: maxMoodItems,
    );
    return _scrapperFeedToApp(feed);
  }

  /// Fetches the full moods and genres list from YouTube Music.
  Future<RelatedHomeFeed> getMoodsAndGenresFeed() async {
    final feed = await _ytMusic.browse.fetchMoodsAndGenresFeed();
    return _scrapperFeedToApp(feed);
  }

  Future<LyricsResult> getLyrics(String videoId) async {
    try {
      final browseId = await _ytMusic.next.getLyricsBrowseId(videoId);
      if (browseId == null || browseId.isEmpty) return LyricsResult.empty;
      final raw = await _ytMusic.browse.fetchLyrics(browseId);
      if (raw == null) return LyricsResult.empty;
      final fullText = raw['fullText'] as String? ?? '';
      final source = raw['source'] as String?;
      final isSynced = raw['isSynced'] as bool? ?? false;
      final rawLines = raw['lines'] as List<dynamic>? ?? [];
      final lines = rawLines.map((e) {
        final map = e as Map<String, dynamic>;
        final text = map['text'] as String? ?? '';
        final startMs = map['startTimeMs'] as int?;
        return LyricsLine(
          text: text,
          startTime: startMs != null ? Duration(milliseconds: startMs) : null,
        );
      }).toList();
      return LyricsResult(
        fullText: fullText,
        lines: lines,
        source: source,
        isSynced: isSynced,
      );
    } catch (_) {
      return LyricsResult.empty;
    }
  }

  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      return await _ytMusic.search.getSearchSuggestions(query);
    } catch (_) {
      return [];
    }
  }

  Future<SearchBrowseIdsResult> searchResolveBrowseIds(
    String query, {
    String? preferredArtistName,
  }) async {
    String? artistBrowseId;
    String? albumBrowseId;

    // Step A: general (unfiltered) search — best source for card-shelf browse IDs.
    try {
      final map = await _ytMusic.search.searchResolveBrowseIds(
        query,
        preferredArtistName: preferredArtistName,
      );
      artistBrowseId = map['artistBrowseId'];
      albumBrowseId = map['albumBrowseId'];
    } catch (_) {}

    // Step B: song-filtered search — top result's track metadata reliably
    // carries albumBrowseId when the general search card shelf doesn't.
    if (albumBrowseId == null) {
      try {
        final tracks = await _ytMusic.search.searchMusic(query, maxResults: 3);
        for (final t in tracks) {
          if (artistBrowseId == null && t.artistBrowseId != null) {
            artistBrowseId = t.artistBrowseId;
          }
          if (t.albumBrowseId != null) {
            albumBrowseId = t.albumBrowseId;
            break;
          }
        }
      } catch (_) {}
    }

    return SearchBrowseIdsResult(
      artistBrowseId: artistBrowseId,
      albumBrowseId: albumBrowseId,
    );
  }

  void clearCache() {
    _streamCache.clear();
    _db?.clearAllStreamUrlCache().ignore();
    _hiveBox?.clear().ignore();
  }

  Map<String, int> getStats() => {
        'hits': _hits,
        'misses': _misses,
      };

  void dispose() {
    _ytDirect.dispose();
    _qualityNotifier.dispose();
  }
}
