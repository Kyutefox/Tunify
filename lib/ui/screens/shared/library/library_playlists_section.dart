import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:tunify/ui/screens/shared/home/home_shared.dart' show SkeletonBox;

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/library_folder.dart';
import 'package:tunify/data/models/library_playlist.dart';
import 'package:tunify/features/library/library_provider.dart';
import 'package:tunify/ui/widgets/common/button.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/desktop_tokens.dart';
import 'package:tunify/core/utils/string_utils.dart';

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
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.sm);

    // 1. Custom image (e.g. saved from a remote playlist)
    if (playlist.customImageUrl != null &&
        playlist.customImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: playlist.customImageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _placeholder(size, radius),
        ),
      );
    }

    final songs = playlist.songs;

    // 2. No songs — placeholder
    if (songs.isEmpty) return _placeholder(size, radius);

    // 3. Single song — single image
    if (songs.length == 1) {
      return ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: songs.first.thumbnailUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _placeholder(size, radius),
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
                _cell(urls[0], cell),
                SizedBox(width: gap),
                _cell(urls.length > 1 ? urls[1] : null, cell),
              ]),
              SizedBox(height: gap),
              Row(children: [
                _cell(urls.length > 2 ? urls[2] : null, cell),
                SizedBox(width: gap),
                _cell(urls.length > 3 ? urls[3] : null, cell),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(String? url, double s) {
    if (url == null) return _placeholderCell(s);
    return CachedNetworkImage(
      imageUrl: url,
      width: s,
      height: s,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => _placeholderCell(s),
    );
  }

  Widget _placeholderCell(double s) => Container(
        width: s,
        height: s,
        color: AppColors.surfaceLight,
        child: Center(
          child: AppIcon(
              icon: AppIcons.musicNote,
              color: AppColors.textMuted,
              size: s * 0.4),
        ),
      );

  Widget _placeholder(double s, BorderRadius r) => ClipRRect(
        borderRadius: r,
        child: Container(
          width: s,
          height: s,
          color: AppColors.surfaceLight,
          child: Center(
            child: AppIcon(
                icon: AppIcons.musicNote,
                color: AppColors.textMuted,
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
    this.isSelecting = false,
    this.selectedIds = const {},
    this.onLongPress,
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

  /// Bulk-select state.
  final bool isSelecting;
  final Set<String> selectedIds;

  /// Called on long-press with the item id to enter select mode.
  final void Function(String id)? onLongPress;

  @override
  Widget build(BuildContext context) {
    final contentEntries = entries;
    final showCreateFirstEmptyState =
        showCreateFirstPlaylistEmptyState && contentEntries.isEmpty;
    final showFolderEmptyState = isFolderView && contentEntries.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showFolderEmptyState)
            _SectionEmptyState(
              child: Text(
                'No playlists in this folder',
                style: TextStyle(
                  color: AppColors.textMuted,
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
                    color: AppColors.textMuted.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Create your first playlist',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppFontSize.lg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Tap + to get started',
                    style: TextStyle(
                      color: AppColors.textMuted,
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
                        isSelecting: isSelecting,
                        selectedIds: selectedIds,
                        onLongPress: onLongPress,
                      )
                    : _LibrarySectionList(
                        entries: contentEntries,
                        onPlaylistTap: onPlaylistTap,
                        onPlaylistOptions: onPlaylistOptions,
                        onFolderTap: onFolderTap,
                        onFolderOptions: onFolderOptions,
                        isSelecting: isSelecting,
                        selectedIds: selectedIds,
                        onLongPress: onLongPress,
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
    this.isSelecting = false,
    this.selectedIds = const {},
    this.onLongPress,
  });

  final List<LibrarySectionEntry> entries;
  final void Function(LibraryPlaylist) onPlaylistTap;
  final void Function(LibraryPlaylist, Rect?) onPlaylistOptions;
  final void Function(LibraryFolder) onFolderTap;
  final void Function(LibraryFolder, Rect?) onFolderOptions;
  final bool isSelecting;
  final Set<String> selectedIds;
  final void Function(String id)? onLongPress;

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
              backgroundColor: AppColors.surfaceLight,
              backgroundGradient: AppColors.loveThemeGradientFor('liked_songs'),
              title: 'Liked Songs',
              subtitle: songCount == 0 ? 'No songs yet' : '$songCount songs',
              onTap: onTap,
            ),
          DownloadsEntry(:final songCount, :final onTap) => _StaticGridCard(
              icon: AppIcons.download,
              iconColor: Colors.white,
              backgroundColor: AppColors.surfaceLight,
              backgroundGradient: AppColors.downloadGradient,
              title: 'Downloads',
              subtitle: songCount == 0 ? 'No songs yet' : '$songCount songs',
              onTap: onTap,
            ),
          LocalFilesEntry(:final songCount, :final onTap) => _StaticGridCard(
              icon: AppIcons.folder,
              iconColor: Colors.white,
              backgroundColor: AppColors.surfaceLight,
              backgroundGradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF9F43), Color(0xFFFF6B35)],
              ),
              title: 'Local Files',
              subtitle: songCount == 0 ? 'No songs yet' : '$songCount songs',
              onTap: onTap,
            ),
          FolderEntry(:final folder) => _LibraryFolderGridCard(
              folder: folder,
              onTap: () => onFolderTap(folder),
              onOptions: (rect) => onFolderOptions(folder, rect),
              isSelected: selectedIds.contains(folder.id),
              isSelecting: isSelecting,
              onLongPress: onLongPress != null ? () => onLongPress!(folder.id) : null,
            ),
          PlaylistEntry(:final playlist) => _LibraryPlaylistGridCard(
              playlist: playlist,
              onTap: () => onPlaylistTap(playlist),
              onOptions: (rect) => onPlaylistOptions(playlist, rect),
              isSelected: selectedIds.contains(playlist.id),
              isSelecting: isSelecting,
              onLongPress: onLongPress != null ? () => onLongPress!(playlist.id) : null,
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
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
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
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppFontSize.md,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.subtitle,
              style: const TextStyle(
                color: AppColors.textMuted,
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
    this.isSelected = false,
    this.isSelecting = false,
    this.onLongPress,
  });

  final LibraryPlaylist playlist;
  final VoidCallback onTap;
  final void Function(Rect?) onOptions;
  final bool isSelected;
  final bool isSelecting;
  final VoidCallback? onLongPress;

  @override
  State<_LibraryPlaylistGridCard> createState() =>
      _LibraryPlaylistGridCardState();
}

class _LibraryPlaylistGridCardState extends State<_LibraryPlaylistGridCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final playlist = widget.playlist;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onLongPress: () {
        if (widget.onLongPress != null) {
          widget.onLongPress!();
        } else {
          HapticFeedback.mediumImpact();
          widget.onOptions(null);
        }
      },
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => PlaylistCoverThumbnail(
                      playlist: playlist,
                      size: constraints.maxHeight.isFinite
                          ? constraints.maxHeight
                          : constraints.maxWidth,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    if (!widget.isSelecting && playlist.isPinned)
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
                          fontSize: AppFontSize.md,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!widget.isSelecting)
                      Builder(
                        builder: (btnCtx) => GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            final box =
                                btnCtx.findRenderObject() as RenderBox?;
                            widget.onOptions(box != null && box.hasSize
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
                    fontSize: AppFontSize.xs,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (widget.isSelecting)
              Positioned(
                top: 6,
                right: 6,
                child: AnimatedSwitcher(
                  duration: AppDuration.fast,
                  child: Icon(
                    widget.isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    key: ValueKey(widget.isSelected),
                    size: 22,
                    color: widget.isSelected
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.8),
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 4),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LibraryFolderGridCard extends StatefulWidget {
  const _LibraryFolderGridCard({
    required this.folder,
    required this.onTap,
    required this.onOptions,
    this.isSelected = false,
    this.isSelecting = false,
    this.onLongPress,
  });

  final LibraryFolder folder;
  final VoidCallback onTap;
  final void Function(Rect?) onOptions;
  final bool isSelected;
  final bool isSelecting;
  final VoidCallback? onLongPress;

  @override
  State<_LibraryFolderGridCard> createState() => _LibraryFolderGridCardState();
}

class _LibraryFolderGridCardState extends State<_LibraryFolderGridCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final folder = widget.folder;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onLongPress: () {
        if (widget.onLongPress != null) {
          widget.onLongPress!();
        } else {
          HapticFeedback.mediumImpact();
          widget.onOptions(null);
        }
      },
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Stack(
          children: [
            Column(
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
                    if (!widget.isSelecting && folder.isPinned)
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
                          fontSize: AppFontSize.md,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!widget.isSelecting)
                      Builder(
                        builder: (btnCtx) => GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            final box =
                                btnCtx.findRenderObject() as RenderBox?;
                            widget.onOptions(box != null && box.hasSize
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
                    fontSize: AppFontSize.xs,
                  ),
                ),
              ],
            ),
            if (widget.isSelecting)
              Positioned(
                top: 6,
                right: 6,
                child: AnimatedSwitcher(
                  duration: AppDuration.fast,
                  child: Icon(
                    widget.isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    key: ValueKey(widget.isSelected),
                    size: 22,
                    color: widget.isSelected
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.8),
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 4),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LibraryFolderListTile extends StatelessWidget {
  const _LibraryFolderListTile({
    required this.folder,
    required this.onTap,
    required this.onOptions,
    this.isSelected = false,
    this.isSelecting = false,
    this.onLongPress,
  });

  final LibraryFolder folder;
  final VoidCallback onTap;
  final void Function(Rect?) onOptions;
  final bool isSelected;
  final bool isSelecting;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final thumbSize = t.isDesktop ? 44.0 : 52.0;
    final tile = Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        onLongPress: () {
          if (onLongPress != null) {
            onLongPress!();
          } else {
            HapticFeedback.mediumImpact();
            onOptions(null);
          }
        },
        hoverColor: t.isDesktop ? Colors.transparent : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              if (isSelecting)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: AnimatedSwitcher(
                    duration: AppDuration.fast,
                    child: Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      key: ValueKey(isSelected),
                      size: 22,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              Container(
                width: thumbSize,
                height: thumbSize,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
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
                        color: AppColors.textPrimary,
                        fontSize: AppFontSize.lg,
                        fontWeight:
                            t.isDesktop ? FontWeight.w700 : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      folder.playlistCount == 0
                          ? 'No playlists'
                          : '${folder.playlistCount} playlist${folder.playlistCount == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: AppFontSize.md,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isSelecting) ...[
                if (folder.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: AppIcon(
                        icon: AppIcons.pin, size: 14, color: AppColors.primary),
                  ),
                Builder(
                  builder: (btnCtx) => AppIconButton(
                    icon: AppIcon(
                        icon: AppIcons.moreHoriz,
                        size: 22,
                        color: AppColors.textMuted),
                    onPressedWithContext: (btnCtx) {
                      final box = btnCtx.findRenderObject() as RenderBox?;
                      onOptions(box != null && box.hasSize
                          ? box.localToGlobal(Offset.zero) & box.size
                          : null);
                    },
                    size: 40,
                    iconSize: 22,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (t.isDesktop) return _LibraryHoverTile(child: tile);
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
        .fadeIn(duration: const Duration(milliseconds: 220), curve: Curves.easeOut)
        .slideY(begin: 0.06, end: 0, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
  }
}

class _LibrarySectionList extends StatelessWidget {
  const _LibrarySectionList({
    required this.entries,
    required this.onPlaylistTap,
    required this.onPlaylistOptions,
    required this.onFolderTap,
    required this.onFolderOptions,
    this.isSelecting = false,
    this.selectedIds = const {},
    this.onLongPress,
  });

  final List<LibrarySectionEntry> entries;
  final void Function(LibraryPlaylist) onPlaylistTap;
  final void Function(LibraryPlaylist, Rect?) onPlaylistOptions;
  final void Function(LibraryFolder) onFolderTap;
  final void Function(LibraryFolder, Rect?) onFolderOptions;
  final bool isSelecting;
  final Set<String> selectedIds;
  final void Function(String id)? onLongPress;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (context, __) {
        final t = AppTokens.of(context);
        return SizedBox(height: t.isDesktop ? AppSpacing.sm : AppSpacing.xs);
      },
      itemBuilder: (context, index) {
        final entry = entries[index];
        final tile = switch (entry) {
          LikedSongsEntry(:final songCount, :final onTap) => _StaticListTile(
              iconWidget: FavouriteIcon(
                isLiked: true,
                size: 28,
                fillColor: Colors.white,
              ),
              backgroundColor: AppColors.surfaceLight,
              backgroundGradient: AppColors.loveThemeGradientFor('liked_songs'),
              title: 'Liked Songs',
              subtitle: songCount == 0 ? 'No songs yet' : '$songCount songs',
              onTap: onTap,
            ),
          DownloadsEntry(:final songCount, :final onTap) => _StaticListTile(
              icon: AppIcons.download,
              iconColor: Colors.white,
              backgroundColor: AppColors.surfaceLight,
              backgroundGradient: AppColors.downloadGradient,
              title: 'Downloads',
              subtitle: songCount == 0 ? 'No songs yet' : '$songCount songs',
              onTap: onTap,
            ),
          LocalFilesEntry(:final songCount, :final onTap) => _StaticListTile(
              icon: AppIcons.folder,
              iconColor: Colors.white,
              backgroundColor: AppColors.surfaceLight,
              backgroundGradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF9F43), Color(0xFFFF6B35)],
              ),
              title: 'Local Files',
              subtitle: songCount == 0 ? 'No songs yet' : '$songCount songs',
              onTap: onTap,
            ),
          FolderEntry(:final folder) => _LibraryFolderListTile(
              folder: folder,
              onTap: () => onFolderTap(folder),
              onOptions: (rect) => onFolderOptions(folder, rect),
              isSelected: selectedIds.contains(folder.id),
              isSelecting: isSelecting,
              onLongPress: onLongPress != null ? () => onLongPress!(folder.id) : null,
            ),
          PlaylistEntry(:final playlist) => _LibraryPlaylistListTile(
              playlist: playlist,
              onTap: () => onPlaylistTap(playlist),
              onOptions: (rect) => onPlaylistOptions(playlist, rect),
              isSelected: selectedIds.contains(playlist.id),
              isSelecting: isSelecting,
              onLongPress: onLongPress != null ? () => onLongPress!(playlist.id) : null,
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
    final thumbSize = t.isDesktop ? 44.0 : 52.0;
    final tile = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        hoverColor: t.isDesktop ? Colors.transparent : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
          child: Row(
            children: [
              Container(
                width: thumbSize,
                height: thumbSize,
                decoration: BoxDecoration(
                  color: backgroundGradient == null ? backgroundColor : null,
                  gradient: backgroundGradient,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
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
                        color: AppColors.textPrimary,
                        fontSize: AppFontSize.lg,
                        fontWeight:
                            t.isDesktop ? FontWeight.w700 : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textMuted,
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

    if (t.isDesktop) return _LibraryHoverTile(child: tile);
    return tile;
  }
}

class _LibraryPlaylistListTile extends StatelessWidget {
  const _LibraryPlaylistListTile({
    required this.playlist,
    required this.onTap,
    required this.onOptions,
    this.isSelected = false,
    this.isSelecting = false,
    this.onLongPress,
  });

  final LibraryPlaylist playlist;
  final VoidCallback onTap;
  final void Function(Rect?) onOptions;
  final bool isSelected;
  final bool isSelecting;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final thumbSize = t.isDesktop ? 44.0 : 52.0;
    final tile = Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        onLongPress: () {
          if (onLongPress != null) {
            onLongPress!();
          } else {
            HapticFeedback.mediumImpact();
            onOptions(null);
          }
        },
        hoverColor: t.isDesktop ? Colors.transparent : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
          child: Row(
            children: [
              if (isSelecting)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: AnimatedSwitcher(
                    duration: AppDuration.fast,
                    child: Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      key: ValueKey(isSelected),
                      size: 22,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              PlaylistCoverThumbnail(playlist: playlist, size: thumbSize),
              SizedBox(width: t.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name.capitalized,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: AppFontSize.lg,
                        fontWeight:
                            t.isDesktop ? FontWeight.w700 : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      playlist.trackCountLabel,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: AppFontSize.md,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isSelecting) ...[
                if (playlist.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: AppIcon(
                        icon: AppIcons.pin, size: 14, color: AppColors.primary),
                  ),
                Builder(
                  builder: (btnCtx) => AppIconButton(
                    icon: AppIcon(
                        icon: AppIcons.moreHoriz,
                        size: 22,
                        color: AppColors.textMuted),
                    onPressedWithContext: (btnCtx) {
                      final box = btnCtx.findRenderObject() as RenderBox?;
                      onOptions(box != null && box.hasSize
                          ? box.localToGlobal(Offset.zero) & box.size
                          : null);
                    },
                    size: 40,
                    iconSize: 22,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (t.isDesktop) return _LibraryHoverTile(child: tile);
    return tile;
  }
}

/// Hover highlight wrapper for desktop library list tiles.
class _LibraryHoverTile extends StatefulWidget {
  const _LibraryHoverTile({required this.child});
  final Widget child;

  @override
  State<_LibraryHoverTile> createState() => _LibraryHoverTileState();
}

class _LibraryHoverTileState extends State<_LibraryHoverTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.hoverOverlay : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: widget.child,
      ),
    );
  }
}

// ── Library skeleton ─────────────────────────────────────────────────────────

/// Shimmer placeholder list shown while the library is loading from SQLite.
class LibrarySkeletonList extends StatelessWidget {
  const LibrarySkeletonList({super.key, this.itemCount = 8});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (_, index) => _LibrarySkeletonTile(index: index),
    );
  }
}

class _LibrarySkeletonTile extends StatelessWidget {
  const _LibrarySkeletonTile({required this.index});
  final int index;

  // Vary title widths so the skeleton looks natural.
  static const _titleWidths = [130.0, 160.0, 110.0, 145.0, 125.0, 155.0, 120.0, 140.0];

  @override
  Widget build(BuildContext context) {
    final titleWidth = _titleWidths[index % _titleWidths.length];
    const thumbSize = 52.0;
    final delay = Duration(milliseconds: 40 * index.clamp(0, 12));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          SkeletonBox(width: thumbSize, height: thumbSize, radius: AppRadius.sm),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: titleWidth, height: 13, radius: AppRadius.xs),
              const SizedBox(height: AppSpacing.xs),
              SkeletonBox(width: 70, height: 10, radius: AppRadius.xs),
            ],
          ),
        ],
      ),
    )
        .animate(
          delay: delay,
          onPlay: (c) => c.repeat(),
        )
        .shimmer(
          duration: const Duration(milliseconds: 1400),
          color: AppColors.surfaceHighlight,
          curve: Curves.easeInOut,
        );
  }
}
