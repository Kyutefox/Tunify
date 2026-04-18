import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/errors/failures.dart';
import 'package:tunify/v2/core/utils/image_palette_extractor.dart';
import 'package:tunify/v2/core/utils/logger.dart';
import 'package:tunify/v2/features/auth/presentation/providers/auth_providers.dart';
import 'package:tunify/v2/features/library/data/library_browse_details_repository_impl.dart';
import 'package:tunify/v2/features/library/data/library_list_gateway.dart';
import 'package:tunify/v2/features/library/data/library_write_gateway.dart';
import 'package:tunify/v2/features/library/data/library_ephemeral_home_track_shelf_details.dart';
import 'package:tunify/v2/features/library/data/library_offline_collection_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_detail_palette_source.dart';
import 'package:tunify/v2/features/library/domain/library_detail_request.dart';
import 'package:tunify/v2/features/library/domain/library_items_query.dart';
import 'package:tunify/v2/features/library/domain/repositories/library_browse_details_repository.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_strings.dart';

/// Immutable view-state for the library screen.
@immutable
class LibraryViewState {
  const LibraryViewState({
    this.filter = LibraryFilter.all,
    this.playlistSubFilter = LibraryPlaylistSubFilter.none,
    this.viewMode = LibraryViewMode.list,
    this.sortMode = LibrarySortMode.recents,
  });

  final LibraryFilter filter;
  final LibraryPlaylistSubFilter playlistSubFilter;
  final LibraryViewMode viewMode;
  final LibrarySortMode sortMode;

  LibraryViewState copyWith({
    LibraryFilter? filter,
    LibraryPlaylistSubFilter? playlistSubFilter,
    LibraryViewMode? viewMode,
    LibrarySortMode? sortMode,
  }) {
    return LibraryViewState(
      filter: filter ?? this.filter,
      playlistSubFilter: playlistSubFilter ?? this.playlistSubFilter,
      viewMode: viewMode ?? this.viewMode,
      sortMode: sortMode ?? this.sortMode,
    );
  }
}

/// Business logic for library filtering, sorting, and view toggling.
class LibraryController extends Notifier<LibraryViewState> {
  @override
  LibraryViewState build() => const LibraryViewState();

  void setFilter(LibraryFilter filter) {
    if (state.filter == filter) {
      state = state.copyWith(
        filter: LibraryFilter.all,
        playlistSubFilter: LibraryPlaylistSubFilter.none,
      );
      return;
    }
    state = state.copyWith(
      filter: filter,
      playlistSubFilter: LibraryPlaylistSubFilter.none,
    );
  }

  void clearFilter() {
    state = state.copyWith(
      filter: LibraryFilter.all,
      playlistSubFilter: LibraryPlaylistSubFilter.none,
    );
  }

  void setPlaylistSubFilter(LibraryPlaylistSubFilter sub) {
    if (sub == state.playlistSubFilter) {
      state = state.copyWith(playlistSubFilter: LibraryPlaylistSubFilter.none);
      return;
    }
    state = state.copyWith(playlistSubFilter: sub);
  }

  void toggleViewMode() {
    final next = state.viewMode == LibraryViewMode.list
        ? LibraryViewMode.grid
        : LibraryViewMode.list;
    state = state.copyWith(viewMode: next);
  }

  void setSortMode(LibrarySortMode mode) {
    state = state.copyWith(sortMode: mode);
  }
}

final libraryControllerProvider =
    NotifierProvider<LibraryController, LibraryViewState>(
  LibraryController.new,
);

final libraryListGatewayProvider = Provider<LibraryListGateway>((ref) {
  return LibraryListGateway(api: ref.watch(tunifyApiClientProvider));
});

final libraryWriteGatewayProvider = Provider<LibraryWriteGateway>((ref) {
  return LibraryWriteGateway(api: ref.watch(tunifyApiClientProvider));
});

/// Raw rows from `GET /v1/library/playlists` (`folderId` null = root with folders).
final libraryRemoteItemsProvider =
    FutureProvider.autoDispose.family<List<LibraryItem>, String?>((ref, folderId) async {
  return ref.watch(libraryListGatewayProvider).fetchLibraryItems(folderId: folderId);
});

/// Filtered + sorted library items for the current UI state and optional folder scope.
final libraryItemsAsyncProvider =
    Provider.family<AsyncValue<List<LibraryItem>>, String?>((ref, folderId) {
  final remote = ref.watch(libraryRemoteItemsProvider(folderId));
  final viewState = ref.watch(libraryControllerProvider);
  return remote.whenData((items) {
    if (folderId != null && folderId.trim().isNotEmpty) {
      return LibraryItemsQuery.applyFolderContents(
        items: items,
        sortMode: viewState.sortMode,
      );
    }
    return LibraryItemsQuery.apply(
      items: items,
      filter: viewState.filter,
      playlistSubFilter: viewState.playlistSubFilter,
      sortMode: viewState.sortMode,
    );
  });
});

/// Tunify browse-backed collection details.
final libraryBrowseDetailsRepositoryProvider =
    Provider<LibraryBrowseDetailsRepository>((ref) {
  return LibraryBrowseDetailsRepositoryImpl(
    api: ref.watch(tunifyApiClientProvider),
  );
});

Future<LibraryDetailsModel> _libraryDetailsWithResolvedPalette(
  LibraryDetailsModel details,
  LibraryItem item,
) async {
  try {
    final url = libraryDetailPaletteSourceUrl(item: item, details: details);
    if (url == null) {
      return details;
    }
    final palette = await ImagePaletteExtractor.fromNetworkUrl(url);
    if (palette == null) {
      return details;
    }
    return details.withBackgroundPalette(
      gradientTop: palette.gradientTop,
      backgroundGradientMid: palette.gradientMid,
    );
  } on Object catch (e, st) {
    Logger.error(
      'Palette resolution failed; using default gradient',
      tag: 'LibraryDetails',
      error: e,
      stackTrace: st,
    );
    return details;
  }
}

bool _isStaticSystemPlaylist(LibraryItem item) {
  return item.systemArtwork == SystemArtworkType.likedSongs ||
      item.systemArtwork == SystemArtworkType.yourEpisodes;
}

/// Remote browse details, static system playlists, or offline shells.
final libraryDetailsProvider = FutureProvider.autoDispose
    .family<LibraryDetailsModel, LibraryDetailRequest>((ref, request) async {
  final item = request.item;
  final browseId = item.ytmBrowseId?.trim();
  final LibraryDetailsModel details;
  if (item.isEphemeralHomeTrackShelf && item.homeTrackVideoIds.isNotEmpty) {
    details = libraryEphemeralHomeTrackShelfDetails(item);
  } else if (browseId != null && browseId.isNotEmpty) {
    try {
      details = await ref
          .read(libraryBrowseDetailsRepositoryProvider)
          .loadDetails(item);
    } on Object catch (e, st) {
      Logger.error(
        'Library browse failed',
        tag: 'LibraryDetails',
        error: e,
        stackTrace: st,
      );
      throw NetworkFailure(LibraryStrings.collectionDetailsLoadError);
    }
  } else if (_isStaticSystemPlaylist(item)) {
    details = libraryStaticSystemPlaylistDetails(item);
  } else {
    details = libraryOfflinePlaylistShell(item);
  }

  return _libraryDetailsWithResolvedPalette(details, item);
});
