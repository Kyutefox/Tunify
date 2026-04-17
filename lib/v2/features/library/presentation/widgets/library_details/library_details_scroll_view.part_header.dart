part of 'library_details_scroll_view.dart';

class _BackHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.white,
            size: LibraryDetailsLayout.backButtonIconSize,
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.hint,
    required this.showSortButton,
  });

  final String hint;
  final bool showSortButton;

  @override
  Widget build(BuildContext context) {
    final field = Expanded(
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
    );

    if (!showSortButton) return Row(children: [field]);

    return Row(
      children: [
        field,
        const SizedBox(width: AppSpacing.sm),
        Container(
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
      ],
    );
  }
}

class _ChipPill extends StatelessWidget {
  const _ChipPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final icon = switch (label) {
      LibraryPlaylistManagementChips.add => Icons.add,
      LibraryPlaylistManagementChips.edit => Icons.menu,
      LibraryPlaylistManagementChips.sort => Icons.swap_vert,
      _ => Icons.edit_outlined,
    };
    return Container(
      height: LibraryDetailsLayout.chipPillHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.midDark,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.white,
            size: LibraryDetailsLayout.chipIconSize,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontSize: LibraryDetailsLayout.chipLabelFontSize,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddToPlaylistRow extends StatelessWidget {
  const _AddToPlaylistRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: LibraryDetailsLayout.addRowLeadingSize,
          height: LibraryDetailsLayout.addRowLeadingSize,
          color: AppColors.darkSurface,
          child: Icon(
            Icons.add,
            color: AppColors.silver,
            size: LibraryDetailsLayout.addRowPlusIconSize,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          LibraryStrings.addToThisPlaylist,
          style: AppTextStyles.body.copyWith(color: AppColors.white),
        ),
      ],
    );
  }
}
