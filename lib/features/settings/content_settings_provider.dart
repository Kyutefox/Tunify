import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tunify/data/models/song.dart';
import 'package:tunify_database/tunify_database.dart';
import 'package:tunify_logger/tunify_logger.dart';

import 'package:tunify/data/repositories/database_repository.dart';

/// Shared base for boolean settings backed by SQLite + SharedPreferences.
/// Subclasses supply [settingKey] and their public setter name.
abstract class _BoolSettingNotifier extends Notifier<bool> {
  _BoolSettingNotifier({required this.settingKey});

  final String settingKey;

  @override
  bool build() {
    load();
    return true;
  }

  Future<void> load() async {
    try {
      final repo = ref.read(databaseRepositoryProvider);
      final local = await repo.getSetting(settingKey);
      if (local != null) {
        state = local == 'true';
        await (await SharedPreferences.getInstance())
            .setBool(settingKey, state);
      }
    } catch (e) {
      logWarning('ContentSettings: load $settingKey failed: $e',
          tag: 'ContentSettings');
    }
  }

  Future<void> _persist(bool value) async {
    if (state == value) return;
    state = value;
    try {
      await (await SharedPreferences.getInstance()).setBool(settingKey, value);
      await ref
          .read(databaseRepositoryProvider)
          .savePlaybackSetting(settingKey, value);
    } catch (e) {
      logWarning('ContentSettings: persist $settingKey failed: $e',
          tag: 'ContentSettings');
    }
  }

  Future<void> onAuthChanged() async => load();
}

/// Whether explicit tracks are visible in search results, quick picks, and the queue.
final showExplicitContentProvider =
    NotifierProvider<ShowExplicitContentNotifier, bool>(
  ShowExplicitContentNotifier.new,
);

/// Persists the explicit-content filter setting to SQLite + SharedPreferences,
/// syncing with Supabase via [DatabaseRepository] on auth changes.
class ShowExplicitContentNotifier extends _BoolSettingNotifier {
  ShowExplicitContentNotifier()
      : super(settingKey: PlaybackSettingKeys.showExplicitContent);

  Future<void> setShowExplicit(bool value) => _persist(value);
}

/// Filters [songs] based on the explicit-content setting.
/// Returns [songs] unmodified when [showExplicit] is true;
/// otherwise removes tracks where [Song.isExplicit] is true.
List<Song> filterByExplicitSetting(List<Song> songs, bool showExplicit) {
  if (showExplicit) return songs;
  return songs.where((s) => !s.isExplicit).toList();
}
