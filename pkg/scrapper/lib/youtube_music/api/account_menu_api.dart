import 'package:scrapper/youtube_music/client/yt_music_client.dart';

/// Lightweight wrapper around the YouTube Music `account_menu` endpoint.
///
/// This API surfaces information about the currently authenticated user
/// account using the configuration attached to the underlying [YTMusicClient].
class AccountMenuApi {
  final YTMusicClient _client;

  /// Creates a new [AccountMenuApi] bound to the provided [client].
  AccountMenuApi({required YTMusicClient client}) : _client = client;

  /// Fetches the raw `account_menu` InnerTube payload for the current user.
  ///
  /// The call uses the client's current [YTMusicClient.context] to construct
  /// the request body and returns the decoded JSON response as a map.
  Future<Map<String, dynamic>> fetchAccountMenu() async {
    final payload = {'context': _client.context()};
    return _client.post('account/account_menu', payload);
  }
}
