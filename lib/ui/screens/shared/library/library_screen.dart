import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:tunify/ui/widgets/common/sheet.dart';
import 'package:tunify/ui/widgets/common/confirm_dialog.dart';
import 'package:tunify/ui/widgets/common/input_field.dart';
import 'package:tunify/ui/widgets/common/empty_list_message.dart';
import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/library_album.dart';
import 'package:tunify/data/models/library_artist.dart';
import 'package:tunify/data/models/library_folder.dart';
import 'package:tunify/data/models/library_playlist.dart';
import 'package:tunify/data/models/playlist.dart';
import 'package:tunify/features/auth/auth_provider.dart';
import 'package:tunify/features/library/library_provider.dart';
import 'package:tunify/features/podcast/podcast_provider.dart';
import 'package:tunify/data/repositories/database_repository.dart';
import 'package:tunify/ui/shell/shell_context.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_routes.dart';
import 'package:tunify/core/utils/string_utils.dart';
import 'package:tunify/ui/screens/shared/library/create_library_item_screen.dart';
import 'package:tunify/ui/screens/shared/library/library_playlist_screen.dart';
import 'package:tunify/ui/screens/shared/library/library_playlists_section.dart';
import 'package:tunify/ui/screens/shared/library/library_app_bar.dart';
import 'package:tunify/ui/screens/shared/library/library_search_screen.dart';
import 'package:tunify/ui/widgets/library/library_item_tile.dart';
import 'package:tunify/ui/widgets/common/adaptive_menu.dart';
import 'package:tunify/ui/screens/shared/library/create_library_options.dart';
import 'package:tunify/ui/widgets/player/download_queue_sheet.dart';
import 'package:tunify/features/downloads/download_provider.dart';
import 'package:tunify/features/device/device_music_provider.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// Drives the chip row.
  LibraryFilter? _filter;

  /// Drives the body content (kept in sync with _filter for smooth transitions).
  LibraryFilter? _contentFilter;

  /// When non-null, section shows this folder's playlists with a back row instead of main list.
  String? _selectedFolderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deviceMusicProvider.notifier).loadSongs();
    });
  }

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

  /// Builds the main list entries (Liked Songs + Downloads + Local Files + folders + playlists) or playlists-only.
  List<LibrarySectionEntry> _buildSectionEntries({
    required bool includeLikedSongs,
    required List<LibraryFolder> folders,
    required List<LibraryPlaylist> rootPlaylists,
  }) {
    if (includeLikedSongs) {
      final downloadCount =
          ref.watch(downloadServiceProvider).downloadedSongs.length;
      final localFilesCount = ref.watch(deviceMusicProvider).songs.length;
      final episodesForLaterCount =
          ref.watch(podcastProvider.select((s) => s.episodesForLater.length));
      final podcasts = ref.watch(podcastSubscriptionsProvider);
      final audiobooks = ref.watch(savedAudiobooksProvider);
      return [
        LikedSongsEntry(
          songCount: ref.watch(libraryLikedCountProvider),
          onTap: () {
            Navigator.of(context).push(
              appPageRoute<void>(
                builder: (_) => const LibraryPlaylistScreen.liked(),
              ),
            );
          },
        ),
        DownloadsEntry(
          songCount: downloadCount,
          onTap: () {
            Navigator.of(context).push(
              appPageRoute<void>(
                builder: (_) => const LibraryPlaylistScreen.downloads(),
              ),
            );
          },
        ),
        LocalFilesEntry(
          songCount: localFilesCount,
          onTap: () {
            Navigator.of(context).push(
              appPageRoute<void>(
                builder: (_) => const LibraryPlaylistScreen.localFiles(),
              ),
            );
          },
        ),
        EpisodesForLaterEntry(
          episodeCount: episodesForLaterCount,
          onTap: () {
            Navigator.of(context).push(
              appPageRoute<void>(
                builder: (_) => LibraryPlaylistScreen.podcast(
                  playlist: Playlist(
                    id: 'episodesForLater',
                    title: 'Episodes For Later',
                    description: 'Your saved podcast episodes',
                    coverUrl: '',
                    trackCount: episodesForLaterCount,
                  ),
                ),
              ),
            );
          },
        ),
        ...podcasts.map(
          (p) => MediaLibraryEntry(
            title: p.title,
            subtitle: p.author ?? 'Podcast',
            thumbnailUrl: p.thumbnailUrl,
            placeholderIcon: AppIcons.podcast,
            showPinIndicator: p.isPinned,
            onTap: () {
              Navigator.of(context).push(
                appPageRoute<void>(
                  builder: (_) => LibraryPlaylistScreen.podcast(
                    playlist: Playlist(
                      id: p.browseId ?? p.id,
                      title: p.title,
                      description: p.author ?? '',
                      coverUrl: p.thumbnailUrl ?? '',
                    ),
                  ),
                ),
              );
            },
            onOptions: (rect) => _onPlaylistOptions(
              _mediaAsLibraryPlaylist(
                id: p.browseId ?? p.id,
                title: p.title,
                subtitle: p.author ?? '',
                thumbnailUrl: p.thumbnailUrl,
                isPinned: p.isPinned,
              ),
              rect,
            ),
          ),
        ),
        ...audiobooks.map(
          (a) => MediaLibraryEntry(
            title: a.title,
            subtitle: a.author ?? 'Audiobook',
            thumbnailUrl: a.thumbnailUrl,
            placeholderIcon: AppIcons.bookOpen,
            showPinIndicator: a.isPinned,
            onTap: () {
              Navigator.of(context).push(
                appPageRoute<void>(
                  builder: (_) => LibraryPlaylistScreen.podcast(
                    playlist: Playlist(
                      id: a.browseId ?? a.id,
                      title: a.title,
                      description: a.author ?? '',
                      coverUrl: a.thumbnailUrl ?? '',
                    ),
                  ),
                ),
              );
            },
            onOptions: (rect) => _onPlaylistOptions(
              _mediaAsLibraryPlaylist(
                id: a.browseId ?? a.id,
                title: a.title,
                subtitle: a.author ?? '',
                thumbnailUrl: a.thumbnailUrl,
                isPinned: a.isPinned,
              ),
              rect,
            ),
          ),
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

  LibraryPlaylist _mediaAsLibraryPlaylist({
    required String id,
    required String title,
    required String subtitle,
    required String? thumbnailUrl,
    required bool isPinned,
  }) =>
      LibraryPlaylist(
        id: id,
        name: title,
        description: subtitle,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isImported: true,
        browseId: id,
        customImageUrl: thumbnailUrl,
        isPinned: isPinned,
      );

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final isLoading = ref.watch(libraryProvider.select((s) => s.isLoading));
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
      if (isLoading) {
        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: LibrarySkeletonList(viewMode: viewMode),
        );
      }
      final scrollView = CustomScrollView(
        key: contentKey,
        cacheExtent: 1000,
        physics: withRefresh
            ? const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics())
            : const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          ..._buildContentSlivers(viewMode, sortOrder, rootPlaylists),
          SliverToBoxAdapter(
            child: SizedBox(
              height: isDesktop ? 96 : 160,
            ),
          ),
        ],
      );
      if (withRefresh) {
        return RefreshIndicator(onRefresh: _onPullToRefresh, child: scrollView);
      }
      return scrollView;
    }

    final isLoggedIn = ref.watch(currentUserProvider) != null;

    return Scaffold(
      backgroundColor: AppColorsScheme.of(context).background,
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
        final disableEmptyFadeTransition =
            showCreateFirstPlaylistEmptyState && entries.isEmpty;
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
              showCreateFirstPlaylistEmptyState:
                  showCreateFirstPlaylistEmptyState,
              isFolderView: _selectedFolderId != null,
            ),
          ),
        ];
      case LibraryFilter.podcasts:
        final podcasts = ref.watch(podcastSubscriptionsProvider);
        if (podcasts.isEmpty) {
          return [
            SliverFillRemaining(
              child: LibraryFilterPlaceholder(
                icon: AppIcons.podcast,
                message: 'Podcasts you save will appear here',
              ),
            ),
          ];
        }
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: podcasts.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final podcast = podcasts[index];
                  return LibraryItemTile(
                    title: podcast.title,
                    subtitle: podcast.author ?? 'Podcast',
                    thumbnailUrl: podcast.thumbnailUrl,
                    placeholderIcon: AppIcons.podcast,
                    onTap: () {
                      Navigator.of(context).push(
                        appPageRoute<void>(
                          builder: (_) => LibraryPlaylistScreen.podcast(
                            playlist: Playlist(
                              id: podcast.browseId ?? podcast.id,
                              title: podcast.title,
                              description: podcast.author ?? '',
                              coverUrl: podcast.thumbnailUrl ?? '',
                            ),
                          ),
                        ),
                      );
                    },
                    onOptions: (rect) => _onPlaylistOptions(
                      _mediaAsLibraryPlaylist(
                        id: podcast.browseId ?? podcast.id,
                        title: podcast.title,
                        subtitle: podcast.author ?? '',
                        thumbnailUrl: podcast.thumbnailUrl,
                        isPinned: podcast.isPinned,
                      ),
                      rect,
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 160)),
        ];
      case LibraryFilter.audiobooks:
        final audiobooks = ref.watch(savedAudiobooksProvider);
        if (audiobooks.isEmpty) {
          return [
            SliverFillRemaining(
              child: LibraryFilterPlaceholder(
                icon: AppIcons.bookOpen,
                message: 'Audiobooks you save will appear here',
              ),
            ),
          ];
        }
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: audiobooks.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final audiobook = audiobooks[index];
                  return LibraryItemTile(
                    title: audiobook.title,
                    subtitle: audiobook.author ?? 'Audiobook',
                    thumbnailUrl: audiobook.thumbnailUrl,
                    placeholderIcon: AppIcons.bookOpen,
                    onTap: () {
                      Navigator.of(context).push(
                        appPageRoute<void>(
                          builder: (_) => LibraryPlaylistScreen.podcast(
                            playlist: Playlist(
                              id: audiobook.browseId ?? audiobook.id,
                              title: audiobook.title,
                              description: audiobook.author ?? '',
                              coverUrl: audiobook.thumbnailUrl ?? '',
                            ),
                          ),
                        ),
                      );
                    },
                    onOptions: (rect) => _onPlaylistOptions(
                      _mediaAsLibraryPlaylist(
                        id: audiobook.browseId ?? audiobook.id,
                        title: audiobook.title,
                        subtitle: audiobook.author ?? '',
                        thumbnailUrl: audiobook.thumbnailUrl,
                        isPinned: audiobook.isPinned,
                      ),
                      rect,
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 160)),
        ];
      case LibraryFilter.albums:
        final rawAlbums =
            ref.watch(libraryProvider.select((s) => s.followedAlbums));
        const albumsHPad = AppSpacing.base;
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
              padding: const EdgeInsets.symmetric(horizontal: albumsHPad),
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
        const artistsHPad = AppSpacing.base;
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
              padding: const EdgeInsets.symmetric(horizontal: artistsHPad),
              child: viewMode == LibraryViewMode.grid
                  ? _FollowedArtistsGrid(artists: sortedArtists)
                  : _FollowedArtistsList(artists: sortedArtists),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 160)),
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
        copy.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
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
        copy.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
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
    showLibraryPlaylistOptionsSheet(context, ref, playlist,
        anchorRect: anchorRect);
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
                builder: (_) => LibraryPlaylistScreen.artist(
                  artistName: artist.name,
                  thumbnailUrl: artist.thumbnailUrl,
                  browseId: artist.browseId,
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
                        color: AppColorsScheme.of(context).surfaceLight,
                        child: AppIcon(
                            icon: AppIcons.person,
                            color: AppColorsScheme.of(context).textMuted,
                            size: 28),
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
                          style: TextStyle(
                            color: AppColorsScheme.of(context).textPrimary,
                            fontSize: AppFontSize.lg,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Artist',
                          style: TextStyle(
                              color: AppColorsScheme.of(context).textMuted,
                              fontSize: AppFontSize.md),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: AppIcon(
                        icon: AppIcons.checkCircle,
                        color: AppColors.primary,
                        size: 22),
                    onPressed: () => ref
                        .read(libraryProvider.notifier)
                        .toggleFollowArtist(artist),
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
      cacheExtent: 1000,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
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
              builder: (_) => LibraryPlaylistScreen.artist(
                artistName: artist.name,
                thumbnailUrl: artist.thumbnailUrl,
                browseId: artist.browseId,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColorsScheme.of(context).surfaceLight,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: artist.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => AppIcon(
                        icon: AppIcons.person,
                        color: AppColorsScheme.of(context).textMuted,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                artist.name,
                style: TextStyle(
                  color: AppColorsScheme.of(context).textPrimary,
                  fontSize: AppFontSize.md,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              Text(
                'Artist',
                style: TextStyle(
                    color: AppColorsScheme.of(context).textMuted,
                    fontSize: AppFontSize.xs),
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
                builder: (_) => LibraryPlaylistScreen.album(
                  songTitle: album.title,
                  artistName: album.artistName,
                  thumbnailUrl: album.thumbnailUrl,
                  browseId: album.browseId,
                  name: album.title,
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
                        color: AppColorsScheme.of(context).surfaceLight,
                        child: AppIcon(
                            icon: AppIcons.album,
                            color: AppColorsScheme.of(context).textMuted,
                            size: 28),
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
                          style: TextStyle(
                            color: AppColorsScheme.of(context).textPrimary,
                            fontSize: AppFontSize.lg,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          album.artistName,
                          style: TextStyle(
                              color: AppColorsScheme.of(context).textMuted,
                              fontSize: AppFontSize.md),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: AppIcon(
                        icon: AppIcons.checkCircle,
                        color: AppColors.primary,
                        size: 22),
                    onPressed: () => ref
                        .read(libraryProvider.notifier)
                        .toggleFollowAlbum(album),
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
      cacheExtent: 1000,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
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
              builder: (_) => LibraryPlaylistScreen.album(
                songTitle: album.title,
                artistName: album.artistName,
                thumbnailUrl: album.thumbnailUrl,
                browseId: album.browseId,
                name: album.title,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColorsScheme.of(context).surfaceLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: CachedNetworkImage(
                      imageUrl: album.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => AppIcon(
                        icon: AppIcons.album,
                        color: AppColorsScheme.of(context).textMuted,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                album.title,
                style: TextStyle(
                  color: AppColorsScheme.of(context).textPrimary,
                  fontSize: AppFontSize.md,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                album.artistName,
                style: TextStyle(
                    color: AppColorsScheme.of(context).textMuted,
                    fontSize: AppFontSize.xs),
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
              color:
                  AppColorsScheme.of(context).textMuted.withValues(alpha: 0.5),
              size: 64,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColorsScheme.of(context)
                    .textMuted
                    .withValues(alpha: 0.9),
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
          padding:
              const EdgeInsets.symmetric(horizontal: kSheetHorizontalPadding),
          child: Row(
            children: [
              AppIcon(
                icon: AppIcons.folder,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Add to folder',
                style: TextStyle(
                  color: AppColorsScheme.of(context).textPrimary,
                  fontSize: AppFontSize.h3,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.folders.length}',
                style: TextStyle(
                  color: AppColorsScheme.of(context).textMuted,
                  fontSize: AppFontSize.base,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: kSheetHorizontalPadding),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: AppColorsScheme.of(context).surfaceLight,
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Row(
              children: [
                const SizedBox(width: AppSpacing.base),
                AppIcon(
                  icon: AppIcons.search,
                  color: AppColorsScheme.of(context).textMuted,
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
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: AppIcon(
                        icon: AppIcons.clear,
                        color: AppColorsScheme.of(context).textMuted,
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
                  cacheExtent: 1000,
                  addAutomaticKeepAlives: true,
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
                        style: TextStyle(
                            color: AppColorsScheme.of(context).textPrimary),
                      ),
                      subtitle: Text(
                        '${f.playlistCount} playlists',
                        style: TextStyle(
                            color: AppColorsScheme.of(context).textMuted,
                            fontSize: AppFontSize.sm),
                      ),
                      trailing: hasPlaylist
                          ? AppIcon(
                              icon: AppIcons.check, color: AppColors.primary)
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
  final isDesktop = ShellContext.isDesktopPlatform;

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
            ref
                .read(libraryProvider.notifier)
                .removePlaylistFromFolder(f.id, playlist.id);
          } else {
            ref
                .read(libraryProvider.notifier)
                .addPlaylistToFolder(f.id, playlist.id);
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
          onTap: () =>
              ref.read(libraryProvider.notifier).togglePlaylistPin(playlist.id),
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
              message:
                  '${playlist.name.capitalized} will be removed from your library.',
              confirmLabel: 'Delete',
            );
            if (confirmed) {
              await ref
                  .read(libraryProvider.notifier)
                  .deletePlaylist(playlist.id);
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
          message:
              '${playlist.name.capitalized} will be removed from your library.',
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
  final isDesktop = ShellContext.isDesktopPlatform;

  if (isDesktop) {
    showAdaptiveMenu(
      context,
      title: folder.name,
      entries: [
        AppMenuEntry(
          icon: folder.isPinned ? AppIcons.pinOff : AppIcons.pin,
          label: folder.isPinned ? 'Unpin' : 'Pin to top',
          onTap: () =>
              ref.read(libraryProvider.notifier).toggleFolderPin(folder.id),
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
              ref
                  .read(libraryProvider.notifier)
                  .renameFolder(folder.id, newName.trim());
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
              message:
                  '${folder.name.capitalized} will be removed. Playlists inside will not be deleted.',
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
          ref
              .read(libraryProvider.notifier)
              .renameFolder(folder.id, newName.trim());
        }
      },
      onDelete: () async {
        final confirmed = await showConfirmDialog(
          context,
          title: 'Delete folder?',
          message:
              '${folder.name.capitalized} will be removed. Playlists inside will not be deleted.',
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
