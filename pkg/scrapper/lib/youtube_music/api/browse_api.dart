import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:scrapper/models/related_feed.dart';
import 'package:scrapper/models/track.dart';
import 'package:scrapper/youtube_music/client/yt_music_client.dart';
import 'package:scrapper/youtube_music/formatters/browse_formatter.dart';

/// Wrapper around the YouTube Music `browse` endpoint.
class BrowseApi {
  final YTMusicClient _client;

  /// Creates a new [BrowseApi] bound to the provided [client].
  BrowseApi({required YTMusicClient client}) : _client = client;

  /// Fetches the personalised YouTube Music home feed.
  ///
  /// The [maxTracks], [maxPlaylists], [maxArtists] and [maxMoodItems] parameters cap how many
  /// items of each type are included in the returned [RelatedHomeFeed].
  ///
  /// This method follows section list continuations (when present) so that all
  /// shelves from the home page are included, not just the first batch.
  Future<RelatedHomeFeed> fetchHomeFeed({
    int maxTracks = 30,
    int maxPlaylists = 12,
    int maxArtists = 12,
    int maxMoodItems = 100,
  }) async {
    try {
      // Initial home browse call.
      final first = await _client.post('browse', {
        'context': _client.context(),
        'browseId': 'FEmusic_home',
      });

      var aggregate = BrowseFormatter.parseRelatedFeed(
        first,
        maxTracks: maxTracks,
        maxPlaylists: maxPlaylists,
        maxArtists: maxArtists,
        maxMoodItems: maxMoodItems,
      );

      // Follow sectionListRenderer continuations for additional shelves.
      var token = _extractHomeContinuationToken(first);
      int rounds = 0;
      const maxRounds = 3;

      while (token != null && token.isNotEmpty && rounds < maxRounds) {
        rounds++;
        final payload = _client.basePayload();
        payload['continuation'] = token;
        final data = await _client.post('browse', payload);
        final part = BrowseFormatter.parseRelatedFeed(
          data,
          maxTracks: maxTracks,
          maxPlaylists: maxPlaylists,
          maxArtists: maxArtists,
          maxMoodItems: maxMoodItems,
        );

        aggregate = RelatedHomeFeed(
          trackShelves: [
            ...aggregate.trackShelves,
            ...part.trackShelves,
          ],
          playlistShelves: [
            ...aggregate.playlistShelves,
            ...part.playlistShelves,
          ],
          artistShelves: [
            ...aggregate.artistShelves,
            ...part.artistShelves,
          ],
          shelves: [
            ...aggregate.shelves,
            ...part.shelves,
          ],
          moodItems: [
            ...aggregate.moodItems,
            ...part.moodItems,
          ],
        );

        token = _extractHomeContinuationToken(data);
      }

      return aggregate;
    } catch (e) {
      return const RelatedHomeFeed();
    }
  }

  /// Extracts the continuation token for the main home section list, when present.
  ///
  /// Handles both the initial `contents.sectionListRenderer` shape and the
  /// continuation `continuationContents.sectionListContinuation` variant.
  String? _extractHomeContinuationToken(Map<String, dynamic> data) {
    try {
      final contents = data['contents']?['singleColumnBrowseResultsRenderer']
          ?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer'];
      final conts = contents?['continuations'] as List<dynamic>?;
      if (conts != null && conts.isNotEmpty) {
        final nextData =
            conts.first['nextContinuationData'] as Map<String, dynamic>?;
        final token = nextData?['continuation'] as String?;
        if (token != null && token.isNotEmpty) return token;
      }
    } catch (_) {}

    try {
      final sectionCont = data['continuationContents']
          ?['sectionListContinuation'] as Map<String, dynamic>?;
      final conts = sectionCont?['continuations'] as List<dynamic>?;
      if (conts != null && conts.isNotEmpty) {
        final nextData =
            conts.first['nextContinuationData'] as Map<String, dynamic>?;
        final token = nextData?['continuation'] as String?;
        if (token != null && token.isNotEmpty) return token;
      }
    } catch (_) {}

    return null;
  }

  /// Fetches the non-personalised "Explore" home feed.
  ///
  /// This uses the static `FEmusic_explore` browse ID and returns a
  /// [RelatedHomeFeed] independent of the current user session.
  Future<RelatedHomeFeed> fetchExploreFeed() async {
    try {
      final exploreData = await _client.post('browse', {
        'context': _client.context(),
        'browseId': 'FEmusic_explore',
      });

      return BrowseFormatter.parseRelatedFeed(exploreData, maxMoodItems: 100);
    } catch (e) {
      return const RelatedHomeFeed();
    }
  }

  /// Fetches the top charts feed from YouTube Music.
  ///
  /// Uses the static `FEmusic_charts` browse ID with a global filter param.
  /// Returns song/artist/album chart sections as a [RelatedHomeFeed].
  Future<RelatedHomeFeed> fetchChartsPage() async {
    try {
      final data = await _client.post('browse', {
        'context': _client.context(),
        'browseId': 'FEmusic_charts',
        'params': 'ggMGCgQIgAQ%3D',
      });
      return BrowseFormatter.parseRelatedFeed(data,
          maxTracks: 25, maxPlaylists: 12, maxArtists: 12);
    } catch (_) {
      return const RelatedHomeFeed();
    }
  }

  /// Fetches the full moods and genres list from YouTube Music.
  ///
  /// This uses the `FEmusic_moods_and_genres` browse ID which returns all
  /// available mood and genre categories.
  Future<RelatedHomeFeed> fetchMoodsAndGenresFeed() async {
    try {
      final data = await _client.post('browse', {
        'context': _client.context(),
        'browseId': 'FEmusic_moods_and_genres',
      });

      return BrowseFormatter.parseRelatedFeed(data, maxMoodItems: 200);
    } catch (e) {
      return const RelatedHomeFeed();
    }
  }

  /// Fetches detailed content for a specific mood or activity shelf.
  ///
  /// The [browseId] and optional [params] are taken from mood chips or
  /// navigation buttons in other browse responses and are passed through to
  /// the `browse` endpoint unchanged.
  Future<MoodDetailResult> fetchMoodDetail(
    String browseId, {
    String? params,
  }) async {
    try {
      final payload = <String, dynamic>{
        'context': _client.context(),
        'browseId': browseId,
      };
      if (params != null && params.isNotEmpty) {
        payload['params'] = params;
      }
      final data = await _client.post('browse', payload);
      return BrowseFormatter.parseMoodDetailResponse(data);
    } catch (e) {
      return const MoodDetailResult();
    }
  }

  /// Fetches a single page of tracks from a playlist or album browse page.
  ///
  /// Returns the tracks from that one page and the continuation token for
  /// the next page (if any). Use this for manual/incremental pagination
  /// (e.g. podcasts where the user triggers "load more").
  ///
  /// The [browseId] corresponds to a playlist or album page and [params]
  /// carries additional server‑side filters. The number of returned [Track]s
  /// per page is capped by [maxTracks].
  Future<({List<Track> tracks, String? continuationToken})> fetchPlaylistOrAlbumWithContinuation(
    String browseId, {
    String? params,
    String? continuationToken,
    int maxTracks = 500,
  }) async {
    try {
      final payload = <String, dynamic>{
        'context': _client.context(),
      };
      
      if (continuationToken != null && continuationToken.isNotEmpty) {
        payload['continuation'] = continuationToken;
      } else {
        payload['browseId'] = browseId;
        if (params != null && params.isNotEmpty) {
          payload['params'] = params;
        }
      }
      
      final data = await _client.post('browse', payload);
      final tracks = BrowseFormatter.extractTracksFromBrowseData(data, maxResults: maxTracks);
      final nextToken = BrowseFormatter.extractBrowseContinuationToken(data);
      return (tracks: tracks, continuationToken: nextToken);
    } catch (e) {
      return (tracks: <Track>[], continuationToken: null);
    }
  }

  /// Fetches ALL tracks from a playlist, album, or artist page by automatically
  /// following every continuation token until exhausted.
  ///
  /// YouTube Music returns ~100 tracks per page. This method keeps fetching
  /// continuation pages until no more tokens are returned, giving you the full
  /// content regardless of size. [maxTracks] acts as an absolute safety cap
  /// (defaults to 5000) to prevent unbounded loops on pathological responses.
  Future<List<Track>> fetchPlaylistOrAlbum(
    String browseId, {
    String? params,
    int maxTracks = 5000,
  }) async {
    final allTracks = <Track>[];
    final seenIds = <String>{};

    try {
      // Fetch the first page.
      final firstPayload = <String, dynamic>{
        'context': _client.context(),
        'browseId': browseId,
      };
      if (params != null && params.isNotEmpty) {
        firstPayload['params'] = params;
      }
      final firstData = await _client.post('browse', firstPayload);
      final firstTracks = BrowseFormatter.extractTracksFromBrowseData(
        firstData,
        maxResults: maxTracks,
      );
      for (final t in firstTracks) {
        if (seenIds.add(t.id)) allTracks.add(t);
      }
      String? nextToken = BrowseFormatter.extractBrowseContinuationToken(firstData);

      // Follow every continuation page until there are no more tokens or we hit
      // the safety cap.
      while (nextToken != null && nextToken.isNotEmpty && allTracks.length < maxTracks) {
        try {
          final contPayload = <String, dynamic>{
            'context': _client.context(),
            'continuation': nextToken,
          };
          final contData = await _client.post('browse', contPayload);
          final contTracks = BrowseFormatter.extractTracksFromBrowseData(
            contData,
            maxResults: maxTracks - allTracks.length,
          );
          // If a continuation page comes back empty, stop to avoid infinite loops.
          if (contTracks.isEmpty) break;
          for (final t in contTracks) {
            if (seenIds.add(t.id)) allTracks.add(t);
          }
          nextToken = BrowseFormatter.extractBrowseContinuationToken(contData);
        } catch (_) {
          // Stop pagination on any error mid-loop but keep what we have so far.
          break;
        }
      }
    } catch (_) {
      // Return whatever we collected before the failure.
    }

    return allTracks;
  }

  /// Fetches related/recommended content for a given browse ID.
  ///
  /// For **artists** pass the artist channel ID directly — browsing it returns
  /// the full artist page including all shelves.
  ///
  /// For **albums and playlists** the caller must first resolve the related
  /// browse ID via the `next` endpoint (`tabs[2]`) and pass it as
  /// [relatedBrowseId]. If [relatedBrowseId] is provided it is used instead of
  /// [browseId].
  Future<RelatedHomeFeed> fetchRelatedFeed(
    String browseId, {
    String? relatedBrowseId,
  }) async {
    final id = relatedBrowseId ?? browseId;
    try {
      final data = await _client.post('browse', {
        'context': _client.context(),
        'browseId': id,
      });
      return BrowseFormatter.parseRelatedFeed(
        data,
        maxTracks: 20,
        maxPlaylists: 20,
        maxArtists: 20,
      );
    } catch (_) {
      return const RelatedHomeFeed();
    }
  }

  /// Fetches content from a podcast show page and extracts videos as episodes.
  ///
  /// Podcast shows (browseIds starting with MPED) don't have structured episode lists
  /// like playlists. This method browses the show page and extracts any videos found
  /// as "episodes" for playback.
  Future<List<Track>> fetchPodcastShowContent(
    String browseId, {
    int maxTracks = 50,
  }) async {
    try {
      final payload = <String, dynamic>{
        'context': _client.context(),
        'browseId': browseId,
      };
      final data = await _client.post('browse', payload);
      return BrowseFormatter.extractTracksFromBrowseData(data,
          maxResults: maxTracks);
    } catch (e) {
      return [];
    }
  }

  /// Fetches lyrics payload for a track using a lyrics browse ID.
  ///
  /// Only browse IDs starting with the `MPLYt` prefix are considered valid
  /// lyrics pages. When the ID is invalid or an error occurs, `null` is
  /// returned.
  static const _androidClientVersion = '7.27.52';

  Future<Map<String, dynamic>?> fetchLyrics(String browseId) async {
    if (browseId.isEmpty || !browseId.startsWith('MPLYt')) return null;
    // Try Android Music client first — it returns timed (synced) lyrics.
    final timed = await _fetchLyricsWithAndroidClient(browseId);
    if (timed != null) return timed;
    // Fall back to web client for plain (unsynced) lyrics.
    try {
      final data = await _client.post('browse', {
        'context': _client.context(),
        'browseId': browseId,
      });
      return _parseLyricsResponse(data);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchLyricsWithAndroidClient(
    String browseId, {
    int retryCount = 0,
  }) async {
    try {
      final uri = Uri.parse(
          'https://music.youtube.com/youtubei/v1/browse?prettyPrint=false');
      final body = jsonEncode({
        'context': {
          'client': {
            'clientName': 'ANDROID_MUSIC',
            'clientVersion': _androidClientVersion,
            'androidSdkVersion': 30,
            'hl': 'en',
            'gl': 'US',
          }
        },
        'browseId': browseId,
      });
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent':
              'com.google.android.apps.youtube.music/$_androidClientVersion'
                  ' (Linux; U; Android 11; en_US) gzip',
          'X-YouTube-Client-Name': '21',
          'X-YouTube-Client-Version': _androidClientVersion,
        },
        body: body,
      );
      if (response.statusCode != 200) {
        // Retry once on transient server errors (5xx) or rate-limiting (429).
        final isTransient =
            response.statusCode == 429 || response.statusCode >= 500;
        if (isTransient && retryCount == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 600));
          return _fetchLyricsWithAndroidClient(browseId, retryCount: 1);
        }
        return null;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseAndroidLyricsResponse(data);
    } catch (_) {
      // Retry once on network-level failures (socket timeout, etc.).
      if (retryCount == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        return _fetchLyricsWithAndroidClient(browseId, retryCount: 1);
      }
      return null;
    }
  }

  static Map<String, dynamic>? _parseAndroidLyricsResponse(
      Map<String, dynamic> data) {
    try {
      final lyricsData = data['contents']?['elementRenderer']?['newElement']
              ?['type']?['componentType']?['model']?['timedLyricsModel']
          ?['lyricsData'] as Map<String, dynamic>?;
      if (lyricsData == null) return null;

      final rawEntries = lyricsData['timedLyricsData'] as List<dynamic>?;
      if (rawEntries == null || rawEntries.isEmpty) return null;

      final lines = <Map<String, dynamic>>[];
      String fullText = '';
      for (final entry in rawEntries) {
        if (entry is! Map<String, dynamic>) continue;
        final text = entry['lyricLine']?.toString() ?? '';
        final rawMs = entry['cueRange']?['startTimeMilliseconds'];
        final startMs =
            rawMs is int ? rawMs : int.tryParse(rawMs?.toString() ?? '') ?? 0;
        lines.add({'text': text, 'startTimeMs': startMs});
        if (fullText.isNotEmpty) fullText += '\n';
        fullText += text;
      }

      final source = lyricsData['sourceMessage'] as String?;
      return {
        'fullText': fullText,
        'source': source,
        'isSynced': true,
        'lines': lines,
      };
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? _parseLyricsResponse(Map<String, dynamic> data) {
    try {
      final contents = data['contents']?['sectionListRenderer']?['contents'];
      if (contents is! List || contents.isEmpty) return null;

      for (final section in contents) {
        if (section is! Map<String, dynamic>) continue;
        final timed = section['musicTimedLyricsRenderer'];
        if (timed is Map<String, dynamic>) {
          final timedData = timed['timedLyricsData'] as List<dynamic>?;
          if (timedData != null && timedData.isNotEmpty) {
            final lines = <Map<String, dynamic>>[];
            String fullText = '';
            for (final entry in timedData) {
              if (entry is! Map<String, dynamic>) continue;
              final text = entry['lyric'] as String? ?? '';
              final rawMs =
                  entry['startTimeMilliseconds'] ?? entry['startTimeMillis'];
              final startMs = rawMs is int
                  ? rawMs
                  : int.tryParse(rawMs?.toString() ?? '') ?? 0;
              lines.add({'text': text, 'startTimeMs': startMs});
              if (fullText.isNotEmpty) fullText += '\n';
              fullText += text;
            }
            final source = timed['sourceMessage'] as String?;
            return {
              'fullText': fullText,
              'source': source,
              'isSynced': true,
              'lines': lines,
            };
          }
        }
        final shelf = section['musicDescriptionShelfRenderer'];
        if (shelf is Map<String, dynamic>) {
          final desc = shelf['description'];
          String? lyricsStr;
          if (desc is Map<String, dynamic>) {
            final runs = desc['runs'] as List<dynamic>?;
            if (runs != null) {
              lyricsStr = runs
                  .whereType<Map<String, dynamic>>()
                  .map((r) => r['text'] as String? ?? '')
                  .join('');
            } else {
              lyricsStr = desc['simpleText'] as String?;
            }
          }
          if (lyricsStr != null && lyricsStr.isNotEmpty) {
            final runs = shelf['header']?['runs'] as List<dynamic>?;
            String? source;
            if (runs != null && runs.isNotEmpty) {
              final first = runs.first as Map<String, dynamic>?;
              source = first?['text'] as String?;
            }
            final lineTexts = lyricsStr
                .split('\n')
                .where((s) => s.trim().isNotEmpty)
                .toList();
            final lines = lineTexts.isEmpty
                ? <Map<String, dynamic>>[
                    {'text': lyricsStr, 'startTimeMs': null}
                  ]
                : lineTexts
                    .map((t) => {'text': t, 'startTimeMs': null})
                    .toList();
            return {
              'fullText': lyricsStr,
              'source': source,
              'isSynced': false,
              'lines': lines,
            };
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
