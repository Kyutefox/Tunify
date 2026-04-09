import 'package:tunify_source_youtube_music/youtube_music/api/account_menu_api.dart';
import 'package:tunify_source_youtube_music/youtube_music/api/browse_api.dart';
import 'package:tunify_source_youtube_music/youtube_music/api/next_api.dart';
import 'package:tunify_source_youtube_music/youtube_music/api/player_api.dart';
import 'package:tunify_source_youtube_music/youtube_music/api/search_api.dart';
import 'package:tunify_source_youtube_music/youtube_music/auth/yt_music_auth.dart';
import 'package:tunify_source_youtube_music/youtube_music/client/yt_music_client.dart';
import 'package:tunify_source_youtube_music/youtube_music/services/visitor_data_fetcher.dart';

/// High-level facade for the YouTube Music InnerTube API.
///
/// This provides typed access to browse, search, player and next queue
/// operations without exposing low-level HTTP details.
class YoutubeMusic {
  final YTMusicClient client;
  final AccountMenuApi accountMenu;
  final BrowseApi browse;
  final NextApi next;
  final SearchApi search;
  final PlayerApi player;

  /// Current VISITOR_DATA token associated with this client session.
  String? get visitorData => client.visitorData;

  /// Creates a `YoutubeMusic` instance using pre-fetched configuration.
  ///
  /// Use this when you already have `visitorData`, `apiKey`, `clientVersion`
  /// and optional cookies and auth headers.
  factory YoutubeMusic({
    String? visitorData,
    String? apiKey,
    String? clientVersion,
    String? sessionCookies,
    String? gl,
    String? hl,
    YTMusicAuth? auth,
    void Function(String?)? onVisitorDataReceived,
  }) {
    final c = YTMusicClient(
      visitorData: visitorData,
      apiKey: apiKey,
      clientVersion: clientVersion,
      sessionCookies: sessionCookies,
      gl: gl,
      hl: hl,
      auth: auth,
      onVisitorDataReceived: onVisitorDataReceived,
    );
    return YoutubeMusic._(
      client: c,
      accountMenu: AccountMenuApi(client: c),
      browse: BrowseApi(client: c),
      next: NextApi(client: c),
      search: SearchApi(client: c),
      player: PlayerApi(client: c),
    );
  }

  /// Creates and initialises a `YoutubeMusic` instance by fetching
  /// configuration from the YouTube Music web client.
  ///
  /// This performs a one-time HTML fetch via [VisitorDataFetcher] to obtain
  /// live `visitorData`, `apiKey`, `clientVersion`, cookies and locales.
  static Future<YoutubeMusic> init({
    YTMusicAuth? auth,
    void Function(String?)? onVisitorDataReceived,
  }) async {
    final swData = await VisitorDataFetcher.fetch();
    return YoutubeMusic(
      visitorData: swData.visitorData,
      apiKey: swData.apiKey,
      clientVersion: swData.clientVersion,
      sessionCookies: swData.sessionCookies,
      gl: swData.gl,
      hl: swData.hl,
      auth: auth,
      onVisitorDataReceived: onVisitorDataReceived,
    );
  }

  YoutubeMusic._({
    required this.client,
    required this.accountMenu,
    required this.browse,
    required this.next,
    required this.search,
    required this.player,
  });

  /// Reports periodic playback watch-time events to the YouTube stats endpoint.
  ///
  /// This is a convenience wrapper around [PlayerApi.reportWatchtime] that
  /// forwards the current [client] configuration (visitor data, cookies and
  /// client version). [atrUrl] and [cpn] come from the `playbackTracking`
  /// block of a player response and [playbackSeconds] indicates the elapsed
  /// watch time in seconds.
  Future<void> reportPlaybackWatchtime(
    String atrUrl,
    String cpn,
    int playbackSeconds, {
    int? lengthSeconds,
  }) =>
      PlayerApi.reportWatchtime(atrUrl, cpn, playbackSeconds,
          visitorData: client.visitorData,
          sessionCookies: client.sessionCookies,
          clientVersion: client.clientVersion,
          lengthSeconds: lengthSeconds);

  /// Reports the start of playback to the YouTube stats endpoint.
  ///
  /// This wraps [PlayerApi.reportPlaybackStart] and forwards current session
  /// configuration so the resulting GET matches real browser traffic as
  /// closely as possible.
  Future<void> reportPlaybackStart(String videostatsPlaybackUrl, String cpn) =>
      PlayerApi.reportPlaybackStart(videostatsPlaybackUrl, cpn,
          visitorData: client.visitorData,
          sessionCookies: client.sessionCookies,
          clientVersion: client.clientVersion);

  /// Reports player tracking events (`ptracking`) to YouTube.
  ///
  /// This wraps [PlayerApi.reportPtracking] and attaches the current
  /// [client.visitorData] and [client.sessionCookies].
  Future<void> reportPtracking(String ptrackingUrl, String cpn) =>
      PlayerApi.reportPtracking(ptrackingUrl, cpn,
          visitorData: client.visitorData,
          sessionCookies: client.sessionCookies);
}
