import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_detail_request.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_layout.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_strings.dart';
import 'package:tunify/v2/features/library/presentation/library_track_playlist_sheet_actions.dart';
import 'package:tunify/v2/features/library/presentation/library_track_like_sheet_actions.dart';
import 'package:tunify/v2/features/library/presentation/providers/library_providers.dart';
import 'package:tunify/v2/features/library/presentation/screens/library_create_item_screen.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_list_tile.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_collection_artwork.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_search_bar_with_sort.dart';

/// Bottom sheet to save a track to a playlist or liked songs.
/// Shows search bar, sort button, and list of playlists with toggle icons.
void showSaveTrackToPlaylistSheet({
  required BuildContext context,
  required WidgetRef ref,
  required LibraryDetailsTrack track,
  required LibraryItem sourceCollectionItem,
  String? excludePlaylistId,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.bottomSheetSurface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppBorderRadius.comfortable),
      ),
    ),
    builder: (_) => ProviderScope(
      overrides: [
        _saveTrackToPlaylistTrackProvider.overrideWithValue(track),
        _saveTrackToPlaylistSourceItemProvider.overrideWithValue(sourceCollectionItem),
        _saveTrackToPlaylistExcludeProvider.overrideWithValue(excludePlaylistId),
      ],
      child: const _SaveTrackToPlaylistSheet(),
    ),
  );
}

final _saveTrackToPlaylistTrackProvider = Provider<LibraryDetailsTrack>((ref) {
  throw UnimplementedError('Provider must be overridden');
});

final _saveTrackToPlaylistSourceItemProvider = Provider<LibraryItem>((ref) {
  throw UnimplementedError('Provider must be overridden');
});

final _saveTrackToPlaylistExcludeProvider = Provider<String?>((ref) {
  throw UnimplementedError('Provider must be overridden');
});

class _SaveTrackToPlaylistSheet extends ConsumerStatefulWidget {
  const _SaveTrackToPlaylistSheet();

  @override
  ConsumerState<_SaveTrackToPlaylistSheet> createState() => _SaveTrackToPlaylistSheetState();
}

class _SaveTrackToPlaylistSheetState extends ConsumerState<_SaveTrackToPlaylistSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _searchQuery.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchQuery.dispose();
    super.dispose();
  }

  String get _videoId => ref.read(_saveTrackToPlaylistTrackProvider).videoId.trim();

  bool get _hasVideoId => _videoId.isNotEmpty;

  Future<void> _onNewPlaylistTap() async {
    if (!_hasVideoId) return;

    final created = await Navigator.of(context).push<LibraryItem?>(
      MaterialPageRoute<LibraryItem?>(
        builder: (_) => const LibraryCreateItemScreen(isPlaylist: true),
      ),
    );

    if (!mounted) return;
    if (created != null) {
      // Auto-add track to newly created playlist
      final track = ref.read(_saveTrackToPlaylistTrackProvider);
      final sourceItem = ref.read(_saveTrackToPlaylistSourceItemProvider);
      try {
        await LibraryTrackPlaylistSheetActions.addTrackToUserPlaylist(
          ref: ref,
          targetPlaylistId: created.id,
          videoId: _videoId,
          track: track,
          detailsItem: sourceItem,
        );
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(LibraryStrings.trackAddedToPlaylist)),
          );
        }
      } on Object catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(LibraryStrings.trackAddToPlaylistFailed)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(_saveTrackToPlaylistTrackProvider);
    final excludeId = ref.watch(_saveTrackToPlaylistExcludeProvider);
    final itemsAsync = ref.watch(_saveTrackToPlaylistItemsProvider(excludeId));
    final membershipsAsync = ref.watch(trackPlaylistMembershipsProvider(_videoId));
    final likedAsync = ref.watch(trackLikedStatusProvider(_videoId));

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: LibraryLayout.sheetHandleWidth,
            height: LibraryLayout.sheetHandleHeight,
            decoration: BoxDecoration(
              color: AppColors.silver.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(LibraryLayout.sheetHandleRadius),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                Text(
                  LibraryStrings.saveInSheetTitle,
                  style: AppTextStyles.bodyBold,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _onNewPlaylistTap,
                  child: Text(
                    LibraryStrings.saveInNewPlaylist,
                    style: AppTextStyles.smallBold.copyWith(
                      color: AppColors.brandGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: LibrarySearchBarWithSort(
              hint: LibraryStrings.saveInFindPlaylistHint,
              showSortButton: true,
              onTapSort: () {
                // TODO: Show sort options sheet
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Flexible(
            child: itemsAsync.when(
              loading: () {
                // Use Skeletonizer to auto-generate from actual UI
                final dummyPlaylists = List.generate(
                  4,
                  (i) => LibraryItem(
                    id: 'skeleton-$i',
                    kind: LibraryItemKind.playlist,
                    title: 'Loading Playlist',
                    subtitle: 'Loading',
                    imageUrl: null,
                    isPinned: false,
                  ),
                );
                
                return SizedBox(
                  height: 200,
                  child: Skeletonizer(
                    enabled: true,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        return LibraryListTile(
                          item: dummyPlaylists[index],
                          onTap: () {},
                        );
                      },
                    ),
                  ),
                );
              },
              error: (e, _) => SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'Could not load playlists',
                    style: AppTextStyles.caption,
                  ),
                ),
              ),
              data: (items) => ValueListenableBuilder<String>(
                valueListenable: _searchQuery,
                builder: (context, query, _) {
                  final filtered = _filterItems(items, query);
                  if (filtered.isEmpty) {
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: Text(
                          'No playlists found',
                          style: AppTextStyles.caption,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _PlaylistTile(
                        item: item,
                        track: track,
                        membershipsAsync: membershipsAsync,
                        likedAsync: likedAsync,
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _NewPlaylistListItem(onTap: _onNewPlaylistTap),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  List<LibraryItem> _filterItems(List<LibraryItem> items, String query) {
    if (query.isEmpty) return items;
    final lowerQuery = query.toLowerCase();
    return items.where((item) => item.title.toLowerCase().contains(lowerQuery)).toList();
  }
}

/// Provider for playlist items (user playlists from root + folders + liked songs).
final _saveTrackToPlaylistItemsProvider = FutureProvider.autoDispose.family<List<LibraryItem>, String?>((ref, excludeId) async {
  final rootItems = await ref.read(libraryRemoteItemsProvider(null).future);
  final likedItem = ref.read(likedPlaylistLibraryItemProvider);
  
  final Set<String> seenIds = {};
  final List<LibraryItem> result = [];
  
  // Add liked songs if available
  if (likedItem != null && !seenIds.contains(likedItem.id)) {
    result.add(likedItem);
    seenIds.add(likedItem.id);
  }
  
  // Add root-level user-owned playlists
  for (final item in rootItems) {
    if (item.isUserOwnedPlaylist && 
        (excludeId == null || item.id != excludeId) &&
        !seenIds.contains(item.id)) {
      result.add(item);
      seenIds.add(item.id);
    }
  }
  
  // Add user-owned playlists from folders
  for (final item in rootItems) {
    if (item.kind == LibraryItemKind.folder) {
      try {
        final folderItems = await ref.read(libraryRemoteItemsProvider(item.id).future);
        for (final folderItem in folderItems) {
          if (folderItem.isUserOwnedPlaylist && 
              (excludeId == null || folderItem.id != excludeId) &&
              !seenIds.contains(folderItem.id)) {
            result.add(folderItem);
            seenIds.add(folderItem.id);
          }
        }
      } catch (_) {
        // If folder fetch fails, skip it
      }
    }
  }
  
  return result;
});

class _PlaylistTile extends ConsumerWidget {
  const _PlaylistTile({
    required this.item,
    required this.track,
    required this.membershipsAsync,
    required this.likedAsync,
  });

  final LibraryItem item;
  final LibraryDetailsTrack track;
  final AsyncValue<Set<String>> membershipsAsync;
  final AsyncValue<bool> likedAsync;

  bool get _isLikedSongs => item.systemArtwork == SystemArtworkType.likedSongs;

  bool get _isFolder => item.kind == LibraryItemKind.folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLiked = _isLikedSongs 
        ? likedAsync.maybeWhen(data: (v) => v, orElse: () => false)
        : membershipsAsync.maybeWhen(data: (set) => set.contains(item.id), orElse: () => false);

    return InkWell(
      onTap: () => _onToggle(ref, context, isLiked),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            // Artwork or folder icon
            _buildArtwork(),
            const SizedBox(width: AppSpacing.lg),
            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _buildSubtitle(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption,
              ),
                ],
              ),
            ),
            // Plus/Check toggle icon
            _buildToggleIcon(context, ref, isLiked),
          ],
        ),
      ),
    );
  }

  Widget _buildArtwork() {
    if (_isFolder) {
      return Container(
        width: LibraryLayout.listThumbSize,
        height: LibraryLayout.listThumbSize,
        decoration: BoxDecoration(
          color: AppColors.midDark,
          borderRadius: BorderRadius.circular(AppBorderRadius.subtle),
        ),
        child: Icon(
          Icons.folder,
          color: AppColors.silver,
          size: 24,
        ),
      );
    }
    return LibraryCollectionArtwork(
      item: item,
      size: LibraryLayout.listThumbSize,
      borderRadius: AppBorderRadius.subtle,
    );
  }

  String _buildSubtitle() {
    if (_isFolder) {
      // For folders, we'd need to count playlists inside
      // For now, show a placeholder
      return 'Folder';
    }
    if (_isLikedSongs) {
      return 'Liked songs';
    }
    return item.subtitle;
  }

  Widget _buildToggleIcon(BuildContext context, WidgetRef ref, bool isAdded) {
    return GestureDetector(
      onTap: () => _onToggle(ref, context, isAdded),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isAdded ? AppColors.brandGreen : AppColors.transparent,
          border: Border.all(
            color: isAdded ? AppColors.brandGreen : AppColors.silver,
            width: 1.5,
          ),
        ),
        child: Icon(
          isAdded ? Icons.check : Icons.add,
          color: isAdded ? AppColors.nearBlack : AppColors.silver,
          size: 18,
        ),
      ),
    );
  }

  Future<void> _onToggle(WidgetRef ref, BuildContext context, bool isAdded) async {
    final videoId = track.videoId.trim();
    if (videoId.isEmpty) return;

    try {
      if (_isLikedSongs) {
        // Toggle liked status
        final likedItem = ref.read(likedPlaylistLibraryItemProvider);
        if (likedItem == null) return;
        
        final sourceItem = ref.read(_saveTrackToPlaylistSourceItemProvider);
        await LibraryTrackLikeSheetActions.setTrackLiked(
          ref: ref,
          liked: !isAdded,
          videoId: videoId,
          track: track,
          likedPlaylistItem: likedItem,
          currentDetailsItem: sourceItem,
        );
      } else {
        // Toggle playlist membership
        final sourceItem = ref.read(_saveTrackToPlaylistSourceItemProvider);
        final excludeId = ref.read(_saveTrackToPlaylistExcludeProvider);
        if (isAdded) {
          await LibraryTrackPlaylistSheetActions.removeTrackFromUserPlaylist(
            ref: ref,
            playlistId: item.id,
            trackId: videoId,
            detailsItem: sourceItem,
          );
        } else {
          await LibraryTrackPlaylistSheetActions.addTrackToUserPlaylist(
            ref: ref,
            targetPlaylistId: item.id,
            videoId: videoId,
            track: track,
            detailsItem: sourceItem,
          );
        }
        // Invalidate the items provider to refresh the list
        ref.invalidate(_saveTrackToPlaylistItemsProvider(excludeId));
        // Invalidate the target playlist details to update subtitle/track count
        ref.invalidate(libraryDetailsProvider(LibraryDetailRequest(item)));
      }
    } on Object catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(LibraryStrings.saveInToggleFailed)),
        );
      }
    }
  }
}

class _NewPlaylistListItem extends StatelessWidget {
  const _NewPlaylistListItem({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Container(
              width: LibraryLayout.listThumbSize,
              height: LibraryLayout.listThumbSize,
              decoration: BoxDecoration(
                color: AppColors.midDark,
                borderRadius: BorderRadius.circular(AppBorderRadius.subtle),
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.silver,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                LibraryStrings.saveInNewPlaylist,
                style: AppTextStyles.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
