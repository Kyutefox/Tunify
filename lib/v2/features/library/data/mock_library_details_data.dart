import 'package:flutter/material.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';

abstract final class MockLibraryDetailsData {
  static bool _isStaticPlaylist(LibraryItem item) {
    return item.systemArtwork == SystemArtworkType.likedSongs ||
        item.systemArtwork == SystemArtworkType.yourEpisodes;
  }

  static const _baseTracks = <LibraryDetailsTrack>[
    LibraryDetailsTrack(
      title: 'One Of The Girls (with JENNIE, Lily-Rose Depp)',
      subtitle: '2,581,184,303',
    ),
    LibraryDetailsTrack(
      title: 'Starboy',
      subtitle: '4,481,500,397',
    ),
    LibraryDetailsTrack(
      title: 'Timeless (feat Playboi Carti)',
      subtitle: '1,483,110,828',
    ),
    LibraryDetailsTrack(
      title: 'Blinding Lights',
      subtitle: '4,120,289,931',
    ),
    LibraryDetailsTrack(
      title: 'The Hills',
      subtitle: '4,010,268,931',
    ),
  ];

  static LibraryDetailsModel fromItem(LibraryItem item) {
    if (_isStaticPlaylist(item)) {
      final liked = item.systemArtwork == SystemArtworkType.likedSongs;
      return LibraryDetailsModel(
        type: LibraryDetailsType.staticPlaylist,
        item: item,
        searchHint: liked ? 'Find in Liked Songs' : 'Find in Your Episodes',
        title: item.title,
        subtitlePrimary: liked ? '1 song' : '3 episodes',
        subtitleSecondary: '',
        statsLine: '',
        tracks: liked
            ? const [
                LibraryDetailsTrack(
                  title: 'Tumhe Apna Banane Ka',
                  subtitle:
                      'Armaan Malik, Neeti Mohan, Amaal Mallik, Rashmi Virag',
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

    if (item.kind == LibraryItemKind.artist) {
      return LibraryDetailsModel(
        type: LibraryDetailsType.artist,
        item: item,
        searchHint: '',
        title: item.title,
        subtitlePrimary: '116.2M monthly listeners',
        subtitleSecondary: 'Following',
        statsLine: '',
        tracks: _baseTracks,
        heroImageUrl:
            'https://i.scdn.co/image/ab6761610000e5eb1026c0f1f3f7ac6f9f8f6115',
        gradientTop: const Color(0xFF121212),
        artistTabs: const ['Music', 'Events', 'Merch'],
      );
    }

    return LibraryDetailsModel(
      type: LibraryDetailsType.playlist,
      item: item,
      searchHint: 'Find on this page',
      title: item.title.toUpperCase(),
      subtitlePrimary: item.creatorName ?? 'Tunify',
      subtitleSecondary: '8h 22min',
      statsLine: '5 songs • about 6 hr 20 min',
      tracks: const [
        LibraryDetailsTrack(
          title: 'Fortnight (feat. Post Malone)',
          subtitle: 'Taylor Swift, Post Malone',
        ),
        LibraryDetailsTrack(
          title: 'The Tortured Poets Department',
          subtitle: 'Taylor Swift',
        ),
      ],
      gradientTop: const Color(0xFF6589AE),
      chips: const ['Add', 'Edit', 'Sort', 'Name & details'],
    );
  }
}
