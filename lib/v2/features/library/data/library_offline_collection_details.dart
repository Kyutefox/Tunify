import 'package:flutter/material.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_playlist_management_pills.dart';

/// Liked Songs / Your Episodes when there is no YouTube browse id.
LibraryDetailsModel libraryStaticSystemPlaylistDetails(LibraryItem item) {
  final liked = item.systemArtwork == SystemArtworkType.likedSongs;
  return LibraryDetailsModel(
    type: LibraryDetailsType.staticPlaylist,
    item: item,
    searchHint: liked ? 'Find in Liked Songs' : 'Find in Your Episodes',
    title: item.title,
    subtitlePrimary: liked ? '1 song' : '3 episodes',
    tracks: liked
        ? const [
            LibraryDetailsTrack(
              title: 'Tumhe Apna Banane Ka',
              subtitle: 'Armaan Malik, Neeti Mohan, Amaal Mallik, Rashmi Virag',
            ),
          ]
        : const [
            LibraryDetailsTrack(
              title: 'Episode 12 — The one about music',
              subtitle: 'Today · 42 min',
            ),
            LibraryDetailsTrack(
              title: 'Episode 11 — Behind the scenes',
              subtitle: 'Mar 2 · 38 min',
            ),
            LibraryDetailsTrack(
              title: 'Episode 10 — Listener mail',
              subtitle: 'Feb 18 · 51 min',
            ),
          ],
    gradientTop: liked ? const Color(0xFF2F3FAF) : const Color(0xFF0A3D32),
    showSortButton: true,
    showAddRow: true,
  );
}

/// User-owned or unknown local rows without [LibraryItem.ytmBrowseId].
LibraryDetailsModel libraryOfflinePlaylistShell(LibraryItem item) {
  return LibraryDetailsModel(
    type: LibraryDetailsType.playlist,
    item: item,
    searchHint: 'Find on this page',
    title: item.title,
    subtitlePrimary: item.creatorName ?? 'Playlist',
    collectionStatInfo: 'No tracks yet',
    typeSubtitle: 'Playlist',
    tracks: const [],
    heroImageUrl: item.imageUrl,
    gradientTop: const Color(0xFF6589AE),
    chips: libraryPlaylistShowsManagementPills(item)
        ? LibraryPlaylistManagementChips.ordered
        : const <String>[],
  );
}
