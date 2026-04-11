import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/v1/ui/widgets/common/input_field.dart';
import 'package:tunify/v1/ui/widgets/common/sheet.dart'
    show showAppSheet, kSheetHorizontalPadding;
import 'package:tunify/v1/core/constants/app_icons.dart';
import 'package:tunify/v1/data/models/song.dart';
import 'package:tunify/v1/features/library/library_provider.dart';
import 'package:tunify/v1/ui/theme/app_colors.dart';
import 'package:tunify/v1/ui/theme/design_tokens.dart';
import 'package:tunify/v1/core/utils/string_utils.dart';
import 'package:tunify/v1/ui/theme/app_colors_scheme.dart';

void showAddToPlaylistSheet(
  BuildContext context, {
  required Song song,
  List<Song>? songs,
}) {
  final list = songs ?? [song];
  showAppSheet(
    context,
    child: _AddToPlaylistSheetContent(songs: list, onDone: () {}),
  );
}

class _AddToPlaylistSheetContent extends ConsumerStatefulWidget {
  const _AddToPlaylistSheetContent({
    required this.songs,
    required this.onDone,
  });

  final List<Song> songs;
  final VoidCallback onDone;

  @override
  ConsumerState<_AddToPlaylistSheetContent> createState() =>
      _AddToPlaylistSheetContentState();
}

class _AddToPlaylistSheetContentState
    extends ConsumerState<_AddToPlaylistSheetContent> {
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

  @override
  Widget build(BuildContext context) {
    final allPlaylists = ref.watch(libraryPlaylistsProvider);
    final playlists = _query.isEmpty
        ? allPlaylists
        : allPlaylists
            .where((p) => p.name.toLowerCase().contains(_query))
            .toList();

    final maxListHeight = MediaQuery.of(context).size.height * 0.45;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            kSheetHorizontalPadding,
            AppSpacing.sm,
            kSheetHorizontalPadding,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              AppIcon(
                icon: AppIcons.playlistAdd,
                color: AppColorsScheme.of(context).textPrimary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  widget.songs.length == 1
                      ? 'Add to playlist'
                      : 'Add ${widget.songs.length} songs to playlist',
                  style: TextStyle(
                    color: AppColorsScheme.of(context).textPrimary,
                    fontSize: AppFontSize.xxl,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kSheetHorizontalPadding,
            vertical: AppSpacing.xs,
          ),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColorsScheme.of(context).surfaceLight,
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Row(
              children: [
                const SizedBox(width: AppSpacing.md),
                AppIcon(
                  icon: AppIcons.search,
                  color: AppColorsScheme.of(context).textMuted,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppInputField(
                    controller: _searchController,
                    hintText: 'Search playlists',
                    style: InputFieldStyle.transparent,
                  ),
                ),
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: () => _searchController.clear(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: AppIcon(
                        icon: AppIcons.clear,
                        color: AppColorsScheme.of(context).textMuted,
                        size: 18,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: AppSpacing.md),
              ],
            ),
          ),
        ),
        if (playlists.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xxl,
              horizontal: AppSpacing.base,
            ),
            child: Text(
              _query.isNotEmpty
                  ? 'No playlists match "$_query"'
                  : 'Create a playlist in Library first',
              style: TextStyle(
                color: AppColorsScheme.of(context)
                    .textMuted
                    .withValues(alpha: 0.9),
                fontSize: AppFontSize.base,
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxListHeight),
            child: ListView.builder(
              shrinkWrap: true,
              cacheExtent: 500,
              addAutomaticKeepAlives: true,
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final p = playlists[index];
                final pSongIds = p.songs.map((s) => s.id).toSet();
                final allAlreadyIn =
                    widget.songs.every((s) => pSongIds.contains(s.id));
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                  ),
                  leading: p.songs.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                          child: Image.network(
                            p.songs.first.thumbnailUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholderIcon(),
                          ),
                        )
                      : _placeholderIcon(),
                  title: Text(
                    p.name.capitalized,
                    style: TextStyle(
                      color: AppColorsScheme.of(context).textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    p.trackCountLabel,
                    style: TextStyle(
                      color: AppColorsScheme.of(context).textMuted,
                      fontSize: AppFontSize.sm,
                    ),
                  ),
                  trailing: allAlreadyIn
                      ? AppIcon(
                          icon: AppIcons.checkCircle,
                          color: AppColors.primary,
                          size: 24,
                        )
                      : null,
                  onTap: () async {
                    await ref
                        .read(libraryProvider.notifier)
                        .addSongsToPlaylist(p.id, widget.songs);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Added to ${p.name.capitalized}',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.of(context).pop();
                      widget.onDone();
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColorsScheme.of(context).surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: AppIcon(
        icon: AppIcons.musicNote,
        color: AppColorsScheme.of(context).textMuted,
        size: 24,
      ),
    );
  }
}
