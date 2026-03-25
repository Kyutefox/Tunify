import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/ui/screens/shared/search/search_page.dart';
import 'package:tunify/ui/widgets/common/empty_list_message.dart';
import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/data/models/library_folder.dart';
import 'package:tunify/data/models/library_playlist.dart';
import 'package:tunify/features/library/library_provider.dart';
import 'package:tunify/core/utils/string_utils.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_routes.dart';
import 'library_playlist_screen.dart';
import 'package:tunify/ui/widgets/player/mini_player.dart';

/// Full-screen library search using [SharedSearchPage]. Filters playlists
/// and folders by name; tap opens a playlist or opens a folder in the library.
class LibrarySearchScreen extends ConsumerStatefulWidget {
  const LibrarySearchScreen({super.key});

  @override
  ConsumerState<LibrarySearchScreen> createState() =>
      _LibrarySearchScreenState();
}

class _LibrarySearchScreenState extends ConsumerState<LibrarySearchScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _controller.addListener(() => setState(() {}));
    // Defer focus so the route transition finishes first; reduces shutter.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNode.canRequestFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSong = ref.watch(currentSongProvider) != null;
    final searchPage = SharedSearchPage(
      controller: _controller,
      focusNode: _focusNode,
      onBack: () {
        _controller.clear();
        Navigator.of(context).pop();
      },
      onClear: () => setState(() {}),
      hintText: 'Search in Library',
      autofocus: false,
      body: LibrarySearchBody(query: _controller.text.trim().toLowerCase()),
    );
    if (!hasSong) return searchPage;
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: searchPage),
            const MiniPlayer(key: ValueKey('library-search-mini-player')),
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
      ),
    );
  }
}

/// Shared search results body used by both [LibrarySearchScreen] (mobile,
/// full-screen) and the desktop sidebar search panel.
///
/// When [onFolderTap] / [onPlaylistTap] are null the widget falls back to
/// the mobile navigator pattern (pop with folder-id / pop then push playlist).
class LibrarySearchBody extends ConsumerWidget {
  const LibrarySearchBody({
    super.key,
    required this.query,
    this.onFolderTap,
    this.onPlaylistTap,
  });

  final String query;
  final void Function(LibraryFolder)? onFolderTap;
  final void Function(LibraryPlaylist)? onPlaylistTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.isEmpty) {
      return SearchPageEmptyState(
        icon: AppIcon(
          icon: AppIcons.search,
          size: 64,
          color: AppColors.textMuted,
        ),
        heading: 'Search your library',
        subheading: 'Find playlists and folders by name',
      );
    }

    final playlists = ref.watch(libraryPlaylistsProvider);
    final folders = ref.watch(libraryFoldersProvider);
    final inFolderIds = folders.fold<Set<String>>(
      {},
      (set, f) => set..addAll(f.playlistIds),
    );
    final rootPlaylists =
        playlists.where((p) => !inFolderIds.contains(p.id)).toList();

    final filteredPlaylists = rootPlaylists
        .where((p) => p.name.toLowerCase().contains(query))
        .toList();
    final filteredFolders =
        folders.where((f) => f.name.toLowerCase().contains(query)).toList();
    final hasResults =
        filteredPlaylists.isNotEmpty || filteredFolders.isNotEmpty;

    if (!hasResults) {
      return EmptyListMessage(
        emptyLabel: 'results',
        query: query,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: AppFontSize.lg,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.max),
      children: [
        if (filteredFolders.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              'FOLDERS',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.9),
                fontSize: AppFontSize.sm,
                fontWeight: FontWeight.w700,
                letterSpacing: AppLetterSpacing.label,
              ),
            ),
          ),
          ...filteredFolders.map((folder) => _FolderTile(
                folder: folder,
                onTap: onFolderTap != null
                    ? () => onFolderTap!(folder)
                    : () => Navigator.of(context).pop(folder.id),
              )),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (filteredPlaylists.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              'PLAYLISTS',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.9),
                fontSize: AppFontSize.sm,
                fontWeight: FontWeight.w700,
                letterSpacing: AppLetterSpacing.label,
              ),
            ),
          ),
          ...filteredPlaylists.map((playlist) => _PlaylistTile(
                playlist: playlist,
                onTap: onPlaylistTap != null
                    ? () => onPlaylistTap!(playlist)
                    : () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          appPageRoute<void>(
                            builder: (_) =>
                                LibraryPlaylistScreen(playlistId: playlist.id),
                          ),
                        );
                      },
              )),
        ],
      ],
    );
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({required this.folder, required this.onTap});

  final LibraryFolder folder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AppIcon(
        icon: AppIcons.folder,
        color: AppColors.primary,
        size: 24,
      ),
      title: Text(
        folder.name.capitalized,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppFontSize.xl,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${folder.playlistCount} playlist${folder.playlistCount == 1 ? '' : 's'}',
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: AppFontSize.md,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({required this.playlist, required this.onTap});

  final LibraryPlaylist playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AppIcon(
        icon: AppIcons.playlist,
        color: AppColors.textSecondary,
        size: 24,
      ),
      title: Text(
        playlist.name.capitalized,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppFontSize.xl,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${playlist.songs.length} song${playlist.songs.length == 1 ? '' : 's'}',
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: AppFontSize.md,
        ),
      ),
      onTap: onTap,
    );
  }
}
