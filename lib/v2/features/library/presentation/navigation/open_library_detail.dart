import 'package:flutter/material.dart';
import 'package:tunify/v2/features/home/domain/entities/home_block.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/presentation/screens/library_details_screen.dart';
import 'package:tunify/v2/features/search/domain/entities/search_models.dart';

/// Home promo card backed by a real playlist browse id (e.g. `playlist_shelf_promo` / Charts).
bool homePromoIsBrowseBackedPlaylist(HomePodcastPromo data) {
  if (data.trackVideoIds.isNotEmpty) {
    return false;
  }
  final id = data.id.trim();
  if (id.startsWith('tunify_home_tracks:')) {
    return false;
  }
  return id.startsWith('VL') ||
      id.startsWith('OLAK5uy_') ||
      id.startsWith('RD');
}

void pushLibraryDetailFromHomeBrowsePlaylistPromo(
  BuildContext context,
  HomePodcastPromo data,
) {
  if (!homePromoIsBrowseBackedPlaylist(data)) {
    return;
  }
  final browseId = data.id.trim();
  pushLibraryDetailFromHomeCarousel(
    context,
    browseId: browseId,
    kind: LibraryItemKind.playlist,
    title: data.title,
    subtitle: data.showSubtitle,
    imageUrl:
        data.mosaicArtworkUrls.isNotEmpty ? data.mosaicArtworkUrls.first : null,
  );
}

/// Folded home `track_shelf_promo` — opens playlist-style detail without a YTM browse id.
void pushLibraryDetailFromHomeTrackShelfPromo(
  BuildContext context,
  HomePodcastPromo promo,
) {
  if (promo.trackVideoIds.isEmpty) {
    return;
  }
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => LibraryDetailsScreen(
        item: LibraryItem(
          id: promo.id,
          title: promo.title,
          subtitle: promo.showSubtitle,
          kind: LibraryItemKind.playlist,
          imageUrl: promo.mosaicArtworkUrls.isNotEmpty
              ? promo.mosaicArtworkUrls.first
              : null,
          creatorName: 'Tunify',
          isEphemeralHomeTrackShelf: true,
          homeTrackVideoIds: promo.trackVideoIds,
          homeTrackTitles: promo.trackTitles,
          homeTrackSubtitles: promo.trackSubtitles,
        ),
      ),
    ),
  );
}

void pushLibraryDetailFromSearch(
  BuildContext context,
  SearchResultItem result,
) {
  final kind = _libraryKindFromSearch(result.kind);
  if (kind == null) {
    return;
  }
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => LibraryDetailsScreen(
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

void pushLibraryDetailFromHomeSlimTile(
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
      builder: (_) => LibraryDetailsScreen(
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

void pushLibraryDetailFromHomeCarousel(
  BuildContext context, {
  required String browseId,
  required LibraryItemKind kind,
  required String title,
  required String subtitle,
  String? imageUrl,
}) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => LibraryDetailsScreen(
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
    SearchItemKind.podcast => LibraryItemKind.podcast,
    SearchItemKind.episode => LibraryItemKind.episode,
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
  if (trimmed.startsWith('MPRE')) {
    return LibraryItemKind.album;
  }
  if (trimmed.startsWith('OLAK5uy_') || trimmed.startsWith('VL')) {
    return LibraryItemKind.playlist;
  }
  return null;
}
