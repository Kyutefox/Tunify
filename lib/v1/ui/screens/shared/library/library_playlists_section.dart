import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:tunify/v1/core/constants/app_icons.dart';
import 'package:tunify/v1/data/models/library_folder.dart';
import 'package:tunify/v1/data/models/library_playlist.dart';
import 'package:tunify/v1/features/library/library_provider.dart';
import 'package:tunify/v1/ui/widgets/common/button.dart';
import 'package:tunify/v1/ui/widgets/library/library_item_tile.dart';
import 'package:tunify/v1/ui/theme/app_colors.dart';
import 'package:tunify/v1/ui/theme/design_tokens.dart';
import 'package:tunify/v1/ui/theme/app_tokens.dart';
import 'package:tunify/v1/core/utils/string_utils.dart';
import 'package:tunify/v1/ui/theme/app_colors_scheme.dart';

String _typedSubtitle(String type, String currentSubtitle) {
  final subtitle = currentSubtitle.trim();
  if (subtitle.isEmpty || subtitle.toLowerCase() == type.toLowerCase()) {
    return type;
  }
  return '$type • $subtitle';
}

/// Shared playlist cover thumbnail used in both list and grid views.
/// Respects [customImageUrl] first, then falls back to song art mosaic.
class PlaylistCoverThumbnail extends StatelessWidget {
  const PlaylistCoverThumbnail({
    super.key,
    required this.playlist,
    required this.size,
    this.borderRadius,
  });

  final LibraryPlaylist playlist;
  final double size;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.xs);

    if (playlist.customImageUrl != null &&
        playlist.customImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: playlist.customImageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _placeholder(context, size, radius),
        ),
      );
    }

    final songs = playlist.songs;

    // 2. No songs — placeholder
    if (songs.isEmpty) return _placeholder(context, size, radius);

    // 3. Single song — single image
    if (songs.length == 1) {
      return ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: songs.first.thumbnailUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _placeholder(context, size, radius),
        ),
      );
    }

    // 4. 2–4+ songs — 2×2 mosaic
    final urls = songs.take(4).map((s) => s.thumbnailUrl).toList();
    const gap = 1.5;
    final cell = (size - gap) / 2;

    return ClipRRect(
      borderRadius: radius,
      child: ClipRect(
        child: SizedBox(
          width: size,
          height: size,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                _cell(context, urls[0], cell),
                SizedBox(width: gap),
                _cell(context, urls.length > 1 ? urls[1] : null, cell),
              ]),
              SizedBox(height: gap),
              Row(children: [
                _cell(context, urls.length > 2 ? urls[2] : null, cell),
                SizedBox(width: gap),
                _cell(context, urls.length > 3 ? urls[3] : null, cell),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, String? url, double s) {
    if (url == null) return _placeholderCell(context, s);
    return CachedNetworkImage(
      imageUrl: url,
      width: s,
      height: s,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => _placeholderCell(context, s),
    );
  }

  Widget _placeholderCell(BuildContext context, double s) => Container(
        width: s,
        height: s,
        color: AppColorsScheme.of(context).surfaceLight,
        child: Center(
          child: AppIcon(
              icon: AppIcons.musicNote,
              color: AppColorsScheme.of(context).textMuted,
              size: s * 0.4),
        ),
      );

  Widget _placeholder(BuildContext context, double s, BorderRadius r) =>
      ClipRRect(
        borderRadius: r,
        child: Container(
          width: s,
          height: s,
          color: AppColorsScheme.of(context).surfaceLight,
          child: Center(
            child: AppIcon(
                icon: AppIcons.musicNote,
                color: AppColorsScheme.of(context).textMuted,
                size: s * 0.5),
          ),
        ),
      );
}

/// A single item in the library playlists section: Liked Songs, Downloads, a folder, or a playlist.
sealed class LibrarySectionEntry {}

class LikedSongsEntry extends LibrarySectionEntry {
  LikedSongsEntry({required this.songCount, required this.onTap});
  final int songCount;
  final VoidCallback onTap;
}

class DownloadsEntry extends LibrarySectionEntry {
  DownloadsEntry({required this.songCount, required this.onTap});
  final int songCount;
  final VoidCallback onTap;
}

class LocalFilesEntry extends LibrarySectionEntry {
  LocalFilesEntry({required this.songCount, required this.onTap});
  final int songCount;
  final VoidCallback onTap;
}

class EpisodesForLaterEntry extends LibrarySectionEntry {
  EpisodesForLaterEntry({required this.episodeCount, required this.onTap});
  final int episodeCount;
  final VoidCallback onTap;
}

class MediaLibraryEntry extends LibrarySectionEntry {
  MediaLibraryEntry({
    required this.title,
    required this.subtitle,
    required this.thumbnailUrl,
    required this.placeholderIcon,
    required this.onTap,
    this.onOptions,
    this.showPinIndicator = false,
    this.circularThumbnail = false,
    this.folderSortDate,
    this.gridDetailSubtitle,
  });

  final String title;
  final String subtitle;
  final String? thumbnailUrl;
  final List<List<dynamic>> placeholderIcon;
  final VoidCallback onTap;
  final void Function(Rect?)? onOptions;
  final bool showPinIndicator;

  /// Circular cover in grid/list (e.g. artists).
  final bool circularThumbnail;

  /// When this entry is shown inside a folder, used for sort by recent / recent add.
  final DateTime? folderSortDate;

  /// Optional second line under the title row in grid layout (e.g. album artist).
  final String? gridDetailSubtitle;
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
    this.contentPadding,
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

  /// When non-null, matches parent container insets.
  /// Defaults to symmetric [AppSpacing.base] like [LibraryAppBar] controls.
  final EdgeInsets? contentPadding;

  @override
  Widget build(BuildContext context) {
    final contentEntries = entries;
    final showCreateFirstEmptyState =
        showCreateFirstPlaylistEmptyState && contentEntries.isEmpty;
    final showFolderEmptyState = isFolderView && contentEntries.isEmpty;
    final resolvedPadding = contentPadding ??
        const EdgeInsets.symmetric(horizontal: AppSpacing.base);

    return Padding(
      padding: resolvedPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showFolderEmptyState)
            _SectionEmptyState(
              child: Text(
                'No playlists in this folder',
                style: TextStyle(
                  color: AppColorsScheme.of(context).textMuted,
                  fontSize: AppFontSize.lg,
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
                    color: AppColorsScheme.of(context)
                        .textMuted
                        .withValues(alpha: UIOpacity.emphasis),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Create your first playlist',
                    style: TextStyle(
                      color: AppColorsScheme.of(context).textSecondary,
                      fontSize: AppFontSize.lg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Tap + to get started',
                    style: TextStyle(
                      color: AppColorsScheme.of(context).textMuted,
                      fontSize: AppFontSize.md,
                    ),
                  ),
                ],
              ),
            )
          else
            AnimatedSwitcher(
              duration: AppDuration.fast,
              switchInCurve: AppCurves.decelerate,
              switchOutCurve: AppCurves.standard,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: Alignment.topCenter,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              ),
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
        color: AppColorsScheme.of(context)
            .surfaceLight
            .withValues(alpha: UIOpacity.disabled),
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
      cacheExtent: 1000,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final card = switch (entry) {
          LikedSongsEntry(:final songCount, :final onTap) => _StaticGridCard(
              iconWidget: FavouriteIcon(
                isLiked: true,
                size: 40,
                fillColor: Colors.white,
              ),
              backgroundColor: AppColorsScheme.of(context).surfaceLight,
              backgroundGradient: AppColors.loveThemeGradientFor('liked_songs'),
              title: 'Liked Songs',
              subtitle: songCount == 0 ? 'No songs yet' : '$songCount songs',
              onTap: onTap,
            ),
          DownloadsEntry(:final songCount, :final onTap) => _StaticGridCard(
              icon: AppIcons.download,
              iconColor: Colors.white,
              backgroundColor: AppColorsScheme.of(context).surfaceLight,
              backgroundGradient: AppColors.downloadGradient,
              title: 'Downloads',
              subtitle: songCount == 0 ? 'No songs yet' : '$songCount songs',
              onTap: onTap,
            ),
          LocalFilesEntry(:final songCount, :final onTap) => _StaticGridCard(
              icon: AppIcons.folder,
              iconColor: Colors.white,
              backgroundColor: AppColorsScheme.of(context).surfaceLight,
              backgroundGradient: AppColors.localFilesGradient,
              title: 'Local Files',
              subtitle: songCount == 0 ? 'No songs yet' : '$songCount songs',
              onTap: onTap,
            ),
          EpisodesForLaterEntry(:final episodeCount, :final onTap) =>
            _StaticGridCard(
              icon: AppIcons.bookmark,
              iconColor: Colors.white,
              backgroundColor: AppColorsScheme.of(context).surfaceLight,
              backgroundGradient: AppColors.episodesGradient,
              title: 'Episodes For Later',
              subtitle: episodeCount == 0
                  ? 'No episodes yet'
                  : '$episodeCount episodes',
              onTap: onTap,
            ),
          MediaLibraryEntry() => MediaLibraryGridCard(entry: entry),
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
        return _StaggeredItem(index: index, child: card);
      },
    );
  }
}

class _StaticGridCard extends StatefulWidget {
  const _StaticGridCard({
    this.icon,
    this.iconColor,
    this.iconWidget,
    required this.backgroundColor,
    this.backgroundGradient,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : assert(icon != null && iconColor != null || iconWidget != null);

  final List<List<dynamic>>? icon;
  final Color? iconColor;
  final Widget? iconWidget;
  final Color backgroundColor;
  final LinearGradient? backgroundGradient;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<_StaticGridCard> createState() => _StaticGridCardState();
}

class _StaticGridCardState extends State<_StaticGridCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: AppDuration.instant,
        curve: AppCurves.decelerate,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: widget.backgroundGradient == null
                      ? widget.backgroundColor
                      : null,
                  gradient: widget.backgroundGradient,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: widget.iconWidget ??
                      AppIcon(
                        icon: widget.icon!,
                        color: widget.iconColor!,
                        size: 40,
                      ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.title,
              style: TextStyle(
                color: AppColorsScheme.of(context).textPrimary,
                fontSize: AppFontSize.md,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.subtitle,
              style: TextStyle(
                color: AppColorsScheme.of(context).textMuted,
                fontSize: AppFontSize.xs,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryPlaylistGridCard extends StatefulWidget {
  const _LibraryPlaylistGridCard({
    required this.playlist,
    required this.onTap,
    required this.onOptions,
  });

  final LibraryPlaylist playlist;
  final VoidCallback onTap;
  final void Function(Rect?) onOptions;

  @override
  State<_LibraryPlaylistGridCard> createState() =>
      _LibraryPlaylistGridCardState();
}

class _LibraryPlaylistGridCardState extends State<_LibraryPlaylistGridCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final playlist = widget.playlist;
    final card = GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: AppDuration.instant,
        curve: AppCurves.decelerate,
        child: SizedBox.expand(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => PlaylistCoverThumbnail(
                    playlist: playlist,
                    // Grid card covers should track tile width so custom
                    // playlists don't appear narrower than other card types.
                    size: constraints.maxWidth,
                    borderRadius: BorderRadius.circular(AppRadius.md),
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
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textPrimary,
                        fontSize: AppFontSize.md,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Builder(
                    builder: (btnCtx) => GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        final box = btnCtx.findRenderObject() as RenderBox?;
                        widget.onOptions(box != null && box.hasSize
                            ? box.localToGlobal(Offset.zero) & box.size
                            : null);
                      },
                      child: AppIcon(
                        icon: AppIcons.moreVert,
                        color: AppColorsScheme.of(context).textMuted,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                _typedSubtitle('Playlist', playlist.trackCountLabel),
                style: TextStyle(
                  color: AppColorsScheme.of(context).textMuted,
                  fontSize: AppFontSize.xs,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );

    return card;
  }
}

class _LibraryFolderGridCard extends StatefulWidget {
  const _LibraryFolderGridCard({
    required this.folder,
    required this.onTap,
    required this.onOptions,
  });

  final LibraryFolder folder;
  final VoidCallback onTap;
  final void Function(Rect?) onOptions;

  @override
  State<_LibraryFolderGridCard> createState() => _LibraryFolderGridCardState();
}

class _LibraryFolderGridCardState extends State<_LibraryFolderGridCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final folder = widget.folder;
    final card = GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: AppDuration.instant,
        curve: AppCurves.decelerate,
        child: SizedBox.expand(
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
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textPrimary,
                        fontSize: AppFontSize.md,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Builder(
                    builder: (btnCtx) => GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        final box = btnCtx.findRenderObject() as RenderBox?;
                        widget.onOptions(box != null && box.hasSize
                            ? box.localToGlobal(Offset.zero) & box.size
                            : null);
                      },
                      child: AppIcon(
                        icon: AppIcons.moreVert,
                        color: AppColorsScheme.of(context).textMuted,
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
                style: TextStyle(
                  color: AppColorsScheme.of(context).textMuted,
                  fontSize: AppFontSize.xs,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return card;
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
    final thumbSize = 56.0;
    final tile = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        hoverColor: null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Container(
                width: thumbSize,
                height: thumbSize,
                decoration: BoxDecoration(
                  color: AppColorsScheme.of(context).surfaceLight,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Center(
                  child: AppIcon(
                      icon: AppIcons.folder,
                      color: AppColors.primary,
                      size: 28),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name.capitalized,
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textPrimary,
                        fontSize: AppFontSize.lg,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _typedSubtitle(
                        'Folder',
                        folder.playlistCount == 0
                            ? 'No playlists'
                            : '${folder.playlistCount} playlist${folder.playlistCount == 1 ? '' : 's'}',
                      ),
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textMuted,
                        fontSize: AppFontSize.md,
                      ),
                    ),
                  ],
                ),
              ),
              if (folder.isPinned)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: AppIcon(
                      icon: AppIcons.pin, size: 14, color: AppColors.primary),
                ),
              Builder(
                builder: (btnCtx) => AppIconButton(
                  icon: AppIcon(
                    icon: AppIcons.moreVert,
                    size: 20,
                    color: AppColorsScheme.of(context).textMuted,
                  ),
                  onPressedWithContext: (btnCtx) {
                    final box = btnCtx.findRenderObject() as RenderBox?;
                    onOptions(box != null && box.hasSize
                        ? box.localToGlobal(Offset.zero) & box.size
                        : null);
                  },
                  size: 40,
                  iconSize: 20,
                  iconAlignment: Alignment.centerRight,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return tile;
  }
}

/// Wraps a list item with a staggered fade+slide entrance animation.
/// Delay is proportional to [index] so items cascade in from top to bottom.
class _StaggeredItem extends StatelessWidget {
  const _StaggeredItem({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return child;
    final delay = Duration(milliseconds: 30 * index.clamp(0, 20));
    return child
        .animate(delay: delay)
        .fadeIn(duration: AppDuration.fast, curve: AppCurves.decelerate)
        .slideY(
            begin: 0.06,
            end: 0,
            duration: AppDuration.fast,
            curve: AppCurves.decelerate);
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
        final tile = switch (entry) {
          LikedSongsEntry(:final songCount, :final onTap) => _StaticListTile(
              iconWidget: FavouriteIcon(
                isLiked: true,
                size: 28,
                fillColor: Colors.white,
              ),
              backgroundColor: AppColorsScheme.of(context).surfaceLight,
              backgroundGradient: AppColors.loveThemeGradientFor('liked_songs'),
              title: 'Liked Songs',
              subtitle: songCount == 0 ? 'No songs yet' : '$songCount songs',
              onTap: onTap,
            ),
          DownloadsEntry(:final songCount, :final onTap) => _StaticListTile(
              icon: AppIcons.download,
              iconColor: Colors.white,
              backgroundColor: AppColorsScheme.of(context).surfaceLight,
              backgroundGradient: AppColors.downloadGradient,
              title: 'Downloads',
              subtitle: songCount == 0 ? 'No songs yet' : '$songCount songs',
              onTap: onTap,
            ),
          LocalFilesEntry(:final songCount, :final onTap) => _StaticListTile(
              icon: AppIcons.folder,
              iconColor: Colors.white,
              backgroundColor: AppColorsScheme.of(context).surfaceLight,
              backgroundGradient: AppColors.localFilesGradient,
              title: 'Local Files',
              subtitle: songCount == 0 ? 'No songs yet' : '$songCount songs',
              onTap: onTap,
            ),
          EpisodesForLaterEntry(:final episodeCount, :final onTap) =>
            _StaticListTile(
              icon: AppIcons.bookmark,
              iconColor: Colors.white,
              backgroundColor: AppColorsScheme.of(context).surfaceLight,
              backgroundGradient: AppColors.episodesGradient,
              title: 'Episodes For Later',
              subtitle: episodeCount == 0
                  ? 'No episodes yet'
                  : '$episodeCount episodes',
              onTap: onTap,
            ),
          MediaLibraryEntry() => LibraryItemTile(
              title: entry.title,
              subtitle: entry.subtitle,
              thumbnailUrl: entry.thumbnailUrl,
              placeholderIcon: entry.placeholderIcon,
              showPinIndicator: entry.showPinIndicator,
              circularThumbnail: entry.circularThumbnail,
              onTap: entry.onTap,
              onOptions: entry.onOptions,
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
        return _StaggeredItem(index: index, child: tile);
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
    this.backgroundGradient,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : assert(icon != null && iconColor != null || iconWidget != null);

  final List<List<dynamic>>? icon;
  final Color? iconColor;
  final Widget? iconWidget;
  final Color backgroundColor;
  final LinearGradient? backgroundGradient;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final thumbSize = 56.0;
    final tile = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        hoverColor: null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: t.spacing.xs),
          child: Row(
            children: [
              Container(
                width: thumbSize,
                height: thumbSize,
                decoration: BoxDecoration(
                  color: backgroundGradient == null ? backgroundColor : null,
                  gradient: backgroundGradient,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Center(
                  child: iconWidget ??
                      AppIcon(icon: icon!, color: iconColor!, size: 28),
                ),
              ),
              SizedBox(width: t.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textPrimary,
                        fontSize: AppFontSize.lg,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textMuted,
                        fontSize: AppFontSize.md,
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

    return tile;
  }
}

class MediaLibraryGridCard extends StatelessWidget {
  const MediaLibraryGridCard({super.key, required this.entry});

  final MediaLibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    final mediaChild =
        entry.thumbnailUrl != null && entry.thumbnailUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: entry.thumbnailUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: AppColorsScheme.of(context).surfaceLight,
                  child: Center(
                    child: AppIcon(
                      icon: entry.placeholderIcon,
                      color: AppColorsScheme.of(context).textMuted,
                      size: 36,
                    ),
                  ),
                ),
              )
            : Container(
                color: AppColorsScheme.of(context).surfaceLight,
                child: Center(
                  child: AppIcon(
                    icon: entry.placeholderIcon,
                    color: AppColorsScheme.of(context).textMuted,
                    size: 36,
                  ),
                ),
              );

    final detailLine = entry.gridDetailSubtitle ?? entry.subtitle;

    return GestureDetector(
      onTap: entry.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: entry.circularThumbnail
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final side = constraints.maxWidth < constraints.maxHeight
                          ? constraints.maxWidth
                          : constraints.maxHeight;
                      return Center(
                        child: ClipOval(
                          child: SizedBox(
                            width: side,
                            height: side,
                            child: entry.thumbnailUrl != null &&
                                    entry.thumbnailUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: entry.thumbnailUrl!,
                                    width: side,
                                    height: side,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      color: AppColorsScheme.of(context)
                                          .surfaceLight,
                                      child: Center(
                                        child: AppIcon(
                                          icon: entry.placeholderIcon,
                                          color: AppColorsScheme.of(context)
                                              .textMuted,
                                          size: 36,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: AppColorsScheme.of(context)
                                        .surfaceLight,
                                    child: Center(
                                      child: AppIcon(
                                        icon: entry.placeholderIcon,
                                        color: AppColorsScheme.of(context)
                                            .textMuted,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: mediaChild,
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColorsScheme.of(context).textPrimary,
                    fontSize: AppFontSize.md,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (entry.showPinIndicator)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: AppIcon(
                    icon: AppIcons.pin,
                    size: 12,
                    color: AppColors.primary,
                  ),
                ),
              if (entry.onOptions != null)
                Builder(
                  builder: (btnCtx) => GestureDetector(
                    onTap: () {
                      final box = btnCtx.findRenderObject() as RenderBox?;
                      entry.onOptions!(
                        box != null && box.hasSize
                            ? box.localToGlobal(Offset.zero) & box.size
                            : null,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: AppIcon(
                        icon: AppIcons.moreVert,
                        size: 18,
                        color: AppColorsScheme.of(context).textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Text(
            detailLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColorsScheme.of(context).textMuted,
              fontSize: AppFontSize.xs,
            ),
          ),
        ],
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
    final t = AppTokens.of(context);
    final thumbSize = 56.0;
    final tile = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        hoverColor: null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: t.spacing.xs),
          child: Row(
            children: [
              PlaylistCoverThumbnail(playlist: playlist, size: thumbSize),
              SizedBox(width: t.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name.capitalized,
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textPrimary,
                        fontSize: AppFontSize.lg,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _typedSubtitle('Playlist', playlist.trackCountLabel),
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textMuted,
                        fontSize: AppFontSize.md,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (playlist.isPinned)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: AppIcon(
                      icon: AppIcons.pin, size: 14, color: AppColors.primary),
                ),
              Builder(
                builder: (btnCtx) => AppIconButton(
                  icon: AppIcon(
                    icon: AppIcons.moreVert,
                    size: 20,
                    color: AppColorsScheme.of(context).textMuted,
                  ),
                  onPressedWithContext: (btnCtx) {
                    final box = btnCtx.findRenderObject() as RenderBox?;
                    onOptions(box != null && box.hasSize
                        ? box.localToGlobal(Offset.zero) & box.size
                        : null);
                  },
                  size: 40,
                  iconSize: 20,
                  iconAlignment: Alignment.centerRight,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return tile;
  }
}

// ── Library skeleton ─────────────────────────────────────────────────────────

/// Shimmer placeholder list shown while the library is loading from SQLite.
class LibrarySkeletonList extends StatelessWidget {
  const LibrarySkeletonList({
    super.key,
    this.itemCount = 8,
    this.viewMode = LibraryViewMode.list,
  });
  final int itemCount;
  final LibraryViewMode viewMode;

  @override
  Widget build(BuildContext context) {
    final entries = _fakeSkeletonEntries(itemCount);
    final child = viewMode == LibraryViewMode.grid
        ? _LibrarySectionGrid(
            entries: entries,
            onPlaylistTap: (_) {},
            onPlaylistOptions: (_, __) {},
            onFolderTap: (_) {},
            onFolderOptions: (_, __) {},
          )
        : _LibrarySectionList(
            entries: entries,
            onPlaylistTap: (_) {},
            onPlaylistOptions: (_, __) {},
            onFolderTap: (_) {},
            onFolderOptions: (_, __) {},
          );
    return Skeletonizer(
      enabled: true,
      child: IgnorePointer(
        child: child,
      ),
    );
  }
}

List<LibrarySectionEntry> _fakeSkeletonEntries(int count) {
  final now = DateTime.now();
  return List.generate(count, (i) {
    if (i % 4 == 0) {
      return FolderEntry(
        LibraryFolder(
          id: 'skeleton-folder-$i',
          name: 'Loading folder',
          createdAt: now,
          playlistIds: const ['a', 'b'],
        ),
      );
    }
    return PlaylistEntry(
      LibraryPlaylist(
        id: 'skeleton-playlist-$i',
        name: 'Loading playlist',
        createdAt: now,
        updatedAt: now,
        remoteTrackCount: 12,
        isImported: true,
      ),
    );
  });
}
