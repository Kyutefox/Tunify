import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/constants/podcast_promo_layout.dart';
import 'package:tunify/v2/core/utils/image_palette_extractor.dart';
import 'package:tunify/v2/core/widgets/cards/podcast_promo_card.dart';
import 'package:tunify/v2/features/home/domain/entities/home_block.dart';
import 'package:tunify/v2/features/home/presentation/constants/home_layout.dart';
import 'package:tunify/v2/features/library/data/library_collection_gateway.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/auth/presentation/providers/auth_providers.dart';
import 'package:tunify/v2/features/library/presentation/library_list_invalidation.dart';
import 'package:tunify/v2/features/library/presentation/navigation/open_library_detail.dart';
import 'package:tunify/v2/features/library/presentation/providers/library_collection_providers.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_item_options_sheet.dart';

/// Home feed wrapper for the shared [PodcastPromoCard].
///
/// Extracts a palette from the first available artwork URL and passes
/// the dominant color to the card background, matching the collection-detail
/// gradient behaviour. Falls back to the hash-derived color until ready.
class HomePodcastPromoView extends ConsumerStatefulWidget {
  const HomePodcastPromoView({
    super.key,
    required this.data,
  });

  final HomePodcastPromo data;

  @override
  ConsumerState<HomePodcastPromoView> createState() =>
      _HomePodcastPromoViewState();
}

class _HomePodcastPromoViewState extends ConsumerState<HomePodcastPromoView> {
  int? _resolvedBackgroundArgb;

  @override
  void initState() {
    super.initState();
    _extractPalette();
  }

  @override
  void didUpdateWidget(HomePodcastPromoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.id != widget.data.id ||
        oldWidget.data.mosaicArtworkUrls != widget.data.mosaicArtworkUrls) {
      _resolvedBackgroundArgb = null;
      _extractPalette();
    }
  }

  Future<void> _extractPalette() async {
    final imageUrl = widget.data.mosaicArtworkUrls.isNotEmpty
        ? widget.data.mosaicArtworkUrls.first
        : null;
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return;
    }
    final palette = await ImagePaletteExtractor.fromNetworkUrl(imageUrl);
    if (!mounted || palette == null) {
      return;
    }
    setState(() {
      _resolvedBackgroundArgb = palette.gradientTop.toARGB32();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final isFoldedTrackShelf = data.trackVideoIds.isNotEmpty;
    final isBrowsePlaylistPromo = homePromoIsBrowseBackedPlaylist(data);
    final useCompactPromo = isFoldedTrackShelf || isBrowsePlaylistPromo;
    final effectiveBackground = _resolvedBackgroundArgb ?? data.backgroundColor;

    // Only watch saved state for browse-backed playlist promos (has a browseId)
    final savedAsync = isBrowsePlaylistPromo
        ? ref.watch(libraryCollectionSavedProvider(
            (target: 'playlist', browseId: data.id.trim()),
          ))
        : const AsyncValue<bool>.data(false);
    final isSaved = savedAsync.value ?? false;

    void openDetail() {
      if (isBrowsePlaylistPromo) {
        pushLibraryDetailFromHomeBrowsePlaylistPromo(context, data);
        return;
      }
      if (isFoldedTrackShelf) {
        pushLibraryDetailFromHomeTrackShelfPromo(context, data);
      }
    }

    void tryToggleLibrary() async {
      if (!isBrowsePlaylistPromo) {
        return;
      }
      final browseId = data.id.trim();
      final target = 'playlist';
      final op = isSaved ? 'remove' : 'add';
      await _mutateLibraryCollection(
        context,
        ref,
        browseId: browseId,
        target: target,
        op: op,
        title: data.title,
        coverUrl: data.mosaicArtworkUrls.isNotEmpty
            ? data.mosaicArtworkUrls.first
            : null,
      );
    }

    final libraryItem = LibraryItem(
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
        onOpenDetail: useCompactPromo ? openDetail : null,
        onListenNow:
            useCompactPromo && !isFoldedTrackShelf ? openDetail : null,
        onPlay: isBrowsePlaylistPromo ? openDetail : null,
        onMore: useCompactPromo
            ? () => showLibraryItemOptionsSheet(context, libraryItem)
            : null,
        showAddToLibraryButton: !isFoldedTrackShelf,
        onAddToLibrary: isBrowsePlaylistPromo ? tryToggleLibrary : null,
      ),
    );
  }
}

Future<void> _mutateLibraryCollection(
  BuildContext context,
  WidgetRef ref, {
  required String browseId,
  required String target,
  required String op,
  required String title,
  String? coverUrl,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final gateway = LibraryCollectionGateway(
    api: ref.read(tunifyApiClientProvider),
  );
  final key = (target: target, browseId: browseId);
  try {
    await gateway.mutate(
      op: op,
      target: target,
      browseId: browseId,
      title: title,
      coverUrl: coverUrl,
    );
    ref.invalidate(libraryCollectionSavedProvider(key));
    invalidateLibraryListCaches(ref);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(op == 'add' ? 'Added to Your Library' : 'Removed from Your Library'),
      ),
    );
  } on Object catch (e) {
    messenger?.showSnackBar(
      SnackBar(content: Text('Could not save ($e)')),
    );
  }
}
