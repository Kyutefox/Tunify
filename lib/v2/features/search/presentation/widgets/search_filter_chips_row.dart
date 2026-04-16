import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/widgets/buttons/filter_pill_row.dart';
import 'package:tunify/v2/core/widgets/buttons/filter_single_pill.dart';
import 'package:tunify/v2/features/search/domain/entities/search_models.dart';

class SearchFilterChipsRow extends StatelessWidget {
  const SearchFilterChipsRow({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final SearchFilter selectedFilter;
  final ValueChanged<SearchFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final isCollapsed = selectedFilter != SearchFilter.all;
    const animationDuration = Duration(milliseconds: 280);
    const animationCurve = Curves.easeOutCubic;

    return SizedBox(
      height: 30,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ClipRect(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              IgnorePointer(
                ignoring: isCollapsed,
                child: AnimatedSlide(
                  duration: animationDuration,
                  curve: animationCurve,
                  offset: isCollapsed ? const Offset(0.08, 0) : Offset.zero,
                  child: AnimatedOpacity(
                    duration: animationDuration,
                    curve: animationCurve,
                    opacity: isCollapsed ? 0 : 1,
                    child: FilterPillRow(
                      children: [
                        FilterSinglePill(
                          label: 'Artists',
                          selected: false,
                          onPressed: () => onFilterSelected(SearchFilter.artists),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        FilterSinglePill(
                          label: 'Albums',
                          selected: false,
                          onPressed: () => onFilterSelected(SearchFilter.albums),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        FilterSinglePill(
                          label: 'Playlists',
                          selected: false,
                          onPressed: () => onFilterSelected(SearchFilter.playlists),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        FilterSinglePill(
                          label: 'Songs',
                          selected: false,
                          onPressed: () => onFilterSelected(SearchFilter.songs),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        FilterSinglePill(
                          label: 'Podcasts',
                          selected: false,
                          onPressed: () => onFilterSelected(SearchFilter.podcasts),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                ignoring: !isCollapsed,
                child: AnimatedSlide(
                  duration: animationDuration,
                  curve: animationCurve,
                  offset: isCollapsed ? Offset.zero : const Offset(-0.08, 0),
                  child: AnimatedOpacity(
                    duration: animationDuration,
                    curve: animationCurve,
                    opacity: isCollapsed ? 1 : 0,
                    child: FilterPillRow(
                      children: [
                        FilterSinglePill(
                          label: _labelForFilter(selectedFilter),
                          selected: true,
                          onPressed: () {},
                          showCloseControl: true,
                          onClose: () => onFilterSelected(SearchFilter.all),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _labelForFilter(SearchFilter filter) {
  return switch (filter) {
    SearchFilter.all => 'All',
    SearchFilter.artists => 'Artists',
    SearchFilter.albums => 'Albums',
    SearchFilter.playlists => 'Playlists',
    SearchFilter.songs => 'Songs',
    SearchFilter.podcasts => 'Podcasts',
  };
}
