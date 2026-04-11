import 'package:flutter_riverpod/legacy.dart';

import 'package:tunify/v1/features/player/player_state_provider.dart';
import 'package:tunify/v1/data/repositories/database_repository.dart';
import 'package:tunify/v1/features/downloads/download_service.dart';

/// Provides the singleton [DownloadService], wired to [MusicStreamManager] for URL
/// resolution and to [DatabaseRepository] for persisting downloaded song IDs.
final downloadServiceProvider = ChangeNotifierProvider<DownloadService>((ref) {
  final streamManager = ref.watch(streamManagerProvider);
  final repo = ref.read(databaseRepositoryProvider);
  final service = DownloadService(
    streamManager: streamManager,
    onDownloadedIdsChanged: (ids) => repo.saveDownloadedSongIds(ids),
  );
  ref.onDispose(() => service.dispose());
  return service;
});

/// Returns true when [songId] has a completed download entry in [service].
bool isSongDownloaded(DownloadService service, String songId) {
  return service.isDownloaded(songId);
}
