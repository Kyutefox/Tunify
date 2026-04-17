import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/errors/failures.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_detail_request.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_details_gradient.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_strings.dart';
import 'package:tunify/v2/features/library/presentation/providers/library_providers.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_details/library_playlist_detail_scroll_shell.dart';

String _collectionDetailsErrorMessage(Object error) {
  if (error is Failure) {
    return error.message;
  }
  return LibraryStrings.collectionDetailsLoadError;
}

/// Library collection detail: mock library, or remote album / playlist / artist when [LibraryItem.ytmBrowseId] is set.
class LibraryPlaylistDetailsScreen extends ConsumerWidget {
  const LibraryPlaylistDetailsScreen({
    super.key,
    required this.item,
  });

  final LibraryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetails =
        ref.watch(libraryDetailsProvider(LibraryDetailRequest(item)));
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return asyncDetails.when(
      data: (details) => LibraryPlaylistDetailScrollShell(
        details: details,
        bottomInset: bottomInset,
        gradientColors: libraryDetailBackgroundGradientColors(details),
      ),
      loading: () => Scaffold(
        backgroundColor: AppColors.nearBlack,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.brandGreen),
              SizedBox(height: AppSpacing.lg),
              Text(
                item.title,
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.nearBlack,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              _collectionDetailsErrorMessage(err),
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
