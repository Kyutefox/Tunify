import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tunify/core/constants/storage_keys.dart';
import 'package:tunify/data/models/artist.dart';
import 'package:tunify/data/models/related_feed.dart';
import 'package:tunify/data/models/track.dart';
import 'package:tunify/data/models/mood.dart';
import 'package:tunify/data/models/playlist.dart';
import 'package:tunify/data/models/recently_played_song.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/data/repositories/database_repository.dart';
import 'package:tunify_logger/tunify_logger.dart';
import 'package:tunify/features/settings/music_stream_manager.dart';
import 'package:tunify/core/utils/list_utils.dart';
import 'package:tunify/features/auth/auth_provider.dart';
import 'package:tunify/features/player/player_state_provider.dart';

/// A single dynamic section in the home feed: may contain songs, playlists, or artists.
class HomeSongSection {
  final HomeSectionType type;
  final String title;
  final String? subtitle;
  final List<Song> songs;
  final List<Playlist> playlists;
  final List<Artist> artists;

  late final String titleLower = title.toLowerCase();

  HomeSongSection({
    required this.type,
    required this.title,
    this.subtitle,
    this.songs = const [],
    this.playlists = const [],
    this.artists = const [],
  });
}

/// Content type tag for a [HomeSongSection], used to select the correct render widget.
enum HomeSectionType {
  songs,
  playlists,
  artists,
}

/// Immutable snapshot of the home screen feed.
class HomeState {
  final bool isLoading;
  final bool isLoaded;
  final String? error;
  final List<Song> quickPicks;
  final List<Song> recentlyPlayed;
  final List<Playlist> playlists;
  final List<Artist> artists;
  final List<Mood> moods;
  final List<HomeSongSection> dynamicSections;
  final Color? dominantColor;
  final String? featuredArtworkUrl;
  final List<DateTime> recentlyPlayedTimestamps;

  /// Incremented when feed content is replaced (used for smooth UI transition).
  final int feedVersion;

  /// True when a new feed has been fetched in background and is waiting to be applied.
  /// When true, UI should show skeleton and then apply the pending content.
  final bool hasPendingUpdate;

  /// The pending feed content to be applied when user visits homepage.
  final HomeState? pendingFeed;

  /// True only during initial app load. Used to show full LoadingScreen vs skeleton.
  final bool isInitialLoading;

  const HomeState({
    this.isLoading = false,
    this.isLoaded = false,
    this.error,
    this.quickPicks = const [],
    this.recentlyPlayed = const [],
    this.playlists = const [],
    this.artists = const [],
    this.moods = const [],
    this.dynamicSections = const [],
    this.dominantColor,
    this.featuredArtworkUrl,
    this.recentlyPlayedTimestamps = const [],
    this.feedVersion = 0,
    this.hasPendingUpdate = false,
    this.pendingFeed,
    this.isInitialLoading = false,
  });

  /// NOTE: [error] is applied directly — not merged with null-coalescing.
  /// Pass `null` to clear the error. Pass `this.error` explicitly to preserve it.
  /// Unlike all other fields, omitting [error] does NOT preserve the current value.
  HomeState copyWith({
    bool? isLoading,
    bool? isLoaded,
    String? error,
    List<Song>? quickPicks,
    List<Song>? recentlyPlayed,
    List<Playlist>? playlists,
    List<Artist>? artists,
    List<Mood>? moods,
    List<HomeSongSection>? dynamicSections,
    Color? dominantColor,
    String? featuredArtworkUrl,
    List<DateTime>? recentlyPlayedTimestamps,
    int? feedVersion,
    bool? hasPendingUpdate,
    HomeState? pendingFeed,
    bool? isInitialLoading,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      error: error,
      quickPicks: quickPicks ?? this.quickPicks,
      recentlyPlayed: recentlyPlayed ?? this.recentlyPlayed,
      playlists: playlists ?? this.playlists,
      artists: artists ?? this.artists,
      moods: moods ?? this.moods,
      dynamicSections: dynamicSections ?? this.dynamicSections,
      dominantColor: dominantColor ?? this.dominantColor,
      featuredArtworkUrl: featuredArtworkUrl ?? this.featuredArtworkUrl,
      recentlyPlayedTimestamps:
          recentlyPlayedTimestamps ?? this.recentlyPlayedTimestamps,
      feedVersion: feedVersion ?? this.feedVersion,
      hasPendingUpdate: hasPendingUpdate ?? this.hasPendingUpdate,
      pendingFeed: pendingFeed,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
    );
  }
}

/// Top-level function for use with [compute] — encodes the home feed cache map.
/// Must be top-level (not a closure) to be sendable across isolates.
String _encodeHomeCacheMap(Map<String, dynamic> map) => jsonEncode(map);

/// Top-level function for use with [compute] — decodes the home feed cache JSON.
Map<String, dynamic> _decodeHomeCacheJson(String raw) =>
    jsonDecode(raw) as Map<String, dynamic>;

/// Drives the home screen feed lifecycle: initial load, cache restore, background refresh,
/// and recently-played tracking.
///
/// On first launch the feed is fetched live; on subsequent launches the persisted
/// [SharedPreferences] cache is shown immediately while a background refresh runs.
/// YT visitor data is restored from cache or Supabase before each feed fetch to ensure
/// personalized results.
class HomeNotifier extends Notifier<HomeState> {
  MusicStreamManager get _streamManager => ref.read(streamManagerProvider);
  DatabaseRepository get _repository => ref.read(databaseRepositoryProvider);
  static const String _defaultSeedVideoId = 'J7p4bzqLvCw';

  /// Gradient palette mirroring [_mapMoods] order, used when deserializing moods from the disk cache.
  /// Gradient palette mirroring [_mapMoods] order, used when deserializing moods from the disk cache.
  /// Stored by index rather than by color value so gradient objects don't need to be serialized.
  static const List<LinearGradient> _cacheMoodGradients = [
    LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight),
    LinearGradient(
        colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft),
    LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFF97316)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight),
    LinearGradient(
        colors: [Color(0xFFEC4899), Color(0xFFA855F7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter),
    LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight),
    LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft),
    LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight),
    LinearGradient(
        colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter),
    LinearGradient(
        colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight),
    LinearGradient(
        colors: [Color(0xFFF97316), Color(0xFFFBBF24)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft),
    LinearGradient(
        colors: [Color(0xFFE11D48), Color(0xFFEC4899)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight),
    LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter),
    LinearGradient(
        colors: [Color(0xFF059669), Color(0xFF0D9488)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight),
    LinearGradient(
        colors: [Color(0xFFDB2777), Color(0xFF9333EA)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft),
    LinearGradient(
        colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight),
    LinearGradient(
        colors: [Color(0xFFDC2626), Color(0xFF9F1239)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter),
    LinearGradient(
        colors: [Color(0xFF0891B2), Color(0xFF6366F1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight),
    LinearGradient(
        colors: [Color(0xFF65A30D), Color(0xFF16A34A)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft),
    LinearGradient(
        colors: [Color(0xFFC026D3), Color(0xFF7C3AED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight),
    LinearGradient(
        colors: [Color(0xFFEA580C), Color(0xFFD97706)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter),
  ];
  bool _backgroundFetchInProgress = false;
  bool _preparedForLogin = false;

  /// In-memory copy of the last successful feed state.
  /// Shown immediately on [loadContent] while a background refresh runs, avoiding a skeleton flash.
  HomeState? _cache;

  @override
  HomeState build() {
    _loadRecentlyPlayed();
    return const HomeState();
  }

  /// Called during login hydration (before showing AppShell). Applies YT config
  /// from SQLite, loads recently played, then fetches the home feed so the
  /// first paint shows Supabase-backed data with no pop-in or jitter.
  Future<void> prepareHomeForLogin() async {
    state = const HomeState();
    await _loadRecentlyPlayed();
    await _restoreVisitorData();
    await _loadFeedAndUpdateState();
    _preparedForLogin = true;
  }

  Future<void> onAuthChanged(User? user) async {
    if (_preparedForLogin) {
      _preparedForLogin = false;
      return;
    }
    _cache = null;
    state = const HomeState();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(StorageKeys.prefsHomeFeedCache);
    } catch (_) {}
    await _loadRecentlyPlayed();
    await loadContent();
  }

  Future<void> _loadRecentlyPlayed() async {
    try {
      final user = ref.read(currentUserProvider);
      final history = await _repository.loadRecentlyPlayed(
        userId: user?.id,
      );
      if (history.isEmpty) return;
      final songs = history
          .map((h) => Song(
                id: h.id,
                title: h.title,
                artist: h.artist,
                thumbnailUrl: h.thumbnailUrl,
                duration: Duration(seconds: h.durationSeconds),
              ))
          .toList();
      final timestamps = history.map((h) => h.lastPlayed).toList();
      state = state.copyWith(
        recentlyPlayed: songs,
        recentlyPlayedTimestamps: timestamps,
      );
    } catch (e) {
      logWarning('Home: _loadRecentlyPlayedFromDb failed: $e', tag: 'Home');
    }
  }

  // Valid VISITOR_DATA token length bounds.
  // The correct personalisation token from ytcfg.set() (after a
  // cookie-aware two-step fetch) used to be ~45–120 chars URL-encoded,
  // but newer tokens can be significantly longer. We still keep a sane
  // lower bound to filter obvious garbage, but relax the upper bound so
  // valid personalised tokens are not discarded on every launch.
  static const int _kMinVisitorDataLength = 30;
  static const int _kMaxVisitorDataLength = 600;

  /// If cache exists (in-memory or persisted on app start), show it and optionally refetch in background; otherwise full fetch with skeleton.
  /// Background refresh now stores pending content instead of updating UI.
  Future<void> loadContent() async {
    // Don't reload if content is already loaded
    if (state.isLoaded && _hasUsableCache) return;
    if (state.isLoading && !_hasUsableCache) return;
    final hasCache = _hasUsableCache;
    if (hasCache) {
      // Preserve current recentlyPlayed — _cache is only updated by feed fetches,
      // so it lags behind addToRecentlyPlayed() calls. Stomping state with _cache!
      // directly would silently erase tracks the user just played (especially
      // visible for guests who replay the home screen via refresh()).
      state = _cache!.copyWith(
        recentlyPlayed: state.recentlyPlayed,
        recentlyPlayedTimestamps: state.recentlyPlayedTimestamps,
      );
      // Trigger silent background fetch - stores pending content instead of updating UI
      unawaited(_silentBackgroundFetch());
      return;
    }
    // App start: try restore from persisted cache so we show content immediately instead of skeleton.
    final restored = await _restoreFromPersistedCache();
    if (restored) {
      // Trigger silent background fetch - stores pending content instead of updating UI
      unawaited(_silentBackgroundFetch());
      return;
    }
    // No cache: show skeleton and fetch foreground
    state = state.copyWith(
        isLoading: true, isLoaded: false, error: null, isInitialLoading: true);
    try {
      await _restoreVisitorData();
      await _loadFeedAndUpdateState(isBackgroundRefresh: false);
    } catch (e) {
      logError('loadContent failed: $e', tag: 'HomeNotifier');
      state = state.copyWith(
          isLoading: false, isLoaded: false, isInitialLoading: false);
    }
  }

  /// Silently fetches home feed in background and stores as pending update.
  /// Does not update UI - pending content will be applied when user visits homepage.
  Future<void> _silentBackgroundFetch() async {
    try {
      await _restoreVisitorData();

      // Check if we have API config
      if (!_streamManager.hasApiConfig) {
        await _streamManager.initFromSwJsData();
      }

      final homeFeed = await _streamManager.getRelatedHomeFeed(
        _defaultSeedVideoId,
        maxTracks: 150,
        maxPlaylists: 40,
        maxArtists: 12,
      );

      // Also fetch the full moods list from the dedicated endpoint
      final moodsFeed = await _streamManager.getMoodsAndGenresFeed();

      // Merge moods from both feeds, avoiding duplicates by browseId
      final mergedMoods = <String, RelatedMoodItem>{};
      for (final mood in [...homeFeed.moodItems, ...moodsFeed.moodItems]) {
        final key = '${mood.browseId}|${mood.params ?? ''}';
        if (!mergedMoods.containsKey(key)) {
          mergedMoods[key] = mood;
        }
      }
      final combinedFeed = RelatedHomeFeed(
        trackShelves: homeFeed.trackShelves,
        playlistShelves: homeFeed.playlistShelves,
        artistShelves: homeFeed.artistShelves,
        shelves: homeFeed.shelves,
        moodItems: mergedMoods.values.toList(),
      );

      // Apply as pending update (doesn't change UI)
      _applyFeedToState(combinedFeed, isForeground: false);
    } catch (e) {
      logWarning('HomeFeed: _silentBackgroundFetch failed: $e',
          tag: 'HomeFeed');
    }
  }

  /// Called when user visits the homepage. Applies pending update with skeleton animation if available.
  void applyPendingUpdateIfOnHomepage() {
    if (state.hasPendingUpdate && state.pendingFeed != null) {
      state = state.copyWith(
        isLoading: true,
        isLoaded: false,
      );
      // Apply the pending content after a brief delay to show skeleton
      Future.delayed(const Duration(milliseconds: 300), () {
        if (state.pendingFeed != null) {
          state = state.pendingFeed!.copyWith(
            hasPendingUpdate: false,
            pendingFeed: null,
            recentlyPlayed: state.recentlyPlayed,
            recentlyPlayedTimestamps: state.recentlyPlayedTimestamps,
          );
          _cache = state;
          unawaited(_persistCache());
        }
      });
    }
  }

  /// Public method to trigger silent background fetch.
  /// Can be called after app restart or song played > 15 seconds.
  void triggerSilentRefresh() {
    if (!_backgroundFetchInProgress && !state.hasPendingUpdate) {
      unawaited(_silentBackgroundFetch());
    }
  }

  /// Called when user visits the homepage. Checks for pending updates and applies them.
  /// If there's a pending update, applies the new content directly.
  void visitHomepage() {
    if (state.hasPendingUpdate && state.pendingFeed != null) {
      final pendingFeed = state.pendingFeed;
      state = state.copyWith(
        hasPendingUpdate: false,
        pendingFeed: null,
      );
      if (pendingFeed != null) {
        state = pendingFeed.copyWith(
          recentlyPlayed: state.recentlyPlayed,
          recentlyPlayedTimestamps: state.recentlyPlayedTimestamps,
        );
        _cache = state;
        unawaited(_persistCache());
      }
    }
  }

  bool get _hasUsableCache =>
      _cache != null &&
      _cache!.isLoaded &&
      (_cache!.dynamicSections.isNotEmpty || _cache!.quickPicks.isNotEmpty);

  /// Fetches home feed and updates state. Assumes [_restoreVisitorData] has
  /// already run (YT config from SQLite applied to stream manager).
  /// When [isBackgroundRefresh] is true, does not set loading and updates in place for a smooth transition.
  Future<void> _loadFeedAndUpdateState(
      {bool isBackgroundRefresh = false}) async {
    if (!isBackgroundRefresh) {
      state = state.copyWith(isLoading: true, isLoaded: false, error: null);
    }
    try {
      final currentVd = _streamManager.visitorData;
      final vdLen = currentVd?.length ?? 0;
      final needsFetch = currentVd == null ||
          vdLen < _kMinVisitorDataLength ||
          vdLen > _kMaxVisitorDataLength;
      logInfo(
        'HomeFeed: loadContent visitorData length=$vdLen needsFetch=$needsFetch',
        tag: 'HomeFeed',
      );

      // Initialize API config if needed
      if (!_streamManager.hasApiConfig) {
        await _streamManager.initFromSwJsData();
        final newVd = _streamManager.visitorData;
        if (newVd != null && newVd.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(kYtVisitorDataKey, newVd);
        }
      }

      // If we still don't have API config after trying, clear loading state
      if (!_streamManager.hasApiConfig) {
        if (!isBackgroundRefresh) {
          state = state.copyWith(isLoading: false, isLoaded: false);
        }
        return;
      }

      // Trigger background refresh for future use if needed
      if (needsFetch && !_backgroundFetchInProgress) {
        unawaited(_fetchSwJsDataAndRefresh());
      }

      final homeFeed = await _streamManager.getRelatedHomeFeed(
        _defaultSeedVideoId,
        maxTracks: 150,
        maxPlaylists: 40,
        maxArtists: 12,
      );

      // Also fetch the full moods list from the dedicated endpoint
      final moodsFeed = await _streamManager.getMoodsAndGenresFeed();

      // Merge moods from both feeds, avoiding duplicates by browseId
      final mergedMoods = <String, RelatedMoodItem>{};
      for (final mood in [...homeFeed.moodItems, ...moodsFeed.moodItems]) {
        final key = '${mood.browseId}|${mood.params ?? ''}';
        if (!mergedMoods.containsKey(key)) {
          mergedMoods[key] = mood;
        }
      }
      final combinedFeed = RelatedHomeFeed(
        trackShelves: homeFeed.trackShelves,
        playlistShelves: homeFeed.playlistShelves,
        artistShelves: homeFeed.artistShelves,
        shelves: homeFeed.shelves,
        moodItems: mergedMoods.values.toList(),
      );

      _applyFeedToState(combinedFeed, isForeground: !isBackgroundRefresh);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches the YouTube Music main page via [VisitorDataFetcher] to obtain a
  /// fresh VISITOR_DATA token, updates [MusicStreamManager], persists it, and
  /// re-runs the home feed so Quick Picks reflect the current session.
  Future<void> _fetchSwJsDataAndRefresh() async {
    _backgroundFetchInProgress = true;
    logInfo('HomeFeed: _fetchSwJsDataAndRefresh start', tag: 'HomeFeed');
    try {
      await _streamManager.initFromSwJsData();
      final newVd = _streamManager.visitorData;
      if (newVd == null || newVd.isEmpty) {
        logWarning('HomeFeed: sw.js_data fetch returned no visitorData',
            tag: 'HomeFeed');
        return;
      }
      logInfo(
          'HomeFeed: got visitorData length=${newVd.length} – persisting and refreshing',
          tag: 'HomeFeed');

      // Persist locally.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kYtVisitorDataKey, newVd);

      // Refresh the feed with the new visitor data so the home UI reflects
      // the latest personalisation from this device/session.
      final homeFeed = await _streamManager.getRelatedHomeFeed(
        _defaultSeedVideoId,
        maxTracks: 150,
        maxPlaylists: 40,
        maxArtists: 12,
      );

      // Also fetch the full moods list from the dedicated endpoint
      final moodsFeed = await _streamManager.getMoodsAndGenresFeed();

      // Merge moods from both feeds, avoiding duplicates by browseId
      final mergedMoods = <String, RelatedMoodItem>{};
      for (final mood in [...homeFeed.moodItems, ...moodsFeed.moodItems]) {
        final key = '${mood.browseId}|${mood.params ?? ''}';
        if (!mergedMoods.containsKey(key)) {
          mergedMoods[key] = mood;
        }
      }
      final combinedFeed = RelatedHomeFeed(
        trackShelves: homeFeed.trackShelves,
        playlistShelves: homeFeed.playlistShelves,
        artistShelves: homeFeed.artistShelves,
        shelves: homeFeed.shelves,
        moodItems: mergedMoods.values.toList(),
      );

      _applyFeedToState(combinedFeed, isForeground: false);
    } catch (e) {
      logWarning('HomeFeed: _fetchSwJsDataAndRefresh failed: $e',
          tag: 'HomeFeed');
      if (state.isLoading) {
        state = state.copyWith(isLoading: false, isLoaded: false);
      }
    } finally {
      _backgroundFetchInProgress = false;
    }
  }

  /// Builds state from [homeFeed], sets [state] and [_cache], and kicks off
  /// background persist + Supabase sync. Called from both
  /// [_loadFeedAndUpdateState] and [_fetchSwJsDataAndRefresh] to avoid duplication.
  ///
  /// [isForeground] indicates if this is a user-initiated fetch (pull-to-refresh)
  /// or a silent background fetch. Background fetches store pending content instead
  /// of applying immediately.
  void _applyFeedToState(RelatedHomeFeed homeFeed, {bool isForeground = true}) {
    final sections = _buildSections(homeFeed);
    final quickPicks = _quickPicksFromFeed(sections, homeFeed);
    final newFeedState = HomeState(
      isLoaded: true,
      isLoading: false,
      isInitialLoading: false,
      quickPicks: quickPicks,
      dynamicSections: sections,
      playlists: uniqueById(_mapPlaylists(homeFeed.playlists), (p) => p.id)
          .take(12)
          .toList(),
      artists: uniqueById(_mapArtists(homeFeed.artists), (a) => a.id)
          .take(12)
          .toList(),
      moods: _mapMoods(homeFeed.moodItems),
      featuredArtworkUrl: quickPicks.isNotEmpty
          ? quickPicks.first.thumbnailUrl
          : (homeFeed.playlists.isNotEmpty
              ? homeFeed.playlists.first.thumbnailUrl
              : null),
      feedVersion: state.feedVersion + 1,
    );

    if (isForeground) {
      // User-initiated fetch: apply immediately, preserving recentlyPlayed
      state = newFeedState.copyWith(
        recentlyPlayed: state.recentlyPlayed,
        recentlyPlayedTimestamps: state.recentlyPlayedTimestamps,
      );
      _cache = state;
      unawaited(_persistCache());
      unawaited(_syncVisitorDataToSupabaseIfNeeded());
    } else {
      // Silent background fetch: store as pending, don't update UI
      state = state.copyWith(
        hasPendingUpdate: true,
        pendingFeed: newFeedState,
      );
      _cache = newFeedState;
      unawaited(_persistCache());
    }
  }

  Future<void> _restoreVisitorData() async {
    final prefs = await SharedPreferences.getInstance();
    final localData = prefs.getString(kYtVisitorDataKey);

    // Restore cached apiKey/clientVersion first so that the YoutubeMusic
    // instance rebuilt by setVisitorData() below already has them baked in.
    final cachedApiKey = prefs.getString(StorageKeys.prefsYtApiKey);
    final cachedClientVersion =
        prefs.getString(StorageKeys.prefsYtClientVersion);
    _streamManager.applyCachedApiConfig(cachedApiKey, cachedClientVersion);

    // Only restore if the stored token is in the valid short-token range.
    // Tokens > _kMaxVisitorDataLength are stale service-worker blobs from
    // the old implementation and must be discarded so a fresh fetch runs.
    final localValid = localData != null &&
        localData.isNotEmpty &&
        localData.length >= _kMinVisitorDataLength &&
        localData.length <= _kMaxVisitorDataLength;

    if (localValid) {
      // Local token takes priority — it's the freshest and has the most
      // accumulated history for this device.
      _streamManager.setVisitorData(localData);
      return;
    }

    // Stale or absent local token — clear it so the length check triggers a fetch.
    if (localData != null && localData.isNotEmpty) {
      await prefs.remove(kYtVisitorDataKey);
      logInfo(
          'Home: cleared stale long visitorData token (len=${localData.length})',
          tag: 'Home');
    }

    // No valid local token — use SQLite (filled on login via pullFromSupabase).
    try {
      final yt =
          await ref.read(databaseRepositoryProvider).loadYtPersonalization();
      final cloudData = yt['visitor_data'] as String?;
      final cloudApiKey = yt['api_key'] as String?;
      final cloudClientVersion = yt['client_version'] as String?;

      if (cloudApiKey != null && cloudApiKey.toString().isNotEmpty) {
        await prefs.setString(
            StorageKeys.prefsYtApiKey, cloudApiKey.toString());
        _streamManager.applyCachedApiConfig(
            cloudApiKey.toString(), cloudClientVersion?.toString());
      }
      if (cloudClientVersion != null &&
          cloudClientVersion.toString().isNotEmpty) {
        await prefs.setString(
            StorageKeys.prefsYtClientVersion, cloudClientVersion.toString());
        _streamManager.applyCachedApiConfig(
            cloudApiKey?.toString(), cloudClientVersion.toString());
      }
      if (cloudData != null &&
          cloudData.isNotEmpty &&
          cloudData.length <= _kMaxVisitorDataLength) {
        _streamManager.setVisitorData(cloudData);
        await prefs.setString(kYtVisitorDataKey, cloudData);
      }
    } catch (_) {}
  }

  /// Persists current feed to disk so app start can show it from cache.
  Future<void> _persistCache() async {
    if (!state.isLoaded ||
        (state.dynamicSections.isEmpty && state.quickPicks.isEmpty)) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, dynamic>{
        'quickPicks': state.quickPicks.map((s) => s.toJson()).toList(),
        'dynamicSections': state.dynamicSections.map((s) {
          return <String, dynamic>{
            'type': s.type.index,
            'title': s.title,
            'subtitle': s.subtitle,
            'songs': s.songs.map((e) => e.toJson()).toList(),
            'playlists':
                s.playlists.map((p) => _playlistToCacheJson(p)).toList(),
            'artists': s.artists.map((a) => _artistToCacheJson(a)).toList(),
          };
        }).toList(),
        'playlists': state.playlists.map(_playlistToCacheJson).toList(),
        'artists': state.artists.map(_artistToCacheJson).toList(),
        'moods': state.moods.asMap().entries.map((e) {
          return <String, dynamic>{
            'id': e.value.id,
            'label': e.value.label,
            'query': e.value.query,
            'browseId': e.value.browseId,
            'browseParams': e.value.browseParams,
            'emoji': e.value.emoji,
            'subtitle': e.value.subtitle,
            'gradientIndex': e.key % _cacheMoodGradients.length,
          };
        }).toList(),
        'featuredArtworkUrl': state.featuredArtworkUrl,
        'feedVersion': state.feedVersion,
      };
      final encoded = map.length > 20
          ? await compute(_encodeHomeCacheMap, map)
          : _encodeHomeCacheMap(map);
      await prefs.setString(StorageKeys.prefsHomeFeedCache, encoded);
    } catch (e) {
      logWarning('Home: _persistCache failed: $e', tag: 'Home');
    }
  }

  Map<String, dynamic> _playlistToCacheJson(Playlist p) => {
        'id': p.id,
        'title': p.title,
        'description': p.description,
        'coverUrl': p.coverUrl,
        'curatorName': p.curatorName,
        'trackCount': p.trackCount,
      };

  Map<String, dynamic> _artistToCacheJson(Artist a) => {
        'id': a.id,
        'name': a.name,
        'avatarUrl': a.avatarUrl,
        'latestRelease': a.latestRelease,
      };

  /// Restores feed from disk on app start. Returns true if restored and state/cache were set.
  Future<bool> _restoreFromPersistedCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(StorageKeys.prefsHomeFeedCache);
      if (raw == null || raw.isEmpty) return false;
      final map = raw.length > 10000
          ? await compute(_decodeHomeCacheJson, raw)
          : _decodeHomeCacheJson(raw);
      final quickPicksList = map['quickPicks'] as List<dynamic>?;
      final dynamicSectionsList = map['dynamicSections'] as List<dynamic>?;
      final playlistsList = map['playlists'] as List<dynamic>?;
      final artistsList = map['artists'] as List<dynamic>?;
      final moodsList = map['moods'] as List<dynamic>?;
      if (quickPicksList == null &&
          (dynamicSectionsList == null || dynamicSectionsList.isEmpty)) {
        return false;
      }
      final quickPicks = quickPicksList != null
          ? quickPicksList
              .map((e) => Song.fromJson(e as Map<String, dynamic>))
              .toList(growable: false)
          : <Song>[];
      final dynamicSections = dynamicSectionsList != null
          ? dynamicSectionsList.map((e) {
              final m = e as Map<String, dynamic>;
              final typeIndex = m['type'] as int? ?? 0;
              final type = HomeSectionType.values[
                  typeIndex.clamp(0, HomeSectionType.values.length - 1)];
              return HomeSongSection(
                type: type,
                title: m['title'] as String? ?? '',
                subtitle: m['subtitle'] as String?,
                songs: (m['songs'] as List<dynamic>?)
                        ?.map((s) => Song.fromJson(s as Map<String, dynamic>))
                        .toList(growable: false) ??
                    const [],
                playlists: (m['playlists'] as List<dynamic>?)
                        ?.map((p) =>
                            _playlistFromCacheJson(p as Map<String, dynamic>))
                        .toList() ??
                    const [],
                artists: (m['artists'] as List<dynamic>?)
                        ?.map((a) =>
                            _artistFromCacheJson(a as Map<String, dynamic>))
                        .toList() ??
                    const [],
              );
            }).toList(growable: false)
          : <HomeSongSection>[];
      if (quickPicks.isEmpty && dynamicSections.isEmpty) return false;
      final playlists = playlistsList != null
          ? playlistsList
              .map((p) => _playlistFromCacheJson(p as Map<String, dynamic>))
              .toList(growable: false)
          : <Playlist>[];
      final artists = artistsList != null
          ? artistsList
              .map((a) => _artistFromCacheJson(a as Map<String, dynamic>))
              .toList(growable: false)
          : <Artist>[];
      final moods = moodsList != null
          ? moodsList.asMap().entries.map((e) {
              final m = e.value as Map<String, dynamic>;
              final gi = m['gradientIndex'] as int? ?? 0;
              return Mood(
                id: m['id'] as String? ?? '',
                label: m['label'] as String? ?? '',
                query: m['query'] as String? ?? '',
                browseId: m['browseId'] as String?,
                browseParams: m['browseParams'] as String?,
                emoji: m['emoji'] as String? ?? '',
                subtitle: m['subtitle'] as String?,
                gradient: _cacheMoodGradients[gi % _cacheMoodGradients.length],
              );
            }).toList(growable: false)
          : <Mood>[];
      final restored = HomeState(
        isLoaded: true,
        isLoading: false,
        quickPicks: quickPicks,
        dynamicSections: dynamicSections,
        playlists: playlists,
        artists: artists,
        moods: moods,
        featuredArtworkUrl: map['featuredArtworkUrl'] as String?,
        feedVersion: (map['feedVersion'] as int?) ?? 0,
        recentlyPlayed: state.recentlyPlayed,
        recentlyPlayedTimestamps: state.recentlyPlayedTimestamps,
      );
      _cache = restored;
      state = restored;
      return true;
    } catch (e) {
      logWarning('Home: _restoreFromPersistedCache failed: $e', tag: 'Home');
      return false;
    }
  }

  Playlist _playlistFromCacheJson(Map<String, dynamic> m) => Playlist(
        id: m['id'] as String? ?? '',
        title: m['title'] as String? ?? '',
        description: m['description'] as String? ?? '',
        coverUrl: m['coverUrl'] as String? ?? '',
        curatorName: m['curatorName'] as String?,
        trackCount: (m['trackCount'] as int?) ?? 0,
      );

  Artist _artistFromCacheJson(Map<String, dynamic> m) => Artist(
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? '',
        avatarUrl: m['avatarUrl'] as String? ?? '',
        latestRelease: m['latestRelease'] as String?,
      );

  List<HomeSongSection> _buildSections(RelatedHomeFeed feed) {
    final sections = <HomeSongSection>[];

    for (final shelf in feed.trackShelves) {
      final titleLower = shelf.title.toLowerCase();
      if (_isHiddenTrackSection(titleLower)) continue;
      final songs = _mapTracks(shelf.tracks).take(20).toList(growable: false);
      if (songs.isEmpty) continue;
      sections.add(
        HomeSongSection(
          type: HomeSectionType.songs,
          title: shelf.title,
          subtitle: shelf.subtitle,
          songs: songs,
        ),
      );
    }

    for (final shelf in feed.playlistShelves) {
      final playlists = uniqueById(_mapPlaylists(shelf.playlists), (p) => p.id)
          .take(12)
          .toList();
      if (playlists.isEmpty) continue;
      sections.add(
        HomeSongSection(
          type: HomeSectionType.playlists,
          title: shelf.title,
          subtitle: shelf.subtitle,
          playlists: playlists,
        ),
      );
    }

    for (final shelf in feed.artistShelves) {
      final artists =
          uniqueById(_mapArtists(shelf.artists), (a) => a.id).take(12).toList();
      if (artists.isEmpty) continue;
      sections.add(
        HomeSongSection(
          type: HomeSectionType.artists,
          title: shelf.title,
          subtitle: shelf.subtitle,
          artists: artists,
        ),
      );
    }

    return sections;
  }

  Future<void> _syncVisitorDataToSupabaseIfNeeded() async {
    final visitorData = _streamManager.visitorData;
    if (visitorData == null || visitorData.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString(StorageKeys.prefsYtApiKey);
      final clientVersion = prefs.getString(StorageKeys.prefsYtClientVersion);
      await ref.read(databaseRepositoryProvider).saveYtPersonalization({
        'visitor_data': visitorData,
        if (apiKey != null && apiKey.isNotEmpty) 'api_key': apiKey,
        if (clientVersion != null && clientVersion.isNotEmpty)
          'client_version': clientVersion,
      });
    } catch (e) {
      logWarning('Home: _syncVisitorDataToSupabaseIfNeeded failed: $e',
          tag: 'Home');
    }
  }

  Future<void> refresh() async {
    // User-initiated refresh: show skeleton and fetch foreground
    state = state.copyWith(isLoading: true, isLoaded: false, error: null);
    try {
      await _restoreVisitorData();
      await _loadFeedAndUpdateState(isBackgroundRefresh: false);
    } catch (e) {
      logError('refresh failed: $e', tag: 'HomeNotifier');
      state = state.copyWith(isLoading: false, isLoaded: false);
    }
  }

  void addToRecentlyPlayed(Song song) {
    final current = List<Song>.from(state.recentlyPlayed);
    final currentTs = List<DateTime>.from(state.recentlyPlayedTimestamps);
    final idx = current.indexWhere((s) => s.id == song.id);
    if (idx >= 0) {
      current.removeAt(idx);
      if (idx < currentTs.length) currentTs.removeAt(idx);
    }
    current.insert(0, song);
    currentTs.insert(0, DateTime.now());
    if (current.length > 20) {
      current.removeLast();
      if (currentTs.length > 20) currentTs.removeLast();
    }
    state = state.copyWith(
      recentlyPlayed: current,
      recentlyPlayedTimestamps: currentTs,
    );

    _saveRecentlyPlayed(current, currentTs);
  }

  Future<void> _saveRecentlyPlayed(
      List<Song> songs, List<DateTime> timestamps) async {
    try {
      final user = ref.read(currentUserProvider);
      final now = DateTime.now();
      final history = <RecentlyPlayedSong>[];
      for (var i = 0; i < songs.length; i++) {
        if (songs[i].id.startsWith('device_')) continue;
        history.add(RecentlyPlayedSong(
          id: songs[i].id,
          title: songs[i].title,
          artist: songs[i].artist,
          thumbnailUrl: songs[i].thumbnailUrl,
          durationSeconds: songs[i].duration.inSeconds,
          lastPlayed: i < timestamps.length ? timestamps[i] : now,
        ));
      }
      await _repository.saveRecentlyPlayed(
        history,
        userId: user?.id,
      );
    } catch (e) {
      logWarning('Home: _saveRecentlyPlayed failed: $e', tag: 'Home');
    }
  }

  void updateDominantColor(Color color) {
    state = state.copyWith(dominantColor: color);
  }

  static bool _isHiddenTrackSection(String titleLower) {
    return titleLower.contains('top music video') ||
        titleLower.contains('music videos for you');
  }

  List<Song> _quickPicksFromFeed(
    List<HomeSongSection> mergedSections,
    RelatedHomeFeed feed,
  ) {
    final quickIndex = mergedSections.indexWhere(
      (s) =>
          s.type == HomeSectionType.songs &&
          s.title.toLowerCase().contains('quick pick'),
    );
    final firstSongSection =
        mergedSections.where((s) => s.type == HomeSectionType.songs);
    return quickIndex >= 0
        ? mergedSections[quickIndex].songs
        : (firstSongSection.isNotEmpty
            ? firstSongSection.first.songs
            : _mapTracks(feed.tracks).take(20).toList(growable: false));
  }

  List<Song> _mapTracks(List<Track> tracks) {
    return tracks.map(Song.fromTrack).toList(growable: false);
  }

  List<Playlist> _mapPlaylists(List<RelatedPlaylist> playlists) {
    return playlists
        .map(
          (p) => Playlist(
            id: p.id,
            title: p.title,
            description: p.curatorName ?? 'Recommended on YouTube Music',
            coverUrl: p.thumbnailUrl,
            curatorName: p.curatorName,
            trackCount: p.trackCount ?? 0,
          ),
        )
        .toList(growable: false);
  }

  List<Artist> _mapArtists(List<RelatedArtist> artists) {
    return artists
        .map(
          (a) => Artist(
            id: a.id,
            name: a.name,
            avatarUrl: a.thumbnailUrl,
            latestRelease: a.subtitle,
          ),
        )
        .toList(growable: false);
  }

  static const List<String> _moodEmojis = [
    '🎵',
    '🎸',
    '🎹',
    '🎺',
    '🥁',
    '🎻',
    '🎤',
    '🎧',
    '🎶',
    '🎷',
    '🪗',
    '🪘',
    '🎼',
    '🎙️',
    '🎚️',
    '🎛️',
    '🌟',
    '🔥',
    '💫',
    '🌈',
    '⚡',
    '🌙',
    '☀️',
    '🌊',
  ];

  List<Mood> _mapMoods(List<RelatedMoodItem> moodItems) {
    return moodItems.asMap().entries.map((entry) {
      final index = entry.key;
      final mood = entry.value;
      return Mood(
        id: mood.browseId,
        label: mood.title,
        query: mood.title,
        browseId: mood.browseId,
        browseParams: mood.params,
        emoji: _moodEmojis[index % _moodEmojis.length],
        subtitle: mood.sectionTitle,
        gradient: _cacheMoodGradients[index % _cacheMoodGradients.length],
      );
    }).toList(growable: false);
  }
}

final homeProvider =
    NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);

final homeIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(homeProvider.select((s) => s.isLoading));
});

final homeIsLoadedProvider = Provider<bool>((ref) {
  return ref.watch(homeProvider.select((s) => s.isLoaded));
});

final recentlyPlayedProvider = Provider<List<Song>>((ref) {
  return ref.watch(homeProvider.select((s) => s.recentlyPlayed));
});

final quickPicksProvider = Provider<List<Song>>((ref) {
  return ref.watch(homeProvider.select((s) => s.quickPicks));
});

final homePlaylistsProvider = Provider<List<Playlist>>((ref) {
  return ref.watch(homeProvider.select((s) => s.playlists));
});

final homeArtistsProvider = Provider<List<Artist>>((ref) {
  return ref.watch(homeProvider.select((s) => s.artists));
});

final homeDynamicSectionsProvider = Provider<List<HomeSongSection>>((ref) {
  return ref.watch(homeProvider.select((s) => s.dynamicSections));
});

final homeFeedVersionProvider = Provider<int>((ref) {
  return ref.watch(homeProvider.select((s) => s.feedVersion));
});

final greetingProvider = Provider.autoDispose<String>((ref) {
  final now = DateTime.now();
  final hour = now.hour;
  // Invalidate at the next hour boundary so greeting updates automatically.
  final minutesUntilNextHour = 60 - now.minute;
  final timer =
      Timer(Duration(minutes: minutesUntilNextHour), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  if (hour < 6) return 'Good Night';
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  if (hour < 21) return 'Good Evening';
  return 'Good Night';
});

final moodsProvider = Provider<List<Mood>>((ref) {
  return ref.watch(homeProvider.select((s) => s.moods));
});

final recentlyPlayedTimestampsProvider = Provider<List<DateTime>>((ref) {
  return ref.watch(homeProvider.select((s) => s.recentlyPlayedTimestamps));
});

final homeHasPendingUpdateProvider = Provider<bool>((ref) {
  return ref.watch(homeProvider.select((s) => s.hasPendingUpdate));
});

final homeIsInitialLoadingProvider = Provider<bool>((ref) {
  return ref.watch(homeProvider.select((s) => s.isInitialLoading));
});
