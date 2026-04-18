import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_detail_request.dart';
import 'package:tunify/v2/features/library/presentation/library_list_invalidation.dart';
import 'package:tunify/v2/features/library/presentation/providers/library_providers.dart';

/// Like / unlike via Tunify library (`playlist_kind = liked`). UI stays thin per RULES.md.
abstract final class LibraryTrackLikeSheetActions {
  LibraryTrackLikeSheetActions._();

  static Future<void> setTrackLiked({
    required WidgetRef ref,
    required bool liked,
    required String videoId,
    required LibraryDetailsTrack track,
    required LibraryItem likedPlaylistItem,
    required LibraryItem currentDetailsItem,
  }) async {
    final gw = ref.read(libraryWriteGatewayProvider);
    final vid = videoId.trim();
    if (liked) {
      await gw.addUserPlaylistTrack(
        playlistId: likedPlaylistItem.id,
        trackId: vid,
        title: track.title,
        subtitle: track.subtitle,
        artworkUrl: track.thumbUrl,
        durationMs: track.durationMs,
      );
    } else {
      await gw.removeUserPlaylistTrack(
        playlistId: likedPlaylistItem.id,
        trackId: vid,
      );
    }
    invalidateLibraryListCaches(ref);
    ref.invalidate(trackLikedStatusProvider(vid));
    ref.invalidate(trackPlaylistMembershipsProvider(vid));
    ref.invalidate(
      libraryDetailsProvider(LibraryDetailRequest(likedPlaylistItem)),
    );
    ref.invalidate(
      libraryDetailsProvider(LibraryDetailRequest(currentDetailsItem)),
    );
  }
}
