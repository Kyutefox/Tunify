import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/library_album.dart';
import 'package:tunify/data/models/library_artist.dart';
import 'package:tunify/data/models/library_folder.dart';
import 'package:tunify/data/models/library_playlist.dart';
import 'package:tunify/features/downloads/download_provider.dart';
import 'package:tunify/features/device/device_music_provider.dart';
import 'package:tunify/features/library/library_provider.dart';
import 'package:tunify/ui/widgets/common/adaptive_menu.dart';
import 'package:tunify/ui/widgets/library/library_filter_chips.dart';
import 'package:tunify/ui/widgets/library/library_thumbnail_tile.dart';
import 'package:tunify/ui/widgets/common/button.dart';
import 'package:tunify/ui/widgets/common/input_field.dart';
import 'package:tunify/ui/screens/shared/library/library_app_bar.dart';
import 'package:tunify/ui/screens/shared/library/library_playlist_screen.dart';
import 'package:tunify/ui/screens/shared/library/library_playlists_section.dart';
import 'package:tunify/ui/screens/shared/library/library_search_screen.dart';
import 'package:tunify/ui/screens/shared/library/library_screen.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/desktop_tokens.dart';

const double kDesktopSidebarWidth = 340.0;

/// Library-only left sidebar for the macOS desktop layout.
///
/// Reuses the exact same components as the mobile library:
/// - [LibraryFilterChips] — identical animated filter chips
/// - [LibraryPlaylistsSection] — identical liked/folder/playlist tiles
/// - [showLibrarySortSheet] — same sort-order bottom sheet
/// - [LibrarySearchScreen] — same search modal
///
/// Sort order and view mode are driven by [libraryProvider] — the same shared
/// state that [LibraryScreen] on mobile reads — so preferences persist across
/// both layouts automatically.
class DesktopSidebar extends ConsumerStatefulWidget {
  const DesktopSidebar({
    super.key,
    required this.onCreatePlaylist,
    required this.onCreateFolder,
    required this.onNavigateTo,
  });

  final VoidCallback onCreatePlaylist;
  final VoidCallback onCreateFolder;

  /// Pushes a page into the main content Navigator (desktop in-panel nav).
  final void Function(Widget page) onNavigateTo;

  @override
  ConsumerState<DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends ConsumerState<DesktopSidebar> {
  LibraryFilter? _filter;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  /// When non-null, the sidebar shows the folder's playlist list inline.
  LibraryFolder? _openFolder;

  void _onFilterChanged(LibraryFilter? f) => setState(() => _filter = f);

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchFocusNode.unfocus();
        _searchQuery = '';
      }
    });
  }

  // ── Navigation helpers ──────────────────────────────────────────────────

  void _openPlaylist(LibraryPlaylist p) =>
      widget.onNavigateTo(LibraryPlaylistScreen(playlistId: p.id));

  void _openFolderInline(LibraryFolder f) => setState(() => _openFolder = f);

  void _closeFolderInline() => setState(() => _openFolder = null);

  void _openAlbum(LibraryAlbum a) =>
      widget.onNavigateTo(LibraryPlaylistScreen.album(
        songTitle: a.title,
        artistName: a.artistName,
        thumbnailUrl: a.thumbnailUrl,
        browseId: a.browseId,
        name: a.title,
      ));

  void _openArtist(LibraryArtist a) =>
      widget.onNavigateTo(LibraryPlaylistScreen.artist(
          artistName: a.name,
          thumbnailUrl: a.thumbnailUrl,
          browseId: a.browseId));

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryProvider);
    final sortOrder = ref.watch(libraryProvider.select((s) => s.sortOrder));
    final viewMode = ref.watch(libraryProvider.select((s) => s.viewMode));

    // ── Filter + sort playlists/folders ────────────────────────────────
    final showAll = _filter == null;
    final showPlaylists = showAll || _filter == LibraryFilter.playlists;
    final showAlbums = showAll || _filter == LibraryFilter.albums;
    final showArtists = showAll || _filter == LibraryFilter.artists;
    final q = _searchQuery.toLowerCase().trim();

    final inFolderIds = library.folders.fold<Set<String>>(
      {},
      (set, f) => set..addAll(f.playlistIds),
    );

    final isPlaylistsFilter = _filter == LibraryFilter.playlists;

    // Folders are hidden when the Playlists filter is active (matches mobile).
    final folders = showAll
        ? library.sortedFolders
            .where((f) => q.isEmpty || f.name.toLowerCase().contains(q))
            .toList()
        : <LibraryFolder>[];

    // Playlists filter shows ALL playlists as a flat list (including those
    // inside folders). Unfiltered view shows only root-level playlists.
    final rootPlaylists = !showPlaylists
        ? <LibraryPlaylist>[]
        : isPlaylistsFilter
            ? library.sortedPlaylists
                .where((p) => q.isEmpty || p.name.toLowerCase().contains(q))
                .toList()
            : library.sortedPlaylists
                .where((p) =>
                    !inFolderIds.contains(p.id) &&
                    (q.isEmpty || p.name.toLowerCase().contains(q)))
                .toList();

    // Liked songs tile only shows in the unfiltered "all" view (matches mobile).
    final showLiked = showAll && (q.isEmpty || 'liked songs'.contains(q));

    final downloadCount =
        ref.watch(downloadServiceProvider).downloadedSongs.length;
    final localFilesCount = ref.watch(deviceMusicProvider).songs.length;

    // Build section entries — same helper pattern as LibraryScreen
    final List<LibrarySectionEntry> playlistEntries = [
      if (showLiked)
        LikedSongsEntry(
          songCount: library.likedSongs.length,
          onTap: () => widget.onNavigateTo(const LibraryPlaylistScreen.liked()),
        ),
      if (showAll && _openFolder == null)
        DownloadsEntry(
          songCount: downloadCount,
          onTap: () =>
              widget.onNavigateTo(const LibraryPlaylistScreen.downloads()),
        ),
      if (showAll && _openFolder == null)
        LocalFilesEntry(
          songCount: localFilesCount,
          onTap: () =>
              widget.onNavigateTo(const LibraryPlaylistScreen.localFiles()),
        ),
      ...folders.map(FolderEntry.new),
      ...rootPlaylists.map(PlaylistEntry.new),
    ];

    final albums = showAlbums
        ? library.followedAlbums
            .where((a) =>
                q.isEmpty ||
                a.title.toLowerCase().contains(q) ||
                a.artistName.toLowerCase().contains(q))
            .toList()
        : <LibraryAlbum>[];
    final artists = showArtists
        ? library.followedArtists
            .where((a) => q.isEmpty || a.name.toLowerCase().contains(q))
            .toList()
        : <LibraryArtist>[];

    // ── When a folder is open, override the list to show only its playlists ─
    final List<LibrarySectionEntry>? folderEntries = _openFolder == null
        ? null
        : library.sortedPlaylists
            .where((p) => _openFolder!.playlistIds.contains(p.id))
            .map(PlaylistEntry.new)
            .toList();

    final hasContent = (folderEntries?.isNotEmpty ?? false) ||
        playlistEntries.isNotEmpty ||
        albums.isNotEmpty ||
        artists.isNotEmpty;

    return SizedBox(
      width: kDesktopSidebarWidth,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(DesktopSpacing.base,
                  DesktopSpacing.lg, DesktopSpacing.sm, DesktopSpacing.md),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Library',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: DesktopFontSize.h2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  _CreateMenuButton(
                    onCreatePlaylist: widget.onCreatePlaylist,
                    onCreateFolder: widget.onCreateFolder,
                  ),
                ],
              ),
            ),

            // ── Filter chips ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  DesktopSpacing.base, 0, DesktopSpacing.base, 0),
              child: LibraryFilterChips(
                selectedFilter: _filter,
                onFilterChanged: _onFilterChanged,
                filters: const [
                  LibraryFilter.playlists,
                  LibraryFilter.albums,
                  LibraryFilter.artists,
                ],
                folderName: _openFolder?.name,
                onExitFolder: _openFolder != null ? _closeFolderInline : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Sort + search + view mode ───────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isSearching
                  ? Padding(
                      key: const ValueKey('search-field'),
                      padding: const EdgeInsets.fromLTRB(DesktopSpacing.base, 0,
                          DesktopSpacing.sm, DesktopSpacing.xs),
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Row(
                          children: [
                            AppIconButton(
                              icon: AppIcon(
                                icon: AppIcons.back,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: _toggleSearch,
                              size: 36,
                              iconSize: 18,
                            ),
                            AppIcon(
                              icon: AppIcons.search,
                              size: 15,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  inputDecorationTheme:
                                      const InputDecorationTheme(
                                    border: InputBorder.none,
                                    filled: false,
                                  ),
                                ),
                                child: AppInputField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  hintText: 'Search in Library',
                                  textInputAction: TextInputAction.search,
                                  style: InputFieldStyle.transparent,
                                  autofocus: true,
                                  onChanged: (v) =>
                                      setState(() => _searchQuery = v),
                                ),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              AppIconButton(
                                icon: AppIcon(
                                  icon: AppIcons.clear,
                                  size: 15,
                                  color: AppColors.textMuted,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchFocusNode.unfocus();
                                  setState(() => _searchQuery = '');
                                },
                                size: 36,
                                iconSize: 15,
                              )
                            else
                              const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      key: const ValueKey('controls-row'),
                      padding: const EdgeInsets.fromLTRB(DesktopSpacing.base, 0,
                          DesktopSpacing.sm, DesktopSpacing.xs),
                      child: Row(
                        children: [
                          Builder(
                            builder: (btnCtx) => GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                final box =
                                    btnCtx.findRenderObject() as RenderBox?;
                                Rect? rect;
                                if (box != null && box.hasSize) {
                                  rect =
                                      box.localToGlobal(Offset.zero) & box.size;
                                }
                                showLibrarySortSheet(
                                  context,
                                  sortOrder,
                                  (o) => ref
                                      .read(libraryProvider.notifier)
                                      .setSortOrder(o),
                                  anchorRect: rect,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: DesktopSpacing.xs),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppIcon(
                                      icon: AppIcons.sort,
                                      color: AppColors.textSecondary,
                                      size: DesktopIconSize.xs,
                                    ),
                                    const SizedBox(width: DesktopSpacing.xs),
                                    Text(
                                      sortOrder.label,
                                      style: const TextStyle(
                                        color: AppColors.desktopTextSecondary,
                                        fontSize: DesktopFontSize.sm,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          AppIconButton(
                            icon: AppIcon(
                              icon: AppIcons.search,
                              size: DesktopIconSize.xs,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: _toggleSearch,
                            size: DesktopButtonSize.sm,
                            iconSize: DesktopIconSize.xs,
                            tooltip: 'Search library',
                          ),
                          const SizedBox(width: 2),
                          AppIconButton(
                            icon: AppIcon(
                              icon: viewMode == LibraryViewMode.list
                                  ? AppIcons.gridView
                                  : AppIcons.listView,
                              size: DesktopIconSize.xs,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () =>
                                ref.read(libraryProvider.notifier).setViewMode(
                                      viewMode == LibraryViewMode.list
                                          ? LibraryViewMode.grid
                                          : LibraryViewMode.list,
                                    ),
                            size: DesktopButtonSize.sm,
                            iconSize: DesktopIconSize.xs,
                            tooltip: viewMode == LibraryViewMode.list
                                ? 'Grid view'
                                : 'List view',
                          ),
                        ],
                      ),
                    ),
            ),

            // ── Library list / search results ──────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: AppDuration.normal,
                switchInCurve: AppCurves.decelerate,
                switchOutCurve: AppCurves.standard,
                transitionBuilder: (child, animation) {
                  final currentKey = ValueKey(
                      'sidebar-$_filter-${_openFolder?.id}-$_isSearching');
                  final isIncoming = child.key == currentKey;
                  if (isIncoming) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.03),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: AppCurves.decelerate,
                        )),
                        child: child,
                      ),
                    );
                  }
                  return FadeTransition(opacity: animation, child: child);
                },
                child: KeyedSubtree(
                  key: ValueKey(
                      'sidebar-$_filter-${_openFolder?.id}-$_isSearching'),
                  child: _isSearching
                      // ── Search mode: same body component as LibrarySearchScreen ──
                      ? LibrarySearchBody(
                          query: _searchQuery.trim().toLowerCase(),
                          onFolderTap: _openFolderInline,
                          onPlaylistTap: _openPlaylist,
                        )
                      // ── Normal mode: full library list ─────────────────────────
                      : !hasContent
                          ? LibraryFilterPlaceholder(
                              icon: _filter == LibraryFilter.albums
                                  ? AppIcons.album
                                  : _filter == LibraryFilter.artists
                                      ? AppIcons.artist
                                      : AppIcons.playlist,
                              message: _filter == LibraryFilter.playlists
                                  ? 'Playlists you create will appear here'
                                  : _filter == LibraryFilter.albums
                                      ? 'Albums you save will appear here'
                                      : _filter == LibraryFilter.artists
                                          ? 'Artists you follow will appear here'
                                          : 'Your library is empty.\nTap + to get started.',
                            )
                          : ListView(
                              padding: const EdgeInsets.only(
                                  top: AppSpacing.xs, bottom: 8),
                              children: [
                                // Folder open: show only that folder's playlists
                                if (folderEntries != null) ...[
                                  if (folderEntries.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(AppSpacing.xl),
                                      child: Text(
                                        'No playlists in this folder.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: AppFontSize.md),
                                      ),
                                    )
                                  else
                                    LibraryPlaylistsSection(
                                      entries: folderEntries,
                                      viewMode: viewMode,
                                      onPlaylistTap: _openPlaylist,
                                      onPlaylistOptions: (p, rect) =>
                                          showLibraryPlaylistOptionsSheet(
                                              context, ref, p,
                                              anchorRect: rect),
                                      onFolderTap: _openFolderInline,
                                      onFolderOptions: (f, rect) =>
                                          showLibraryFolderOptionsSheet(
                                              context, ref, f,
                                              anchorRect: rect),
                                    ),
                                ] else ...[
                                  // Normal library list
                                  if (playlistEntries.isNotEmpty)
                                    LibraryPlaylistsSection(
                                      entries: playlistEntries,
                                      viewMode: viewMode,
                                      onPlaylistTap: _openPlaylist,
                                      onPlaylistOptions: (p, rect) =>
                                          showLibraryPlaylistOptionsSheet(
                                              context, ref, p,
                                              anchorRect: rect),
                                      onFolderTap: _openFolderInline,
                                      onFolderOptions: (f, rect) =>
                                          showLibraryFolderOptionsSheet(
                                              context, ref, f,
                                              anchorRect: rect),
                                    ),

                                  if (albums.isNotEmpty) ...[
                                    if (showAll)
                                      const _SectionLabel(label: 'ALBUMS'),
                                    for (final a in albums)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: DesktopSpacing.base),
                                        child: LibraryThumbnailTile(
                                          thumbnailUrl:
                                              a.thumbnailUrl.isNotEmpty
                                                  ? a.thumbnailUrl
                                                  : null,
                                          title: a.title,
                                          subtitle: a.artistName,
                                          onTap: () => _openAlbum(a),
                                        ),
                                      ),
                                  ],

                                  if (artists.isNotEmpty) ...[
                                    if (showAll)
                                      const _SectionLabel(label: 'ARTISTS'),
                                    for (final a in artists)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: DesktopSpacing.base),
                                        child: LibraryThumbnailTile(
                                          thumbnailUrl:
                                              a.thumbnailUrl.isNotEmpty
                                                  ? a.thumbnailUrl
                                                  : null,
                                          title: a.name,
                                          subtitle: 'Artist',
                                          isCircle: true,
                                          onTap: () => _openArtist(a),
                                        ),
                                      ),
                                  ],
                                ],
                              ],
                            ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create menu button ────────────────────────────────────────────────────────

/// Shows an adaptive menu (sheet on mobile, dropdown on desktop) with
/// "Create playlist" and "Create folder" options.
class _CreateMenuButton extends StatelessWidget {
  const _CreateMenuButton({
    required this.onCreatePlaylist,
    required this.onCreateFolder,
  });

  final VoidCallback onCreatePlaylist;
  final VoidCallback onCreateFolder;

  @override
  Widget build(BuildContext context) {
    return AdaptiveMenuAnchor(
      title: 'Create',
      entries: [
        AppMenuEntry(
          icon: AppIcons.playlistAdd,
          label: 'Create playlist',
          onTap: onCreatePlaylist,
        ),
        AppMenuEntry(
          icon: AppIcons.newFolder,
          label: 'Create folder',
          onTap: onCreateFolder,
        ),
      ],
      child: AppIconButton(
        icon:
            AppIcon(icon: AppIcons.add, size: 20, color: AppColors.textPrimary),
        onPressed: null, // tap handled by AdaptiveMenuAnchor
        size: 36,
        iconSize: 20,
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, AppSpacing.md, AppSpacing.base, AppSpacing.xs),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: DesktopFontSize.xs,
          fontWeight: FontWeight.w700,
          letterSpacing: AppLetterSpacing.label,
        ),
      ),
    );
  }
}
