import 'package:scrapper/models/track.dart';
import 'package:scrapper/youtube_music/client/yt_music_client.dart';
import 'package:scrapper/youtube_music/formatters/next_formatter.dart';

/// Wrapper around the YouTube Music `next` endpoint for queue/Up-Next data.
class NextApi {
  final YTMusicClient _client;

  /// Creates a new [NextApi] bound to the given [client].
  NextApi({required YTMusicClient client}) : _client = client;

  /// Fetches the Up‑Next queue for a given [videoId] or [playlistId].
  ///
  /// The method mirrors the behaviour of the YouTube Music web client: it
  /// first requests the standard `next` payload, then optionally follows any
  /// automix preview item and continuation tokens until [maxResults] unique
  /// [Track]s have been collected or no further items are available.
  ///
  /// When [cpn] is provided it is forwarded so that tracking URLs are
  /// consistent with the caller's playback session. When [isAudioOnly] is
  /// `true`, the API is instructed to prefer audio‑only results.
  Future<List<Track>> fetchNext({
    String? videoId,
    String? playlistId,
    int? index,
    String? params,
    String? cpn,
    bool isAudioOnly = true,
    int maxResults = 50,
  }) async {
    try {
      final payload = _client.basePayload();

      if (videoId != null) payload['videoId'] = videoId;
      if (playlistId != null) payload['playlistId'] = playlistId;
      if (index != null) payload['index'] = index;
      if (params != null) payload['params'] = params;
      if (cpn != null && cpn.isNotEmpty) payload['cpn'] = cpn;
      payload['isAudioOnly'] = isAudioOnly;

      final data = await _client.post('next', payload);
      var tracks = NextFormatter.parseNextResponse(data);
      var panel = NextFormatter.extractPlaylistPanel(data);
      var list = List<Track>.from(tracks);
      var seen = list.map((t) => t.id).toSet();

      // When the first response only has the current song + automixPreviewVideoRenderer,
      // request the full "Mix" queue with the automix endpoint (playlistId/params).
      final contents = panel?['contents'] as List<dynamic>?;
      final automixEndpoint = NextFormatter.extractAutomixEndpoint(contents);
      if (automixEndpoint != null && list.length < maxResults) {
        final automixPlaylistId = automixEndpoint['playlistId'] as String?;
        if (automixPlaylistId != null && automixPlaylistId.isNotEmpty) {
          final automixPayload = _client.basePayload();
          automixPayload['isAudioOnly'] = isAudioOnly;
          automixPayload['playlistId'] = automixPlaylistId;
          final automixVideoId = automixEndpoint['videoId'] as String?;
          final automixParams = automixEndpoint['params'] as String?;
          if (automixVideoId != null) {
            automixPayload['videoId'] = automixVideoId;
          }
          if (automixParams != null) automixPayload['params'] = automixParams;

          final automixData = await _client.post('next', automixPayload);
          final automixTracks = NextFormatter.parseNextResponse(automixData);
          panel = NextFormatter.extractPlaylistPanel(automixData);
          for (final t in automixTracks) {
            if (seen.add(t.id) && list.length < maxResults) list.add(t);
          }
        }
      }

      int continuationRounds = 0;
      const maxContinuationRounds = 5;

      while (panel != null &&
          list.length < maxResults &&
          continuationRounds < maxContinuationRounds) {
        continuationRounds++;
        final token = NextFormatter.getContinuationToken(panel);
        if (token == null || token.isEmpty) break;

        final contPayload = _client.basePayload();
        contPayload['continuation'] = token;
        final contData = await _client.post('next', contPayload);
        final result = NextFormatter.parseContinuationResponse(contData);
        if (result == null || result.tracks.isEmpty) break;

        for (final t in result.tracks) {
          if (seen.add(t.id) && list.length < maxResults) list.add(t);
        }
        panel = result.panel;
      }

      return list.take(maxResults).toList();
    } catch (e) {
      return [];
    }
  }

  /// Resolves the browse ID for the "Related" tab for a given [videoId]
  /// (optionally scoped to a [playlistId]). YouTube Music returns this in
  /// `tabs[2].tabRenderer.endpoint.browseEndpoint` of the `next` response.
  /// Browsing that ID returns the related shelves (similar playlists, albums,
  /// artists, songs).
  Future<String?> getRelatedBrowseId(
    String videoId, {
    String? playlistId,
  }) async {
    if (videoId.isEmpty) return null;
    try {
      final payload = _client.basePayload();
      payload['videoId'] = videoId;
      if (playlistId != null && playlistId.isNotEmpty) {
        payload['playlistId'] = playlistId;
      }
      final data = await _client.post('next', payload);
      final tabs = data['contents']
              ?['singleColumnMusicWatchNextResultsRenderer']?['tabbedRenderer']
          ?['watchNextTabbedResultsRenderer']?['tabs'];
      if (tabs is! List || tabs.length < 3) return null;
      final tab2 = tabs[2] as Map<String, dynamic>?;
      final endpoint = tab2?['tabRenderer']?['endpoint']?['browseEndpoint'];
      if (endpoint is! Map<String, dynamic>) return null;
      return endpoint['browseId'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Resolves the browse ID that serves lyrics for a given [videoId], when
  /// available.
  ///
  /// Only IDs starting with the `MPLYt` prefix are considered valid lyrics
  /// pages. When no lyrics tab can be found, `null` is returned.
  Future<String?> getLyricsBrowseId(String videoId) async {
    if (videoId.isEmpty) return null;
    try {
      final payload = _client.basePayload();
      payload['videoId'] = videoId;
      final data = await _client.post('next', payload);
      final tabs = data['contents']
              ?['singleColumnMusicWatchNextResultsRenderer']?['tabbedRenderer']
          ?['watchNextTabbedResultsRenderer']?['tabs'];
      if (tabs is! List || tabs.length < 2) return null;
      final tab1 = tabs[1] as Map<String, dynamic>?;
      final endpoint = tab1?['tabRenderer']?['endpoint']?['browseEndpoint'];
      if (endpoint is! Map<String, dynamic>) return null;
      final browseId = endpoint['browseId'] as String?;
      if (browseId == null || !browseId.startsWith('MPLYt')) return null;
      return browseId;
    } catch (_) {
      return null;
    }
  }
}
