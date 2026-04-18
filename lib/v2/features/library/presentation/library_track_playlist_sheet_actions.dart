import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_detail_request.dart';
import 'package:tunify/v2/features/library/presentation/library_list_invalidation.dart';
import 'package:tunify/v2/features/library/presentation/providers/library_providers.dart';

/// Gateway orchestration + cache invalidation for track rows in the unified
/// library options sheet. Keeps this out of widgets per RULES.md (no business
/// logic in UI).
abstract final class LibraryTrackPlaylistSheetActions {
  LibraryTrackPlaylistSheetActions._();

  static Future<void> removeTrackFromUserPlaylist({
    required WidgetRef ref,
    required String playlistId,
    required String trackId,
    required LibraryItem detailsItem,
  }) async {
    final gw = ref.read(libraryWriteGatewayProvider);
    await gw.removeUserPlaylistTrack(
      playlistId: playlistId,
      trackId: trackId,
    );
    invalidateLibraryListCaches(ref);
    ref.invalidate(trackPlaylistMembershipsProvider(trackId.trim()));
    ref.invalidate(
      libraryDetailsProvider(LibraryDetailRequest(detailsItem)),
    );
  }

  static Future<void> addTrackToUserPlaylist({
    required WidgetRef ref,
    required String targetPlaylistId,
    required String videoId,
    required LibraryDetailsTrack track,
    required LibraryItem detailsItem,
  }) async {
    final gw = ref.read(libraryWriteGatewayProvider);
    await gw.addUserPlaylistTrack(
      playlistId: targetPlaylistId,
      trackId: videoId,
      title: track.title,
      subtitle: track.subtitle,
      artworkUrl: track.thumbUrl,
      durationMs: track.durationMs,
    );
    invalidateLibraryListCaches(ref);
    ref.invalidate(trackPlaylistMembershipsProvider(videoId.trim()));
    ref.invalidate(
      libraryDetailsProvider(LibraryDetailRequest(detailsItem)),
    );
  }

  /// User-owned playlists the current track can be copied into (excludes source).
  static Future<List<LibraryItem>> loadWritablePlaylistTargets({
    required WidgetRef ref,
    required String excludePlaylistId,
  }) async {
    final items = await ref.read(libraryRemoteItemsProvider(null).future);
    return items
        .where((i) => i.isUserOwnedPlaylist && i.id != excludePlaylistId)
        .toList(growable: false);
  }
}
