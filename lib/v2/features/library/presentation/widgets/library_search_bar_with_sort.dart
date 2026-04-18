import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_details_layout.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_strings.dart';

/// Reusable search bar with optional sort button.
/// Used in library details header and save-to-playlist sheet.
class LibrarySearchBarWithSort extends StatelessWidget {
  const LibrarySearchBarWithSort({
    super.key,
    required this.hint,
    this.showSortButton = true,
    this.onTapSearch,
    this.onTapSort,
  });

  final String hint;
  final bool showSortButton;
  final VoidCallback? onTapSearch;
  final VoidCallback? onTapSort;

  @override
  Widget build(BuildContext context) {
    final field = Expanded(
      child: GestureDetector(
        onTap: onTapSearch,
        child: Container(
          height: LibraryDetailsLayout.searchBarHeight,
          decoration: BoxDecoration(
            color: LibraryDetailsLayout.searchFieldFill,
            borderRadius: BorderRadius.circular(
              LibraryDetailsLayout.searchBarCornerRadius,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: AppColors.white,
                size: LibraryDetailsLayout.searchLeadingIconSize,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                hint,
                style: AppTextStyles.smallBold.copyWith(
                  fontSize: LibraryDetailsLayout.searchHintFontSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!showSortButton) return Row(children: [field]);

    return Row(
      children: [
        field,
        const SizedBox(width: AppSpacing.sm),
        GestureDetector(
          onTap: onTapSort,
          child: Container(
            height: LibraryDetailsLayout.searchBarHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: LibraryDetailsLayout.searchFieldFill,
              borderRadius: BorderRadius.circular(
                LibraryDetailsLayout.searchBarCornerRadius,
              ),
            ),
            child: Center(
              child: Text(
                LibraryStrings.sort,
                style: AppTextStyles.smallBold.copyWith(
                  fontSize: LibraryDetailsLayout.searchHintFontSize,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
