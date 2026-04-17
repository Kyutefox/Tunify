import 'package:flutter/material.dart';
import 'package:tunify/v2/features/home/domain/entities/home_block.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/presentation/screens/library_playlist_details_screen.dart';
import 'package:tunify/v2/features/search/domain/entities/search_models.dart';

void pushLibraryRemoteDetailFromSearch(
  BuildContext context,
  SearchResultItem result,
) {
  final kind = _libraryKindFromSearch(result.kind);
  if (kind == null) {
    return;
  }
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => LibraryPlaylistDetailsScreen(
        item: LibraryItem(
          id: result.id,
          title: result.title,
          subtitle: result.subtitle,
          kind: kind,
          imageUrl: result.imageUrl,
          ytmBrowseId: result.id,
        ),
      ),
    ),
  );
}

void pushLibraryRemoteDetailFromHomeSlimTile(
  BuildContext context,
  HomeSlimTile tile, {
  required String subtitle,
}) {
  final kind = _libraryKindForHomeShelf(tile.shelfKind, tile.id);
  if (kind == null) {
    return;
  }
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => LibraryPlaylistDetailsScreen(
        item: LibraryItem(
          id: tile.id,
          title: tile.title,
          subtitle: subtitle,
          kind: kind,
          imageUrl: tile.artworkUrl,
          ytmBrowseId: tile.id,
        ),
      ),
    ),
  );
}

void pushLibraryRemoteDetailFromHomeCarousel(
  BuildContext context, {
  required String browseId,
  required LibraryItemKind kind,
  required String title,
  required String subtitle,
  String? imageUrl,
}) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => LibraryPlaylistDetailsScreen(
        item: LibraryItem(
          id: browseId,
          title: title,
          subtitle: subtitle,
          kind: kind,
          imageUrl: imageUrl,
          ytmBrowseId: browseId,
        ),
      ),
    ),
  );
}

LibraryItemKind? _libraryKindFromSearch(SearchItemKind kind) {
  return switch (kind) {
    SearchItemKind.artist => LibraryItemKind.artist,
    SearchItemKind.album => LibraryItemKind.album,
    SearchItemKind.playlist => LibraryItemKind.playlist,
    _ => null,
  };
}

LibraryItemKind? _libraryKindForHomeShelf(String? shelfKind, String browseId) {
  final trimmed = browseId.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (shelfKind == 'track' ||
      shelfKind == 'podcast' ||
      shelfKind == 'episode') {
    return null;
  }
  final fromKind = switch (shelfKind) {
    'artist' => LibraryItemKind.artist,
    'album' => LibraryItemKind.album,
    'playlist' => LibraryItemKind.playlist,
    _ => null,
  };
  if (fromKind != null) {
    return fromKind;
  }
  if (trimmed.startsWith('UC')) {
    return LibraryItemKind.artist;
  }
  if (trimmed.startsWith('MPRE') || trimmed.startsWith('OLAK5uy_')) {
    return LibraryItemKind.album;
  }
  if (trimmed.startsWith('VL')) {
    return LibraryItemKind.playlist;
  }
  return null;
}
