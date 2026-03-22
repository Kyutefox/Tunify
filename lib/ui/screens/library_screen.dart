import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cached_network_image/cached_network_image.dart';

import '../components/ui/components_ui.dart';
import '../../config/app_icons.dart';
import '../../models/library_album.dart';
import '../../models/library_artist.dart';
import '../../models/library_folder.dart';
import '../../models/library_playlist.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/library_provider.dart';
import '../../system/bridges/database_repository.dart';
import '../layout/shell_context.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
import '../theme/app_routes.dart';
import '../../shared/utils/string_utils.dart';
import 'library/create_library_item_screen.dart';
import 'library/library_playlist_screen.dart';
import 'library/library_playlists_section.dart';
import 'library/library_app_bar.dart';
import 'library/library_downloaded_content.dart';
import 'library/library_liked_songs_screen.dart';
import 'library/library_search_screen.dart';
import '../components/shared/adaptive_menu.dart';
import '../components/shared/create_library_options.dart';
import 'download_queue_sheet.dart';
import 'player/album_page.dart';
import 'player/artist_page.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  /// Drives the chip row.
  LibraryFilter? _filter;
  /// Drives the body content (kept in sync with _filter for smooth transitions).
  LibraryFilter? _contentFilter;
  DownloadedSource _downloadedSource = DownloadedSource.library;
  /// When non-null, section shows this folder's playlists with a back row instead of main list.
  String? _selectedFolderId;

  void _unfocus() => FocusManager.instance.primaryFocus?.unfocus();

  void _onFilterChanged(LibraryFilter? f) {
    setState(() {
      _filter = f;
      _contentFilter = f;
    });
  }

  /// Pulls latest data from Supabase into SQLite, then reloads library state.
  /// Only used when a user is logged in; pull-to-refresh is disabled for guests.
  Future<void> _onPullToRefresh() async {
    final bridge = ref.read(databaseBridgeProvider);
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await bridge.pullFromSupabase(user.id);
    if (mounted) {
      await ref.read(libraryProvider.notifier).load();
    }
  }

  /// Resolves folder by id; returns null if not found.
  LibraryFolder? _selectedFolder(List<LibraryFolder> folders) {
    if (_selectedFolderId == null) return null;
    try {
      return folders.firstWhere((f) => f.id == _selectedFolderId);
    } catch (_) {
      return null;
    }
  }

  /// Builds the main list entries (Liked Songs + folders + playlists) or playlists-only.
  List<LibrarySectionEntry> _buildSectionEntries({
    required bool includeLikedSongs,
    required List<LibraryFolder> folders,
    required List<LibraryPlaylist> rootPlaylists,
  }) {
    if (includeLikedSongs) {
      return [
        LikedSongsEntry(
          songCount: ref.watch(libraryLikedCountProvider),
          onTap: () {
            Navigator.of(context).push(
              appPageRoute<void>(
                builder: (_) => const LibraryLikedSongsScreen(),
              ),
            );
          },
        ),
        ...folders.map((f) => FolderEntry(f)),
        ...rootPlaylists.map((p) => PlaylistEntry(p)),
      ];
    }
    return [
      ...folders.map((f) => FolderEntry(f)),
      ...rootPlaylists.map((p) => PlaylistEntry(p)),
    ];
  }

  List<LibraryPlaylist> _sortedPlaylists(
    List<LibraryPlaylist> list,
    LibrarySortOrder sortOrder,
  ) {
    final copy = List<LibraryPlaylist>.from(list);
    switch (sortOrder) {
      case LibrarySortOrder.recent:
        copy.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case LibrarySortOrder.recentlyAdded:
        copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case LibrarySortOrder.alphabetical:
        copy.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }
    final pinned = copy.where((p) => p.isPinned).toList();
    final unpinned = copy.where((p) => !p.isPinned).toList();
    return [...pinned, ...unpinned];
  }

  @override
  Widget build(BuildContext context) {
    final sortOrder = ref.watch(libraryProvider.select((s) => s.sortOrder));
    final viewMode = ref.watch(libraryProvider.select((s) => s.viewMode));
    final playlists = ref.watch(libraryPlaylistsProvider);
    final folders = ref.watch(libraryFoldersProvider);
    final inFolderIds = folders.fold<Set<String>>(
      {},
      (set, f) => set..addAll(f.playlistIds),
    );
    final rootPlaylists =
        playlists.where((p) => !inFolderIds.contains(p.id)).toList();
    LibraryFolder? selectedFolder;
    if (_selectedFolderId != null) {
      final match = folders.where((f) => f.id == _selectedFolderId).toList();
      selectedFolder = match.isNotEmpty ? match.first : null;
    }

    final appBar = LibraryAppBar(
      asSliver: false,
      onSearchTap: () async {
        final folderId = await Navigator.of(context).push<String>(
          PageRouteBuilder<String>(
            pageBuilder: (_, __, ___) => const LibrarySearchScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 200),
          ),
        );
        if (mounted && folderId != null) {
          setState(() => _selectedFolderId = folderId);
        }
      },
      onDownloadQueueTap: () => showDownloadQueueSheet(context),
      onCreateTap: () => showCreateLibrarySheet(context, ref),
      selectedFilter: _filter,
      onFilterChanged: _onFilterChanged,
      downloadedSource: _filter == LibraryFilter.downloaded
          ? _downloadedSource
          : null,
      onDownloadedSourceChanged: _filter == LibraryFilter.downloaded
          ? (s) => setState(() => _downloadedSource = s)
          : null,
      sortOrder: sortOrder,
      viewMode: viewMode,
      onSortChanged: (order) =>
          ref.read(libraryProvider.notifier).setSortOrder(order),
      onViewModeChanged: (mode) =>
          ref.read(libraryProvider.notifier).setViewMode(mode),
      folderName: selectedFolder?.name.capitalized,
      onExitFolder: selectedFolder != null
          ? () => setState(() => _selectedFolderId = null)
          : null,
    );

    final isDesktop = ShellContext.isDesktopOf(context);

    // Key that changes whenever the displayed section changes.
    final contentKey = ValueKey('$_contentFilter-$_selectedFolderId');

    Widget buildScrollView(bool withRefresh) {
      final scrollView = CustomScrollView(
        key: contentKey,
        physics: withRefresh
            ? const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics())
            : const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          ..._buildContentSlivers(viewMode, sortOrder, rootPlaylists),
          const SliverToBoxAdapter(child: SizedBox(height: 160)),
        ],
      );
      if (withRefresh) {
        return RefreshIndicator(onRefresh: _onPullToRefresh, child: scrollView);
      }
      return scrollView;
    }

    final isLoggedIn = ref.watch(currentUserProvider) != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: GestureDetector(
          onTap: _unfocus,
          behavior: HitTestBehavior.translucent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isDesktop) appBar,
              if (!isDesktop) const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: _ContentSwitcher(
                  contentKey: contentKey,
                  child: buildScrollView(isLoggedIn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContentSlivers(
    LibraryViewMode viewMode,
    LibrarySortOrder sortOrder,
    List<LibraryPlaylist> rootPlaylists,
  ) {
    switch (_contentFilter) {
      case LibraryFilter.all:
      case null:
      case LibraryFilter.playlists:
        final folders = ref.watch(libraryFoldersProvider);
        final folder = _selectedFolder(folders);
        final List<LibrarySectionEntry> entries;
        if (folder != null) {
          final allPlaylists = ref.watch(libraryProvider).playlists;
          final idToPlaylist = {for (final p in allPlaylists) p.id: p};
          final folderPlaylists = folder.playlistIds
              .map((id) => idToPlaylist[id])
              .whereType<LibraryPlaylist>()
              .toList();
          entries = _sortedPlaylists(folderPlaylists, sortOrder)
              .map((p) => PlaylistEntry(p))
              .toList();
        } else {
          final isMainSection =
              _contentFilter == null || _contentFilter == LibraryFilter.all;
          entries = _buildSectionEntries(
            includeLikedSongs: isMainSection,
            folders: folders,
            rootPlaylists: rootPlaylists,
          );
        }
        final showCreateFirstPlaylistEmptyState = _contentFilter ==
                LibraryFilter.playlists &&
            // Empty main playlists view: we show "Create your first playlist".
            folders.isEmpty &&
            rootPlaylists.isEmpty;
        final disableEmptyFadeTransition = showCreateFirstPlaylistEmptyState &&
            entries.isEmpty;
        if (disableEmptyFadeTransition) {
          return [
            SliverFillRemaining(
              child: LibraryFilterPlaceholder(
                icon: AppIcons.playlist,
                message: 'Playlists you create will appear here',
              ),
            ),
          ];
        }

        return [
          SliverToBoxAdapter(
            child: LibraryPlaylistsSection(
              entries: entries,
              viewMode: viewMode,
              onPlaylistTap: _onPlaylistTap,
              onPlaylistOptions: _onPlaylistOptions,
              onFolderTap: _onFolderTap,
              onFolderOptions: _onFolderOptions,
              showCreateFirstPlaylistEmptyState: showCreateFirstPlaylistEmptyState,
              isFolderView: _selectedFolderId != null,
            ),
          ),
        ];
      case LibraryFilter.albums:
        final rawAlbums =
            ref.watch(libraryProvider.select((s) => s.followedAlbums));
        if (rawAlbums.isEmpty) {
          return [
            SliverFillRemaining(
              child: LibraryFilterPlaceholder(
                icon: AppIcons.album,
                message: 'Albums you save will appear here',
              ),
            ),
          ];
        }
        final sortedAlbums = _sortedFollowedAlbums(rawAlbums, sortOrder);
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: viewMode == LibraryViewMode.grid
                  ? _FollowedAlbumsGrid(albums: sortedAlbums)
                  : _FollowedAlbumsList(albums: sortedAlbums),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 160)),
        ];
      case LibraryFilter.artists:
        final rawArtists =
            ref.watch(libraryProvider.select((s) => s.followedArtists));
        if (rawArtists.isEmpty) {
          return [
            SliverFillRemaining(
              child: LibraryFilterPlaceholder(
                icon: AppIcons.artist,
                message: 'Artists you follow will appear here',
              ),
            ),
          ];
        }
        final sortedArtists = _sortedFollowedArtists(rawArtists, sortOrder);
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: viewMode == LibraryViewMode.grid
                  ? _FollowedArtistsGrid(artists: sortedArtists)
                  : _FollowedArtistsList(artists: sortedArtists),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 160)),
        ];
      case LibraryFilter.downloaded:
        return [
          LibraryDownloadedContent(
            isLibraryMode: _downloadedSource == DownloadedSource.library,
            viewMode: viewMode,
            sortOrder: sortOrder,
          ),
        ];
    }
  }

  List<LibraryArtist> _sortedFollowedArtists(
    List<LibraryArtist> list,
    LibrarySortOrder sortOrder,
  ) {
    final copy = List<LibraryArtist>.from(list);
    switch (sortOrder) {
      case LibrarySortOrder.alphabetical:
        copy.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case LibrarySortOrder.recent:
      case LibrarySortOrder.recentlyAdded:
        copy.sort((a, b) => b.followedAt.compareTo(a.followedAt));
    }
    return copy;
  }

  List<LibraryAlbum> _sortedFollowedAlbums(
    List<LibraryAlbum> list,
    LibrarySortOrder sortOrder,
  ) {
    final copy = List<LibraryAlbum>.from(list);
    switch (sortOrder) {
      case LibrarySortOrder.alphabetical:
        copy.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case LibrarySortOrder.recent:
      case LibrarySortOrder.recentlyAdded:
        copy.sort((a, b) => b.followedAt.compareTo(a.followedAt));
    }
    return copy;
  }

  void _onPlaylistTap(LibraryPlaylist playlist) {
    Navigator.of(context).push(
      appPageRoute<void>(
        builder: (_) => LibraryPlaylistScreen(playlistId: playlist.id),
      ),
    );
  }

  void _onFolderTap(LibraryFolder folder) {
    setState(() => _selectedFolderId = folder.id);
  }

  void _onFolderOptions(LibraryFolder folder, Rect? anchorRect) {
    _unfocus();
    showLibraryFolderOptionsSheet(context, ref, folder, anchorRect: anchorRect);
  }

  void _onPlaylistOptions(LibraryPlaylist playlist, Rect? anchorRect) {
    _unfocus();
    showLibraryPlaylistOptionsSheet(context, ref, playlist, anchorRect: anchorRect);
  }
}

// ─── Artists list & grid ──────────────────────────────────────────────────────

class _FollowedArtistsList extends ConsumerWidget {
  const _FollowedArtistsList({required this.artists});
  final List<LibraryArtist> artists;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: artists.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final artist = artists[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              appPageRoute<void>(
                builder: (_) => ArtistPage(
                  artistName: artist.name,
                  thumbnailUrl: artist.thumbnailUrl,
                  artistBrowseId: artist.browseId,
                ),
              ),
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: artist.thumbnailUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 52,
                        height: 52,
                        color: AppColors.surfaceLight,
                        child: AppIcon(icon: AppIcons.person, color: AppColors.textMuted, size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artist.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: AppFontSize.lg,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Artist',
                          style: TextStyle(color: AppColors.textMuted, fontSize: AppFontSize.md),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: AppIcon(icon: AppIcons.checkCircle, color: AppColors.primary, size: 22),
                    onPressed: () => ref.read(libraryProvider.notifier).toggleFollowArtist(artist),
                    iconSize: 22,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FollowedArtistsGrid extends ConsumerWidget {
  const _FollowedArtistsGrid({required this.artists});
  final List<LibraryArtist> artists;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            appPageRoute<void>(
              builder: (_) => ArtistPage(
                artistName: artist.name,
                thumbnailUrl: artist.thumbnailUrl,
                artistBrowseId: artist.browseId,
              ),
            ),
          ),
          onLongPress: () => ref.read(libraryProvider.notifier).toggleFollowArtist(artist),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: artist.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => AppIcon(
                        icon: AppIcons.person,
                        color: AppColors.textMuted,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                artist.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppFontSize.md,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const Text(
                'Artist',
                style: TextStyle(color: AppColors.textMuted, fontSize: AppFontSize.xs),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Albums list & grid ───────────────────────────────────────────────────────

class _FollowedAlbumsList extends ConsumerWidget {
  const _FollowedAlbumsList({required this.albums});
  final List<LibraryAlbum> albums;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: albums.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final album = albums[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              appPageRoute<void>(
                builder: (_) => AlbumPage(
                  songTitle: album.title,
                  artistName: album.artistName,
                  thumbnailUrl: album.thumbnailUrl,
                  albumBrowseId: album.browseId,
                  albumName: album.title,
                ),
              ),
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: CachedNetworkImage(
                      imageUrl: album.thumbnailUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 52,
                        height: 52,
                        color: AppColors.surfaceLight,
                        child: AppIcon(icon: AppIcons.album, color: AppColors.textMuted, size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          album.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: AppFontSize.lg,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          album.artistName,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: AppFontSize.md),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: AppIcon(icon: AppIcons.checkCircle, color: AppColors.primary, size: 22),
                    onPressed: () => ref.read(libraryProvider.notifier).toggleFollowAlbum(album),
                    iconSize: 22,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FollowedAlbumsGrid extends ConsumerWidget {
  const _FollowedAlbumsGrid({required this.albums});
  final List<LibraryAlbum> albums;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            appPageRoute<void>(
              builder: (_) => AlbumPage(
                songTitle: album.title,
                artistName: album.artistName,
                thumbnailUrl: album.thumbnailUrl,
                albumBrowseId: album.browseId,
                albumName: album.title,
              ),
            ),
          ),
          onLongPress: () => ref.read(libraryProvider.notifier).toggleFollowAlbum(album),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: CachedNetworkImage(
                      imageUrl: album.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => AppIcon(
                        icon: AppIcons.album,
                        color: AppColors.textMuted,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                album.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppFontSize.md,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                album.artistName,
                style: const TextStyle(color: AppColors.textMuted, fontSize: AppFontSize.xs),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Shared empty-state widget used by both mobile [LibraryScreen] and
/// desktop [DesktopSidebar] for playlists / albums / artists filters.
class LibraryFilterPlaceholder extends StatelessWidget {
  const LibraryFilterPlaceholder({
    super.key,
    required this.icon,
    required this.message,
  });

  final List<List<dynamic>> icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              icon: icon,
              color: AppColors.textMuted.withValues(alpha: 0.5),
              size: 64,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.9),
                fontSize: AppFontSize.lg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddToFolderSheet extends StatefulWidget {
  const _AddToFolderSheet({
    required this.folders,
    required this.playlistId,
    required this.scrollController,
    required this.onToggle,
  });

  final List<LibraryFolder> folders;
  final String playlistId;
  final ScrollController scrollController;
  final void Function(String folderId, bool add) onToggle;

  @override
  State<_AddToFolderSheet> createState() => _AddToFolderSheetState();
}

class _AddToFolderSheetState extends State<_AddToFolderSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LibraryFolder> get _filtered {
    if (_query.isEmpty) return widget.folders;
    return widget.folders
        .where((f) => f.name.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm),
        Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSheetHorizontalPadding),
                child: Row(
                  children: [
                    AppIcon(
                      icon: AppIcons.folder,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Text(
                      'Add to folder',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: AppFontSize.h3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${widget.folders.length}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: AppFontSize.base,
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSheetHorizontalPadding),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Row(
              children: [
                const SizedBox(width: AppSpacing.base),
                AppIcon(
                  icon: AppIcons.search,
                  color: AppColors.textMuted,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppInputField(
                    controller: _searchController,
                    hintText: 'Search folders',
                    style: InputFieldStyle.transparent,
                  ),
                ),
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: () => _searchController.clear(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      child: AppIcon(
                        icon: AppIcons.clear,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: AppSpacing.base),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: filtered.isEmpty
              ? Padding(
                  padding: EdgeInsets.only(
                    left: kSheetHorizontalPadding,
                    right: kSheetHorizontalPadding,
                    top: AppSpacing.xxl,
                    bottom: bottomPad + AppSpacing.xxl,
                  ),
                  child: EmptyListMessage(emptyLabel: 'folders', query: _query),
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  padding: EdgeInsets.only(
                    left: kSheetHorizontalPadding,
                    right: kSheetHorizontalPadding,
                    bottom: bottomPad + AppSpacing.xxl,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final f = filtered[i];
                    final hasPlaylist =
                        f.playlistIds.contains(widget.playlistId);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 8,
                      ),
                      leading: AppIcon(
                        icon: AppIcons.folder,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        f.name.capitalized,
                        style:
                            const TextStyle(color: AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        '${f.playlistCount} playlists',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: AppFontSize.sm),
                      ),
                      trailing: hasPlaylist
                          ? AppIcon(
                              icon: AppIcons.check,
                              color: AppColors.primary)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onToggle(f.id, !hasPlaylist);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Public sheet launchers — shared by LibraryScreen and DesktopSidebar ──────

/// Shows the playlist options sheet (pin, add to folder, delete).
/// Callable from any [ConsumerWidget] / [ConsumerState] that has a [WidgetRef].
void showLibraryPlaylistOptionsSheet(
  BuildContext context,
  WidgetRef ref,
  LibraryPlaylist playlist, {
  Rect? anchorRect,
}) {
  final isDesktop = defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  if (isDesktop) {
    final folders = ref.read(libraryFoldersProvider);
    final folderSubEntries = folders.map((f) {
      final alreadyIn = f.playlistIds.contains(playlist.id);
      return AppMenuEntry(
        icon: alreadyIn ? AppIcons.checkCircle : AppIcons.folder,
        label: f.name,
        color: alreadyIn ? AppColors.primary : null,
        onTap: () {
          if (alreadyIn) {
            ref.read(libraryProvider.notifier).removePlaylistFromFolder(f.id, playlist.id);
          } else {
            ref.read(libraryProvider.notifier).addPlaylistToFolder(f.id, playlist.id);
          }
        },
      );
    }).toList();

    showAdaptiveMenu(
      context,
      title: playlist.name,
      entries: [
        AppMenuEntry(
          icon: playlist.isPinned ? AppIcons.pinOff : AppIcons.pin,
          label: playlist.isPinned ? 'Unpin' : 'Pin to top',
          onTap: () => ref.read(libraryProvider.notifier).togglePlaylistPin(playlist.id),
        ),
        if (folders.isNotEmpty)
          AppMenuEntry(
            icon: AppIcons.folder,
            label: 'Add to folder',
            onTap: () {},
            subEntries: folderSubEntries,
          ),
        const AppMenuEntry.divider(),
        AppMenuEntry(
          icon: AppIcons.deleteOutline,
          label: 'Delete',
          color: AppColors.secondary,
          onTap: () async {
            final confirmed = await showConfirmDialog(
              context,
              title: 'Delete playlist?',
              message: '${playlist.name.capitalized} will be removed from your library.',
              confirmLabel: 'Delete',
            );
            if (confirmed) {
              await ref.read(libraryProvider.notifier).deletePlaylist(playlist.id);
            }
          },
        ),
      ],
      anchorRect: anchorRect,
      forceDesktop: true,
    );
    return;
  }

  showAppSheet(
    context,
    child: LibraryPlaylistSheet(
      playlist: playlist,
      onTogglePin: () {
        ref.read(libraryProvider.notifier).togglePlaylistPin(playlist.id);
      },
      onDelete: () async {
        final confirmed = await showConfirmDialog(
          context,
          title: 'Delete playlist?',
          message: '${playlist.name.capitalized} will be removed from your library.',
          confirmLabel: 'Delete',
        );
        if (confirmed) {
          await ref.read(libraryProvider.notifier).deletePlaylist(playlist.id);
        }
      },
      onAddToFolder: () async {
        final navigator = Navigator.of(context);
        await showAddToFolderSheet(context, ref, playlist.id);
        if (navigator.mounted) navigator.pop();
      },
    ),
  );
}

/// Shows the folder options sheet (pin, rename, delete).
void showLibraryFolderOptionsSheet(
  BuildContext context,
  WidgetRef ref,
  LibraryFolder folder, {
  Rect? anchorRect,
}) {
  final isDesktop = defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  if (isDesktop) {
    showAdaptiveMenu(
      context,
      title: folder.name,
      entries: [
        AppMenuEntry(
          icon: folder.isPinned ? AppIcons.pinOff : AppIcons.pin,
          label: folder.isPinned ? 'Unpin' : 'Pin to top',
          onTap: () => ref.read(libraryProvider.notifier).toggleFolderPin(folder.id),
        ),
        AppMenuEntry(
          icon: AppIcons.edit,
          label: 'Rename',
          onTap: () async {
            final newName = await showDialog<String>(
              context: context,
              builder: (_) => CreateLibraryItemScreen(
                mode: CreateLibraryItemMode.renameFolder,
                initialName: folder.name,
              ),
            );
            if (newName != null && newName.trim().isNotEmpty) {
              ref.read(libraryProvider.notifier).renameFolder(folder.id, newName.trim());
            }
          },
        ),
        const AppMenuEntry.divider(),
        AppMenuEntry(
          icon: AppIcons.deleteOutline,
          label: 'Delete',
          color: AppColors.secondary,
          onTap: () async {
            final confirmed = await showConfirmDialog(
              context,
              title: 'Delete folder?',
              message: '${folder.name.capitalized} will be removed. Playlists inside will not be deleted.',
              confirmLabel: 'Delete',
            );
            if (confirmed) {
              ref.read(libraryProvider.notifier).deleteFolder(folder.id);
            }
          },
        ),
      ],
      anchorRect: anchorRect,
      forceDesktop: true,
    );
    return;
  }

  showAppSheet(
    context,
    child: LibraryFolderSheet(
      folder: folder,
      onTogglePin: () {
        ref.read(libraryProvider.notifier).toggleFolderPin(folder.id);
      },
      onRename: () async {
        final navigator = Navigator.of(context);
        final newName = await navigator.push<String>(
          appPageRoute<String>(
            builder: (_) => CreateLibraryItemScreen(
              mode: CreateLibraryItemMode.renameFolder,
              initialName: folder.name,
            ),
          ),
        );
        if (navigator.mounted) navigator.pop();
        if (newName != null && newName.trim().isNotEmpty) {
          ref.read(libraryProvider.notifier).renameFolder(folder.id, newName.trim());
        }
      },
      onDelete: () async {
        final confirmed = await showConfirmDialog(
          context,
          title: 'Delete folder?',
          message: '${folder.name.capitalized} will be removed. Playlists inside will not be deleted.',
          confirmLabel: 'Delete',
        );
        if (confirmed) {
          ref.read(libraryProvider.notifier).deleteFolder(folder.id);
        }
      },
    ),
  );
}

/// Shows the add-to-folder picker sheet for a playlist.
Future<void> showAddToFolderSheet(
  BuildContext context,
  WidgetRef ref,
  String playlistId,
) async {
  final folders = ref.read(libraryFoldersProvider);
  if (folders.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create a folder from the menu first')),
    );
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AppDraggableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (scrollController) => _AddToFolderSheet(
        folders: folders,
        playlistId: playlistId,
        scrollController: scrollController,
        onToggle: (folderId, add) {
          if (add) {
            ref
                .read(libraryProvider.notifier)
                .addPlaylistToFolder(folderId, playlistId);
          } else {
            ref
                .read(libraryProvider.notifier)
                .removePlaylistFromFolder(folderId, playlistId);
          }
        },
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class LibraryPlaylistSheet extends StatelessWidget {
  const LibraryPlaylistSheet({
    super.key,
    required this.playlist,
    required this.onDelete,
    required this.onAddToFolder,
    required this.onTogglePin,
  });

  final LibraryPlaylist playlist;
  final VoidCallback onDelete;
  final VoidCallback onAddToFolder;
  final VoidCallback onTogglePin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSheetHorizontalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetOptionTile(
            icon: playlist.isPinned ? AppIcons.pinOff : AppIcons.pin,
            label: playlist.isPinned ? 'Unpin' : 'Pin to top',
            showChevron: false,
            onTap: () {
              Navigator.pop(context);
              onTogglePin();
            },
          ),
          SheetOptionTile(
            icon: AppIcons.folder,
            label: 'Add to folder',
            showChevron: false,
            onTap: () {
              onAddToFolder();
            },
          ),
          SheetOptionTile(
            icon: AppIcons.deleteOutline,
            label: 'Delete',
            iconColor: AppColors.secondary,
            labelColor: AppColors.secondary,
            showChevron: false,
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
        ],
      ),
    );
  }
}

class LibraryFolderSheet extends StatelessWidget {
  const LibraryFolderSheet({
    super.key,
    required this.folder,
    required this.onTogglePin,
    required this.onRename,
    required this.onDelete,
  });

  final LibraryFolder folder;
  final VoidCallback onTogglePin;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSheetHorizontalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetOptionTile(
            icon: folder.isPinned ? AppIcons.pinOff : AppIcons.pin,
            label: folder.isPinned ? 'Unpin' : 'Pin to top',
            showChevron: false,
            onTap: () {
              Navigator.pop(context);
              onTogglePin();
            },
          ),
          SheetOptionTile(
            icon: AppIcons.edit,
            label: 'Rename',
            showChevron: false,
            onTap: () => onRename(),
          ),
          SheetOptionTile(
            icon: AppIcons.deleteOutline,
            label: 'Delete',
            iconColor: AppColors.secondary,
            labelColor: AppColors.secondary,
            showChevron: false,
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
        ],
      ),
    );
  }
}

// ─── Content switcher ─────────────────────────────────────────────────────────
//
// Replicates appPageRoute behaviour in-place:
// - Outgoing child is removed from the tree immediately (frame 0) — no overlap.
// - Incoming child animates in with fade + micro-slide, 240ms easeOutCubic.
// - When the same key is passed again nothing happens.

class _ContentSwitcher extends StatefulWidget {
  const _ContentSwitcher({
    required this.contentKey,
    required this.child,
  });

  final ValueKey<String> contentKey;
  final Widget child;

  @override
  State<_ContentSwitcher> createState() => _ContentSwitcherState();
}

class _ContentSwitcherState extends State<_ContentSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  late Widget _current;
  late ValueKey<String> _currentKey;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      value: 1.0, // start fully visible
    );
    _setupAnimations();
    _current = widget.child;
    _currentKey = widget.contentKey;
  }

  void _setupAnimations() {
    final curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _fade = curved;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(curved);
  }

  @override
  void didUpdateWidget(_ContentSwitcher old) {
    super.didUpdateWidget(old);
    if (widget.contentKey != _currentKey) {
      // Key changed — swap child immediately and restart entrance animation.
      _current = widget.child;
      _currentKey = widget.contentKey;
      _ctrl.forward(from: 0.0);
    } else {
      // Same key but child widget may have changed (e.g. library data loaded).
      // Update silently without re-animating.
      _current = widget.child;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _current,
      ),
    );
  }
}
