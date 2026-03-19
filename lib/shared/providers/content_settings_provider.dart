import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/song.dart';
import 'package:tunify_database/tunify_database.dart';
import 'package:tunify_logger/tunify_logger.dart';


import '../../system/bridges/database_repository.dart';

/// Shared base for boolean settings backed by SQLite + SharedPreferences.
/// Subclasses supply [settingKey] and their public setter name.
abstract class _BoolSettingNotifier extends StateNotifier<bool> {
  _BoolSettingNotifier(Ref ref, {required this.settingKey})
      : _ref = ref,
        super(true);

  final Ref _ref;
  final String settingKey;

  Future<void> load() async {
    try {
      final repo = _ref.read(databaseRepositoryProvider);
      final local = await repo.getSetting(settingKey);
      if (local != null) {
        state = local == 'true';
        await (await SharedPreferences.getInstance()).setBool(settingKey, state);
      }
    } catch (e) {
      logWarning('ContentSettings: load $settingKey failed: $e', tag: 'ContentSettings');
    }
  }

  Future<void> _persist(bool value) async {
    if (state == value) return;
    state = value;
    try {
      await (await SharedPreferences.getInstance()).setBool(settingKey, value);
      await _ref.read(databaseRepositoryProvider).savePlaybackSetting(settingKey, value);
    } catch (e) {
      logWarning('ContentSettings: persist $settingKey failed: $e', tag: 'ContentSettings');
    }
  }

  Future<void> onAuthChanged() async => load();
}

/// Whether explicit tracks are visible in search results, quick picks, and the queue.
final showExplicitContentProvider =
    StateNotifierProvider<ShowExplicitContentNotifier, bool>(
  (ref) => ShowExplicitContentNotifier(ref)..load(),
);

/// Persists the explicit-content filter setting to SQLite + SharedPreferences,
/// syncing with Supabase via [DatabaseRepository] on auth changes.
class ShowExplicitContentNotifier extends _BoolSettingNotifier {
  ShowExplicitContentNotifier(super.ref)
      : super(settingKey: PlaybackSettingKeys.showExplicitContent);

  Future<void> setShowExplicit(bool value) => _persist(value);
}

/// Whether the home feed randomizes recommended track order rather than using
/// the default relevance ranking from YouTube Music.
final smartRecommendationShuffleProvider =
    StateNotifierProvider<SmartRecommendationShuffleNotifier, bool>(
  (ref) => SmartRecommendationShuffleNotifier(ref)..load(),
);

/// Persists the smart-recommendation shuffle setting to SQLite + SharedPreferences,
/// syncing with Supabase via [DatabaseRepository] on auth changes.
class SmartRecommendationShuffleNotifier extends _BoolSettingNotifier {
  SmartRecommendationShuffleNotifier(super.ref)
      : super(settingKey: PlaybackSettingKeys.smartRecommendationShuffle);

  Future<void> setSmartRecommendationShuffle(bool value) => _persist(value);
}

/// Filters [songs] based on the explicit-content setting.
/// Returns [songs] unmodified when [showExplicit] is true;
/// otherwise removes tracks where [Song.isExplicit] is true.
List<Song> filterByExplicitSetting(List<Song> songs, bool showExplicit) {
  if (showExplicit) return songs;
  return songs.where((s) => !s.isExplicit).toList();
}
