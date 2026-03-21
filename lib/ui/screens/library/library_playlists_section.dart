import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../config/app_icons.dart';
import '../../../models/library_folder.dart';
import '../../../models/library_playlist.dart';
import '../../../shared/providers/library_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';
import '../../../shared/utils/string_utils.dart';

/// A single item in the library playlists section: Liked Songs, a folder, or a playlist.
sealed class LibrarySectionEntry {}

class LikedSongsEntry extends LibrarySectionEntry {
  LikedSongsEntry({required this.songCount, required this.onTap});
  final int songCount;
  final VoidCallback onTap;
}

class FolderEntry extends LibrarySectionEntry {
  FolderEntry(this.folder);
  final LibraryFolder folder;
}

class PlaylistEntry extends LibrarySectionEntry {
  PlaylistEntry(this.playlist);
  final LibraryPlaylist playlist;
}

class LibraryPlaylistsSection extends StatelessWidget {
  const LibraryPlaylistsSection({
    super.key,
    required this.entries,
    required this.viewMode,
    required this.onPlaylistTap,
    required this.onPlaylistOptions,
    required this.onFolderTap,
    required this.onFolderOptions,
    this.showCreateFirstPlaylistEmptyState = false,
    this.isFolderView = false,
  });

  final List<LibrarySectionEntry> entries;
  final LibraryViewMode viewMode;
  final void Function(LibraryPlaylist) onPlaylistTap;
  final void Function(LibraryPlaylist, Rect?) onPlaylistOptions;
  final void Function(LibraryFolder) onFolderTap;
  final void Function(LibraryFolder, Rect?) onFolderOptions;
  /// When true and there are no entries (Playlists tab with no folders/playlists), show empty state.
  final bool showCreateFirstPlaylistEmptyState;
  /// When true, we're showing a folder's playlists; empty content shows folder empty message.
  final bool isFolderView;

  @override
  Widget build(BuildContext context) {
    final contentEntries = entries;
    final showCreateFirstEmptyState = showCreateFirstPlaylistEmptyState &&
        contentEntries.isEmpty;
    final showFolderEmptyState =
        isFolderView && contentEntries.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showFolderEmptyState)            _SectionEmptyState(
              child: Text(
                'No playlists in this folder',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 15,
                ),
              ),
            )
          else if (showCreateFirstEmptyState)
            _SectionEmptyState(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    icon: AppIcons.add,
                    size: 48,
                    color: AppColors.textMuted.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Create your first playlist',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Tap + to get started',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            AnimatedSwitcher(
              duration: AppDuration.fast,
              switchInCurve: AppCurves.decelerate,
              switchOutCurve: AppCurves.decelerate,
              child: KeyedSubtree(
                key: ValueKey(viewMode),
                child: viewMode == LibraryViewMode.grid
                    ? _LibrarySectionGrid(
                        entries: contentEntries,
                        onPlaylistTap: onPlaylistTap,
                        onPlaylistOptions: onPlaylistOptions,
                        onFolderTap: onFolderTap,
                        onFolderOptions: onFolderOptions,
                      )
                    : _LibrarySectionList(
                        entries: contentEntries,
                        onPlaylistTap: onPlaylistTap,
                        onPlaylistOptions: onPlaylistOptions,
                        onFolderTap: onFolderTap,
                        onFolderOptions: onFolderOptions,
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionEmptyState extends StatelessWidget {
  const _SectionEmptyState({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxl,
        horizontal: AppSpacing.base,
      ),
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Center(child: child),
    );
  }
}

class _LibrarySectionGrid extends StatelessWidget {
  const _LibrarySectionGrid({
    required this.entries,
    required this.onPlaylistTap,
    required this.onPlaylistOptions,
    required this.onFolderTap,
    required this.onFolderOptions,
  });

  final List<LibrarySectionEntry> entries;
  final void Function(LibraryPlaylist) onPlaylistTap;
  final void Function(LibraryPlaylist, Rect?) onPlaylistOptions;
  final void Function(LibraryFolder) onFolderTap;
  final void Function(LibraryFolder, Rect?) onFolderOptions;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return switch (entry) {
          LikedSongsEntry(:final songCount, :final onTap) => _StaticGridCard(
              iconWidget: FavouriteIcon(
                isLiked: true,
                size: 40,
                gradient: AppColors.loveThemeGradientFor('liked_songs'),
              ),
              backgroundColor: AppColors.surfaceLight,
              title: 'Liked Songs',
              subtitle: songCount == 0 ? 'No songs yet' : '$songCount songs',
              onTap: onTap,
            ),
          FolderEntry(:final folder) => _LibraryFolderGridCard(
              folder: folder,
              onTap: () => onFolderTap(folder),
              onOptions: (rect) => onFolderOptions(folder, rect),
            ),
          PlaylistEntry(:final playlist) => _LibraryPlaylistGridCard(
              playlist: playlist,
              onTap: () => onPlaylistTap(playlist),
              onOptions: (rect) => onPlaylistOptions(playlist, rect),
            ),
        };
      },
    );
  }
}

class _StaticGridCard extends StatelessWidget {
  const _StaticGridCard({
    this.icon,
    this.iconColor,
    this.iconWidget,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : assert(icon != null && iconColor != null || iconWidget != null);

  final List<List<dynamic>>? icon;
  final Color? iconColor;
  final Widget? iconWidget;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: iconWidget ?? AppIcon(
                  icon: icon!,
                  color: iconColor!,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LibraryPlaylistGridCard extends StatelessWidget {
  const _LibraryPlaylistGridCard({
    required this.playlist,
    required this.onTap,
    required this.onOptions,
  });

  final LibraryPlaylist playlist;
  final VoidCallback onTap;
  final void Function(Rect?) onOptions;

  @override
  Widget build(BuildContext context) {
    final coverUrl =
        playlist.songs.isNotEmpty ? playlist.songs.first.thumbnailUrl : null;

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => onOptions(null),
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
              child: coverUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: CachedNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => AppIcon(
                          icon: AppIcons.musicNote,
                          color: AppColors.textMuted,
                          size: 40,
                        ),
                      ),
                    )
                  : AppIcon(
                      icon: AppIcons.musicNote,
                      color: AppColors.textMuted,
                      size: 40,
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (playlist.isPinned)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: AppIcon(
                    icon: AppIcons.pin,
                    size: 12,
                    color: AppColors.primary,
                  ),
                ),
              Expanded(
                child: Text(
                  playlist.name.capitalized,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Builder(
                builder: (btnCtx) => GestureDetector(
                  onTap: () {
                    final box = btnCtx.findRenderObject() as RenderBox?;
                    onOptions(box != null && box.hasSize
                        ? box.localToGlobal(Offset.zero) & box.size
                        : null);
                  },
                  child: AppIcon(
                    icon: AppIcons.moreHoriz,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          Text(
            playlist.trackCountLabel,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryFolderGridCard extends StatelessWidget {
  const _LibraryFolderGridCard({
    required this.folder,
    required this.onTap,
    required this.onOptions,
  });

  final LibraryFolder folder;
  final VoidCallback onTap;
  final void Function(Rect?) onOptions;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => onOptions(null),
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
              child: Center(
                child: AppIcon(
                  icon: AppIcons.folder,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (folder.isPinned)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: AppIcon(
                    icon: AppIcons.pin,
                    size: 12,
                    color: AppColors.primary,
                  ),
                ),
              Expanded(
                child: Text(
                  folder.name.capitalized,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Builder(
                builder: (btnCtx) => GestureDetector(
                  onTap: () {
                    final box = btnCtx.findRenderObject() as RenderBox?;
                    onOptions(box != null && box.hasSize
                        ? box.localToGlobal(Offset.zero) & box.size
                        : null);
                  },
                  child: AppIcon(
                    icon: AppIcons.moreHoriz,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          Text(
            folder.playlistCount == 0
                ? 'No playlists'
                : '${folder.playlistCount} playlist${folder.playlistCount == 1 ? '' : 's'}',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryFolderListTile extends StatelessWidget {
  const _LibraryFolderListTile({
    required this.folder,
    required this.onTap,
    required this.onOptions,
  });

  final LibraryFolder folder;
  final VoidCallback onTap;
  final void Function(Rect?) onOptions;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => onOptions(null),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: AppIcon(
                    icon: AppIcons.folder,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name.capitalized,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      folder.playlistCount == 0
                          ? 'No playlists'
                          : '${folder.playlistCount} playlist${folder.playlistCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (folder.isPinned)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: AppIcon(
                    icon: AppIcons.pin,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              Builder(
                builder: (btnCtx) => IconButton(
                  icon: AppIcon(
                    icon: AppIcons.moreHoriz,
                    size: 22,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () {
                    final box = btnCtx.findRenderObject() as RenderBox?;
                    onOptions(box != null && box.hasSize
                        ? box.localToGlobal(Offset.zero) & box.size
                        : null);
                  },
                  color: AppColors.textMuted,
                  iconSize: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibrarySectionList extends StatelessWidget {
  const _LibrarySectionList({
    required this.entries,
    required this.onPlaylistTap,
    required this.onPlaylistOptions,
    required this.onFolderTap,
    required this.onFolderOptions,
  });

  final List<LibrarySectionEntry> entries;
  final void Function(LibraryPlaylist) onPlaylistTap;
  final void Function(LibraryPlaylist, Rect?) onPlaylistOptions;
  final void Function(LibraryFolder) onFolderTap;
  final void Function(LibraryFolder, Rect?) onFolderOptions;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return switch (entry) {
          LikedSongsEntry(:final songCount, :final onTap) => _StaticListTile(
              iconWidget: FavouriteIcon(
                isLiked: true,
                size: 28,
                gradient: AppColors.loveThemeGradientFor('liked_songs'),
              ),
              backgroundColor: AppColors.surfaceLight,
              title: 'Liked Songs',
              subtitle:
                  songCount == 0 ? 'No songs yet' : '$songCount songs',
              onTap: onTap,
            ),
          FolderEntry(:final folder) => _LibraryFolderListTile(
              folder: folder,
              onTap: () => onFolderTap(folder),
              onOptions: (rect) => onFolderOptions(folder, rect),
            ),
          PlaylistEntry(:final playlist) => _LibraryPlaylistListTile(
              playlist: playlist,
              onTap: () => onPlaylistTap(playlist),
              onOptions: (rect) => onPlaylistOptions(playlist, rect),
            ),
        };
      },
    );
  }
}

class _StaticListTile extends StatelessWidget {
  const _StaticListTile({
    this.icon,
    this.iconColor,
    this.iconWidget,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : assert(icon != null && iconColor != null || iconWidget != null);

  final List<List<dynamic>>? icon;
  final Color? iconColor;
  final Widget? iconWidget;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: iconWidget ?? AppIcon(
                    icon: icon!,
                    color: iconColor!,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryPlaylistListTile extends StatelessWidget {
  const _LibraryPlaylistListTile({
    required this.playlist,
    required this.onTap,
    required this.onOptions,
  });

  final LibraryPlaylist playlist;
  final VoidCallback onTap;
  final void Function(Rect?) onOptions;

  @override
  Widget build(BuildContext context) {
    final coverUrl =
        playlist.songs.isNotEmpty ? playlist.songs.first.thumbnailUrl : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => onOptions(null),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: coverUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: CachedNetworkImage(
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => AppIcon(
                            icon: AppIcons.musicNote,
                            color: AppColors.textMuted,
                            size: 28,
                          ),
                        ),
                      )
                    : AppIcon(
                        icon: AppIcons.musicNote,
                        color: AppColors.textMuted,
                        size: 28,
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name.capitalized,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      playlist.trackCountLabel,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (playlist.isPinned)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: AppIcon(
                    icon: AppIcons.pin,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              Builder(
                builder: (btnCtx) => IconButton(
                  icon: AppIcon(
                    icon: AppIcons.moreHoriz,
                    size: 22,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () {
                    final box = btnCtx.findRenderObject() as RenderBox?;
                    onOptions(box != null && box.hasSize
                        ? box.localToGlobal(Offset.zero) & box.size
                        : null);
                  },
                  color: AppColors.textMuted,
                  iconSize: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
