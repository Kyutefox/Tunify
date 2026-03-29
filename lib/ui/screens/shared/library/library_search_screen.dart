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
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_routes.dart';
import 'library_playlist_screen.dart';
import 'library_playlists_section.dart';
import 'package:tunify/ui/widgets/player/mini_player.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

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
      backgroundColor: AppColorsScheme.of(context).background,
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
          color: AppColorsScheme.of(context).textMuted,
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
        style: TextStyle(
          color: AppColorsScheme.of(context).textSecondary,
          fontSize: AppFontSize.lg,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final entries = <LibrarySectionEntry>[
      ...filteredFolders.map(FolderEntry.new),
      ...filteredPlaylists.map(PlaylistEntry.new),
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.max),
      children: [
        LibraryPlaylistsSection(
          entries: entries,
          viewMode: LibraryViewMode.list,
          onPlaylistTap: (p) {
            if (onPlaylistTap != null) {
              onPlaylistTap!(p);
            } else {
              Navigator.pop(context);
              Navigator.of(context).push(appPageRoute<void>(
                builder: (_) => LibraryPlaylistScreen(playlistId: p.id),
              ));
            }
          },
          onPlaylistOptions: (_, __) {},
          onFolderTap: (f) {
            if (onFolderTap != null) {
              onFolderTap!(f);
            } else {
              Navigator.of(context).pop(f.id);
            }
          },
          onFolderOptions: (_, __) {},
        ),
      ],
    );
  }
}
