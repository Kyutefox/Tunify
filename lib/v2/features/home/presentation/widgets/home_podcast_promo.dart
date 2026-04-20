import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/constants/podcast_promo_layout.dart';
import 'package:tunify/v2/core/utils/image_palette_extractor.dart';
import 'package:tunify/v2/core/widgets/cards/podcast_promo_card.dart';
import 'package:tunify/v2/features/home/domain/entities/home_block.dart';
import 'package:tunify/v2/features/home/presentation/constants/home_layout.dart';
import 'package:tunify/v2/features/library/presentation/navigation/open_library_detail.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/presentation/providers/library_collection_providers.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_item_options_sheet.dart';

/// Checks if a podcast promo is backed by a browse ID (can be added to library).
bool homePromoIsBrowseBackedPlaylist(HomePodcastPromo data) {
  return data.id.trim().isNotEmpty;
}

/// Navigate to library detail for a browse-backed playlist promo.
void pushLibraryDetailFromHomeBrowsePlaylistPromo(
  BuildContext context,
  HomePodcastPromo data,
) {
  pushLibraryDetailFromHomeCarousel(
    context,
    browseId: data.id,
    kind: LibraryItemKind.playlist,
    title: data.title,
    subtitle: data.showSubtitle.isNotEmpty ? 'Playlist' : '',
    imageUrl: (data.mosaicArtworkUrls.isNotEmpty)
        ? data.mosaicArtworkUrls.first
        : null,
  );
}

/// Navigate to library detail for a track shelf promo.
void pushLibraryDetailFromHomeTrackShelfPromo(
  BuildContext context,
  HomePodcastPromo data,
) {
  pushLibraryDetailFromHomeCarousel(
    context,
    browseId: data.id,
    kind: LibraryItemKind.playlist,
    title: data.title,
    subtitle: 'Track shelf',
    imageUrl: data.mosaicArtworkUrls.isNotEmpty
        ? data.mosaicArtworkUrls.first
        : null,
  );
}

/// Home feed wrapper for the shared [PodcastPromoCard].
///
/// Uses Riverpod providers for palette extraction and saved state,
/// following Clean Architecture principles.
class HomePodcastPromoView extends ConsumerWidget {
  const HomePodcastPromoView({
    super.key,
    required this.data,
  });

  final HomePodcastPromo data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFoldedTrackShelf = data.trackVideoIds.isNotEmpty;
    final isBrowsePlaylistPromo = homePromoIsBrowseBackedPlaylist(data);
    final useCompactPromo = isFoldedTrackShelf || isBrowsePlaylistPromo;

    // Watch palette from first artwork URL (Riverpod provider)
    final imageUrl = data.mosaicArtworkUrls.isNotEmpty
        ? data.mosaicArtworkUrls.first
        : '';
    final paletteArgb = ref.watch(imagePaletteArgbProvider(imageUrl));
    final effectiveBackground = paletteArgb ?? data.backgroundColor;

    // Watch saved state for browse-backed playlist promos (has a browseId)
    final savedAsync = isBrowsePlaylistPromo
        ? ref.watch(libraryCollectionSavedProvider(
            (target: 'playlist', browseId: data.id.trim()),
          ))
        : const AsyncValue<bool>.data(false);
    final isSaved = savedAsync.value ?? false;

    return _PodcastPromoContent(
      data: data,
      effectiveBackground: effectiveBackground,
      isSaved: isSaved,
      isFoldedTrackShelf: isFoldedTrackShelf,
      isBrowsePlaylistPromo: isBrowsePlaylistPromo,
      useCompactPromo: useCompactPromo,
      ref: ref,
    );
  }
}

/// Extracted content widget to keep build method small and focused.
class _PodcastPromoContent extends ConsumerWidget {
  const _PodcastPromoContent({
    required this.data,
    required this.effectiveBackground,
    required this.isSaved,
    required this.isFoldedTrackShelf,
    required this.isBrowsePlaylistPromo,
    required this.useCompactPromo,
    required this.ref,
  });

  final HomePodcastPromo data;
  final int effectiveBackground;
  final bool isSaved;
  final bool isFoldedTrackShelf;
  final bool isBrowsePlaylistPromo;
  final bool useCompactPromo;
  final WidgetRef ref;

  LibraryItem get _libraryItem => LibraryItem(
        id: isBrowsePlaylistPromo ? data.id.trim() : data.id,
        title: data.title,
        subtitle: data.showSubtitle,
        kind: LibraryItemKind.playlist,
        imageUrl:
            data.mosaicArtworkUrls.isNotEmpty ? data.mosaicArtworkUrls.first : null,
        creatorName: isFoldedTrackShelf ? 'Tunify' : data.creatorName,
        ytmBrowseId: isBrowsePlaylistPromo ? data.id.trim() : null,
        isEphemeralHomeTrackShelf: isFoldedTrackShelf,
        homeTrackVideoIds: isFoldedTrackShelf ? data.trackVideoIds : const [],
        homeTrackTitles: isFoldedTrackShelf ? data.trackTitles : const [],
        homeTrackSubtitles: isFoldedTrackShelf ? data.trackSubtitles : const [],
      );

  void _openDetail(BuildContext context) {
    if (isBrowsePlaylistPromo) {
      pushLibraryDetailFromHomeBrowsePlaylistPromo(context, data);
      return;
    }
    if (isFoldedTrackShelf) {
      pushLibraryDetailFromHomeTrackShelfPromo(context, data);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        HomeLayout.shelfTrailingAfterContent,
      ),
      child: PodcastPromoCard(
        title: data.title,
        showSubtitle: data.showSubtitle,
        episodeDescription: data.episodeDescription,
        mockCoverArgbColors: data.coverColors,
        backgroundArgb: effectiveBackground,
        mosaicArtworkUrls: data.mosaicArtworkUrls,
        compactPlaylistStyle: useCompactPromo,
        isSaved: isSaved,
        listenNowLabel:
            isFoldedTrackShelf ? 'Preview playlist' : 'Listen now',
        coverWidth: useCompactPromo
            ? PodcastPromoLayout.trackShelfCoverSize
            : null,
        coverHeight: useCompactPromo
            ? PodcastPromoLayout.trackShelfCoverSize
            : null,
        onOpenDetail: useCompactPromo ? () => _openDetail(context) : null,
        onListenNow:
            useCompactPromo && !isFoldedTrackShelf
                ? () => _openDetail(context)
                : null,
        onPlay: isBrowsePlaylistPromo ? () => _openDetail(context) : null,
        onMore: useCompactPromo
            ? () => showLibraryItemOptionsSheet(context, _libraryItem)
            : null,
        showAddToLibraryButton: !isFoldedTrackShelf,
        onAddToLibrary: null,
      ),
    );
  }
}
