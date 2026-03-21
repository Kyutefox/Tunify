import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/ui/components_ui.dart';
import '../../../config/app_icons.dart';
import '../../../models/library_playlist.dart';
import '../../../shared/providers/library_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_routes.dart';
import '../../../shared/utils/string_utils.dart';
import 'library_playlist_screen.dart';

/// Full-screen view of a folder: back button, folder name, and list of playlists inside.
class LibraryFolderScreen extends ConsumerWidget {
  const LibraryFolderScreen({super.key, required this.folderId});

  final String folderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folder = ref.watch(libraryFolderByIdProvider(folderId));
    final playlists = ref.watch(libraryProvider).playlists;
    final idToPlaylist = {for (final p in playlists) p.id: p};
    final folderPlaylists = folder == null
        ? <LibraryPlaylist>[]
        : folder.playlistIds
            .map((id) => idToPlaylist[id])
            .whereType<LibraryPlaylist>()
            .toList();

    if (folder == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: BackTitleAppBar(
          title: '',
          backgroundColor: AppColors.background,
        ),
        body: const Center(
          child: Text(
            'Folder not found',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackTitleAppBar(
        title: folder.name.capitalized,
        backgroundColor: AppColors.background,
      ),
      body: folderPlaylists.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'No playlists in this folder',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: AppFontSize.lg,
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.base,
              ),
              itemCount: folderPlaylists.length,
              itemBuilder: (context, index) {
                final playlist = folderPlaylists[index];
                final coverUrl = playlist.songs.isNotEmpty
                    ? playlist.songs.first.thumbnailUrl
                    : null;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        appPageRoute<void>(
                          builder: (_) =>
                              LibraryPlaylistScreen(playlistId: playlist.id),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                        horizontal: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                            child: coverUrl != null
                                ? ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                    child: CachedNetworkImage(
                                      imageUrl: coverUrl,
                                      fit: BoxFit.cover,
                                      width: 52,
                                      height: 52,
                                      placeholder: (_, __) => Center(
                                        child: AppIcon(
                                          icon: AppIcons.musicNote,
                                          color: AppColors.textMuted,
                                          size: 28,
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => Center(
                                        child: AppIcon(
                                          icon: AppIcons.musicNote,
                                          color: AppColors.textMuted,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: AppIcon(
                                      icon: AppIcons.musicNote,
                                      color: AppColors.textMuted,
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
                                  playlist.name.capitalized,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: AppFontSize.lg,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  playlist.trackCountLabel,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: AppFontSize.md,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppIcon(
                            icon: AppIcons.chevronRight,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
