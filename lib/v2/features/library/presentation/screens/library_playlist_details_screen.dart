import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_details_layout.dart';
import 'package:tunify/v2/features/library/presentation/providers/library_providers.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_details/library_details_scroll_view.dart';

/// Library collection detail: static playlists, standard playlists/albums, or artists.
class LibraryPlaylistDetailsScreen extends ConsumerWidget {
  const LibraryPlaylistDetailsScreen({
    super.key,
    required this.item,
  });

  final LibraryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(libraryRepositoryProvider).detailsFor(item);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.nearBlack,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              details.gradientTop,
              AppColors.nearBlack.withValues(
                alpha: LibraryDetailsLayout.bodyGradientNearBlackStopAlpha,
              ),
              AppColors.nearBlack,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: LibraryDetailsScrollView(
            details: details,
            bottomInset: bottomInset,
          ),
        ),
      ),
    );
  }
}
