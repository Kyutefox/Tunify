import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_items_query.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_details_layout.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_layout.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_strings.dart';
import 'package:tunify/v2/features/library/presentation/navigation/open_library_item.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_grid_tile.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_list_tile.dart';

/// Full-screen search layer matching collection-detail search UX
/// (pinned bar, back, [TextField], grid or list of [LibraryItem]).
class LibrarySearchModeOverlay extends StatelessWidget {
  const LibrarySearchModeOverlay({
    super.key,
    required this.searchTextController,
    required this.searchFocusNode,
    required this.searchQuery,
    required this.searchHint,
    required this.items,
    required this.bottomInset,
    required this.viewMode,
    required this.onBack,
    this.libraryListScopeFolderId,
  });

  final TextEditingController searchTextController;
  final FocusNode searchFocusNode;
  final ValueNotifier<String> searchQuery;
  final String searchHint;
  final List<LibraryItem> items;
  final double bottomInset;
  final LibraryViewMode viewMode;
  final VoidCallback onBack;

  /// When non-null, long-press / options use folder-scoped invalidation.
  final String? libraryListScopeFolderId;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final pinnedBg = Color.alphaBlend(
      AppColors.libraryDefaultGradientTop.withValues(alpha: 0.42),
      AppColors.nearBlack,
    );
    final bottomPad =
        bottomInset + LibraryDetailsLayout.scrollBottomExtraPadding;

    return Material(
      color: AppColors.nearBlack,
      child: Column(
        children: [
          Container(
            color: pinnedBg,
            padding: EdgeInsets.only(top: topPad),
            height: topPad + kToolbarHeight,
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.white,
                        size: 22,
                      ),
                      onPressed: onBack,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    child: SizedBox(
                      height: LibraryDetailsLayout.searchBarHeight,
                      child: TextField(
                        controller: searchTextController,
                        focusNode: searchFocusNode,
                        style: AppTextStyles.smallBold.copyWith(
                          fontSize: LibraryDetailsLayout.searchHintFontSize,
                          color: AppColors.white,
                        ),
                        cursorColor: AppColors.white,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          hintText: searchHint,
                          hintStyle: AppTextStyles.smallBold.copyWith(
                            fontSize: LibraryDetailsLayout.searchHintFontSize,
                            color: AppColors.silver,
                          ),
                          filled: true,
                          fillColor: AppColors.midDark,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(
                              left: AppSpacing.md,
                              right: AppSpacing.sm,
                            ),
                            child: Icon(
                              Icons.search,
                              color: AppColors.white,
                              size: LibraryDetailsLayout.searchLeadingIconSize,
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              LibraryDetailsLayout.searchBarCornerRadius,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              LibraryDetailsLayout.searchBarCornerRadius,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              LibraryDetailsLayout.searchBarCornerRadius,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.fromLTRB(
                            0,
                            0,
                            AppSpacing.md,
                            0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: searchQuery,
              builder: (context, query, _) {
                final filtered = LibraryItemsQuery.filterItemsBySearchQuery(
                  items,
                  query,
                );
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        LibraryStrings.nothingHereTitle,
                        style: AppTextStyles.featureHeading,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (filtered.isEmpty) {
                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      0,
                      bottomPad,
                    ),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.25,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  LibraryStrings.searchNoResultsTitle,
                                  style: AppTextStyles.featureHeading,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  LibraryStrings.searchNoResultsBody,
                                  style: AppTextStyles.caption,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                if (viewMode == LibraryViewMode.grid) {
                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                      LibraryLayout.horizontalPadding,
                      AppSpacing.sm,
                      0,
                      bottomPad,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: LibraryLayout.gridCrossAxisCount,
                      mainAxisSpacing: LibraryLayout.gridMainAxisSpacing,
                      crossAxisSpacing: LibraryLayout.gridCrossAxisSpacing,
                      childAspectRatio: LibraryLayout.gridChildAspectRatio,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return LibraryGridTile(
                        item: item,
                        libraryListScopeFolderId: libraryListScopeFolderId,
                        onTap: () => openLibraryItemFromList(context, item),
                      );
                    },
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.only(bottom: bottomPad),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return LibraryListTile(
                      item: item,
                      libraryListScopeFolderId: libraryListScopeFolderId,
                      onTap: () => openLibraryItemFromList(context, item),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
