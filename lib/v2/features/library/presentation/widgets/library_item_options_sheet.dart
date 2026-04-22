import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_collection_catalog.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_layout.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_strings.dart';
import 'package:tunify/v2/features/library/presentation/library_track_like_sheet_actions.dart';
import 'package:tunify/v2/features/library/presentation/library_track_playlist_sheet_actions.dart';
import 'package:tunify/v2/features/library/presentation/providers/library_providers.dart';
import 'package:tunify/v2/features/library/presentation/widgets/add_to_folder_sheet.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_collection_artwork.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_pin_toggle_row.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_item_sheet_quick_actions.dart';
import 'package:tunify/v2/features/library/presentation/screens/library_details_screen.dart';
import 'package:tunify/v2/features/library/presentation/widgets/save_track_to_playlist_sheet.dart';

part 'library_item_options_sheet.part_widgets.dart';

enum _SheetKind { item, track }

List<_OptionAction> _libraryItemOptionsSecondaryActions(
  LibraryItem item, {
  required LibraryItemSheetQuickRowKind quickKind,
}) {
  final actions = <_OptionAction>[];
  final useQuickRow = quickKind != LibraryItemSheetQuickRowKind.none;
  final isStaticSystemPlaylist =
      item.systemArtwork == SystemArtworkType.likedSongs ||
          item.systemArtwork == SystemArtworkType.yourEpisodes;
  final omitShare = item.isEphemeralHomeTrackShelf || isStaticSystemPlaylist;
  final omitTunifyCode = isStaticSystemPlaylist;

  if (!useQuickRow) {
    if (!omitShare) {
      actions.add(_OptionAction(icon: AppIcons.share, label: 'Share'));
    }
    actions.add(_OptionAction(icon: AppIcons.download, label: 'Download'));
  } else if (quickKind != LibraryItemSheetQuickRowKind.remoteCollection &&
      quickKind != LibraryItemSheetQuickRowKind.ephemeralHomeTrackShelf) {
    actions.add(_OptionAction(icon: AppIcons.share, label: 'Share'));
  }

  actions.add(_OptionAction(icon: AppIcons.queueMusic, label: 'Add to Queue'));

  if (item.kind != LibraryItemKind.playlist && !isStaticSystemPlaylist) {
    actions.add(
      _OptionAction(icon: AppIcons.playlistAddIcon, label: 'Add to playlist'),
    );
  }

  if (!omitTunifyCode) {
    actions.add(
      _OptionAction(icon: AppIcons.equalizer, label: 'Show Tunify Code'),
    );
  }
  return actions;
}

void _showItemOptionsSheet(
  BuildContext context,
  LibraryItem item, {
  String? libraryListScopeFolderId,
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
    builder: (_) => _LibraryOptionsSheet.item(
      hostContext: context,
      item: item,
      libraryListScopeFolderId: libraryListScopeFolderId,
    ),
  );
}

void _showTrackOptionsSheet(
  BuildContext context,
  LibraryDetailsModel details,
  LibraryDetailsTrack track,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.bottomSheetSurface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppBorderRadius.comfortable),
      ),
    ),
    builder: (_) => _LibraryOptionsSheet.track(
      hostContext: context,
      details: details,
      track: track,
    ),
  );
}

/// More options for a library tile (list, grid, home, detail dock).
void showLibraryItemOptionsSheet(
  BuildContext context,
  LibraryItem item, {
  String? libraryListScopeFolderId,
}) {
  _showItemOptionsSheet(
    context,
    item,
    libraryListScopeFolderId: libraryListScopeFolderId,
  );
}

/// Same sheet chrome and list rows as [showLibraryItemOptionsSheet], opened from a
/// collection **track** row (different first-row quick actions only).
void showLibraryItemOptionsSheetForTrack(
  BuildContext context,
  LibraryDetailsModel details,
  LibraryDetailsTrack track,
) {
  _showTrackOptionsSheet(context, details, track);
}

class _LibraryOptionsSheet extends ConsumerStatefulWidget {
  const _LibraryOptionsSheet.item({
    required this.hostContext,
    required this.item,
    this.libraryListScopeFolderId,
  })  : kind = _SheetKind.item,
        details = null,
        track = null;

  const _LibraryOptionsSheet.track({
    required this.hostContext,
    required this.details,
    required this.track,
  })  : kind = _SheetKind.track,
        item = null,
        libraryListScopeFolderId = null;

  final BuildContext hostContext;
  final _SheetKind kind;
  final LibraryItem? item;
  final String? libraryListScopeFolderId;
  final LibraryDetailsModel? details;
  final LibraryDetailsTrack? track;

  @override
  ConsumerState<_LibraryOptionsSheet> createState() =>
      _LibraryOptionsSheetState();
}

class _LibraryOptionsSheetState extends ConsumerState<_LibraryOptionsSheet> {
  bool _playlistBusy = false;
  bool _likeBusy = false;

  String get _videoId => (widget.track?.videoId ?? '').trim();

  bool get _hasVideoId => _videoId.isNotEmpty;

  bool get _userOwnedPlaylist =>
      widget.details?.item.isUserOwnedPlaylist ?? false;

  Future<void> _removeFromPlaylist() async {
    if (!_userOwnedPlaylist || !_hasVideoId || _playlistBusy) {
      return;
    }
    final track = widget.track!;
    final details = widget.details!;
    final go = await showDialog<bool>(
      context: widget.hostContext,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.midCard,
        title: Text(
          LibraryStrings.trackRemoveFromPlaylistTitle,
          style: AppTextStyles.featureHeading,
        ),
        content: Text(
          LibraryStrings.trackRemoveFromPlaylistBody(track.title),
          style: AppTextStyles.caption,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(LibraryStrings.trackRemoveFromPlaylistConfirm),
          ),
        ],
      ),
    );
    if (go != true || !mounted) {
      return;
    }
    setState(() => _playlistBusy = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await LibraryTrackPlaylistSheetActions.removeTrackFromUserPlaylist(
        ref: ref,
        playlistId: details.item.id,
        trackId: _videoId,
        detailsItem: details.item,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      messenger?.showSnackBar(
        const SnackBar(content: Text(LibraryStrings.trackRemovedFromPlaylist)),
      );
    } on Object catch (_) {
      messenger?.showSnackBar(
        const SnackBar(
            content: Text(LibraryStrings.trackRemoveFromPlaylistFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _playlistBusy = false);
      }
    }
  }

  void _addToUserPlaylist() {
    if (!_hasVideoId) {
      return;
    }
    final track = widget.track!;
    final details = widget.details!;
    final exclude = details.item.isUserOwnedPlaylist ? details.item.id : null;
    Navigator.of(context).pop();
    showSaveTrackToPlaylistSheet(
      context: widget.hostContext,
      ref: ref,
      track: track,
      sourceCollectionItem: details.item,
      excludePlaylistId: exclude,
    );
  }

  List<_OptionAction> _trackSecondaryActions() {
    final track = widget.track!;
    final details = widget.details!;
    final isPodcastContext = details.item.kind == LibraryItemKind.podcast ||
        details.item.kind == LibraryItemKind.episode;
    final artistBrowseIds = _orderedArtistBrowseIds(track);
    final hasArtistTarget = !isPodcastContext && artistBrowseIds.isNotEmpty;
    final hasAlbumTarget =
        !isPodcastContext && (track.albumBrowseId?.trim().isNotEmpty ?? false);
    return [
      _OptionAction(icon: AppIcons.share, label: 'Share'),
      _OptionAction(
        icon: AppIcons.playlistAddIcon,
        label: LibraryStrings.trackAddToPlaylistSheetTitle,
        customTap: _openSaveToPlaylistSheetFromTrack,
      ),
      if (hasArtistTarget)
        _OptionAction(
          icon: AppIcons.personOutline,
          label: 'Go to Artist',
          customTap: _openTrackArtist,
        ),
      if (hasAlbumTarget)
        _OptionAction(
          icon: AppIcons.album,
          label: 'Go to Album',
          customTap: _openTrackAlbum,
        ),
      _OptionAction(icon: AppIcons.queueMusic, label: 'Add to Queue'),
      _OptionAction(icon: AppIcons.equalizer, label: 'Show Tunify Code'),
    ];
  }

  void _openTrackArtist() {
    final track = widget.track!;
    final artistBrowseIds = _orderedArtistBrowseIds(track);
    if (artistBrowseIds.isEmpty) {
      return;
    }
    if (artistBrowseIds.length == 1) {
      _openArtistByBrowseId(track, artistBrowseIds.first);
      return;
    }
    _openArtistPicker(track, artistBrowseIds);
  }

  List<String> _orderedArtistBrowseIds(LibraryDetailsTrack track) {
    final ordered = <String>[];
    for (final id in track.artistBrowseIds) {
      final t = id.trim();
      if (t.isNotEmpty && !ordered.contains(t)) {
        ordered.add(t);
      }
    }
    final primary = track.artistBrowseId?.trim();
    if (primary != null && primary.isNotEmpty && !ordered.contains(primary)) {
      ordered.insert(0, primary);
    }
    return ordered;
  }

  Future<void> _openArtistPicker(
    LibraryDetailsTrack track,
    List<String> artistBrowseIds,
  ) async {
    Navigator.of(context).pop();
    final selected = await showModalBottomSheet<String>(
      context: widget.hostContext,
      backgroundColor: AppColors.bottomSheetSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.comfortable),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            const _SheetDragHandle(),
            const SizedBox(height: AppSpacing.sm),
            Text('Choose Artist', style: AppTextStyles.bodyBold),
            const SizedBox(height: AppSpacing.sm),
            ...artistBrowseIds.asMap().entries.map(
                  (entry) => _OptionRow(
                    icon: AppIcons.personOutline,
                    label: _artistLabelForIndex(track, entry.key),
                    onTap: () => Navigator.of(sheetContext).pop(entry.value),
                  ),
                ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
    if (selected == null || selected.trim().isEmpty) {
      return;
    }
    _openArtistByBrowseId(track, selected.trim());
  }

  String _artistLabelForIndex(LibraryDetailsTrack track, int index) {
    final subtitleChunks = track.subtitle
        .split('•')
        .first
        .split(RegExp(r',|&'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    if (index < subtitleChunks.length) {
      return subtitleChunks[index];
    }
    return track.primaryArtistName?.trim().isNotEmpty == true
        ? track.primaryArtistName!.trim()
        : 'Artist ${index + 1}';
  }

  void _openArtistByBrowseId(LibraryDetailsTrack track, String browseId) {
    Navigator.of(widget.hostContext).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LibraryDetailsScreen(
          item: LibraryItem(
            id: browseId,
            title: (track.primaryArtistName?.trim().isNotEmpty ?? false)
                ? track.primaryArtistName!.trim()
                : track.subtitle,
            subtitle: 'Artist',
            kind: LibraryItemKind.artist,
            imageUrl: track.thumbUrl,
            ytmBrowseId: browseId,
          ),
        ),
      ),
    );
  }

  void _openTrackAlbum() {
    final track = widget.track!;
    final browseId = track.albumBrowseId?.trim() ?? '';
    if (browseId.isEmpty) {
      return;
    }
    Navigator.of(context).pop();
    Navigator.of(widget.hostContext).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LibraryDetailsScreen(
          item: LibraryItem(
            id: browseId,
            title: (track.albumName?.trim().isNotEmpty ?? false)
                ? track.albumName!.trim()
                : track.title,
            subtitle: 'Album',
            kind: LibraryItemKind.album,
            ytmBrowseId: browseId,
          ),
        ),
      ),
    );
  }

  void _openSaveToPlaylistSheetFromTrack() {
    if (!_hasVideoId) {
      return;
    }
    final details = widget.details!;
    final exclude = details.item.isUserOwnedPlaylist ? details.item.id : null;
    Navigator.of(context).pop();
    showSaveTrackToPlaylistSheet(
      context: widget.hostContext,
      ref: ref,
      track: widget.track!,
      sourceCollectionItem: details.item,
      excludePlaylistId: exclude,
    );
  }

  Future<void> _onTrackLikeTap(
    LibraryItem likedPlaylistItem,
    bool currentlyLiked,
  ) async {
    if (!_hasVideoId || _likeBusy) {
      return;
    }
    setState(() => _likeBusy = true);
    final messenger = ScaffoldMessenger.maybeOf(widget.hostContext);
    try {
      await LibraryTrackLikeSheetActions.setTrackLiked(
        ref: ref,
        liked: !currentlyLiked,
        videoId: _videoId,
        track: widget.track!,
        likedPlaylistItem: likedPlaylistItem,
        currentDetailsItem: widget.details!.item,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } on Object catch (_) {
      messenger?.showSnackBar(
        const SnackBar(content: Text(LibraryStrings.trackLikeUpdateFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _likeBusy = false);
      }
    }
  }

  void _onTrackPlaylistTap() {
    if (_playlistBusy || !_hasVideoId) {
      return;
    }
    if (_userOwnedPlaylist) {
      _removeFromPlaylist();
    } else {
      _addToUserPlaylist();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.kind == _SheetKind.track) {
      return _buildTrackBody(context);
    }
    return _buildItemBody(context);
  }

  Widget _buildItemBody(BuildContext context) {
    final item = widget.item!;
    final quickKind = libraryItemSheetQuickRowKindFor(item);
    final showPinRow = libraryItemSupportsPinToggle(item) &&
        quickKind == LibraryItemSheetQuickRowKind.none;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          const _SheetDragHandle(),
          const SizedBox(height: AppSpacing.xl),
          _ItemHeader(item: item),
          const SizedBox(height: AppSpacing.lg),
          const _SheetDivider(),
          const SizedBox(height: AppSpacing.sm),
          if (quickKind != LibraryItemSheetQuickRowKind.none) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: LibraryItemSheetQuickActionRow(
                kind: quickKind,
                item: item,
                hostContext: widget.hostContext,
                libraryListScopeFolderId: widget.libraryListScopeFolderId,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const _SheetDivider(),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (libraryItemSupportsFolderMembership(item))
            _OptionRow(
              icon: AppIcons.folder,
              label: 'Add to folder',
              onTap: () {
                Navigator.of(context).pop();
                showAddToFolderSheet(
                  widget.hostContext,
                  ref,
                  playlistId: item.id,
                );
              },
            ),
          if (showPinRow)
            LibraryPinToggleRow(
              item: item,
              libraryListScopeFolderId: widget.libraryListScopeFolderId,
            ),
          ..._libraryItemOptionsSecondaryActions(
            item,
            quickKind: quickKind,
          ).map(
            (a) => _OptionRow(
              icon: a.icon,
              label: a.label,
              onTap: () {
                if (a.customTap != null) {
                  a.customTap!();
                  return;
                }
                Navigator.of(context).pop();
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildTrackBody(BuildContext context) {
    final details = widget.details!;
    final track = widget.track!;
    final likedPlaylistItem = ref.watch(likedPlaylistLibraryItemProvider);
    final likedAsync = ref.watch(trackLikedStatusProvider(_videoId));
    final isLiked = likedAsync.maybeWhen(data: (v) => v, orElse: () => false);
    final likeReady =
        _hasVideoId && likedPlaylistItem != null && !likedAsync.isLoading;
    final radius = AppBorderRadius.subtle;
    final playlistLabel = _userOwnedPlaylist ? 'Remove' : 'Playlist';
    final playlistIcon =
        _userOwnedPlaylist ? AppIcons.close : AppIcons.playlistAddIcon;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          const _SheetDragHandle(),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                LibraryCollectionArtwork(
                  item: LibraryItem(
                    id: track.videoId.isNotEmpty
                        ? track.videoId
                        : details.item.id,
                    title: track.title,
                    subtitle: track.subtitle,
                    kind: LibraryItemKind.playlist,
                    imageUrl: track.thumbUrl,
                  ),
                  preferredImageUrl: track.thumbUrl,
                  size: LibraryLayout.sheetArtworkSize,
                  borderRadius: radius,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyBold,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        track.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.small,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SheetDivider(),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                Expanded(
                  child: _SheetCircleButton(
                    icon: AppIcons.download,
                    label: 'Download',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: _SheetCircleButton(
                    icon: playlistIcon,
                    label: playlistLabel,
                    busy: _playlistBusy,
                    enabled: _hasVideoId,
                    onTap: _hasVideoId ? _onTrackPlaylistTap : null,
                  ),
                ),
                Expanded(
                  child: _SheetCircleButton(
                    icon: AppIcons.favorite,
                    label: isLiked ? 'Unlike' : 'Like',
                    busy: _likeBusy,
                    enabled: likeReady,
                    onTap: () {
                      final row = likedPlaylistItem;
                      if (row == null ||
                          !_hasVideoId ||
                          likedAsync.isLoading ||
                          _likeBusy) {
                        return;
                      }
                      _onTrackLikeTap(row, isLiked);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _SheetDivider(),
          const SizedBox(height: AppSpacing.sm),
          ..._trackSecondaryActions().map(
            (a) => _OptionRow(
              icon: a.icon,
              label: a.label,
              onTap: () {
                if (a.customTap != null) {
                  a.customTap!();
                  return;
                }
                Navigator.of(context).pop();
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
