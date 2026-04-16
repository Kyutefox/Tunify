import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/widgets/buttons/filter_pill_row.dart';
import 'package:tunify/v2/core/widgets/buttons/filter_single_pill.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_layout.dart';
import 'package:tunify/v2/features/library/presentation/providers/library_providers.dart';

/// Horizontally scrolling filter pills for the library screen.
///
/// Figma order: Playlists · Podcasts · Albums · Artists.
/// When a filter is active the row collapses to [X close] + active pill
/// + optional sub-filter pills ("By you" / "By Spotify" for Playlists).
class LibraryFilterPills extends ConsumerWidget {
  const LibraryFilterPills({super.key});

  static const _primaryFilters = <(LibraryFilter, String)>[
    (LibraryFilter.playlists, 'Playlists'),
    (LibraryFilter.podcasts, 'Podcasts'),
    (LibraryFilter.albums, 'Albums'),
    (LibraryFilter.artists, 'Artists'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(libraryControllerProvider);
    final notifier = ref.read(libraryControllerProvider.notifier);
    final isCollapsed = viewState.filter != LibraryFilter.all;

    const animDuration = Duration(milliseconds: 280);
    const animCurve = Curves.easeOutCubic;

    return SizedBox(
      height: LibraryLayout.filterPillsRowHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ClipRect(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // ── Expanded state: all primary pills ──
              IgnorePointer(
                ignoring: isCollapsed,
                child: AnimatedSlide(
                  duration: animDuration,
                  curve: animCurve,
                  offset: isCollapsed ? const Offset(0.08, 0) : Offset.zero,
                  child: AnimatedOpacity(
                    duration: animDuration,
                    curve: animCurve,
                    opacity: isCollapsed ? 0 : 1,
                    child: FilterPillRow(
                      children: _buildExpandedPills(notifier),
                    ),
                  ),
                ),
              ),
              // ── Collapsed state: close + active pill + sub-pills ──
              IgnorePointer(
                ignoring: !isCollapsed,
                child: AnimatedSlide(
                  duration: animDuration,
                  curve: animCurve,
                  offset: isCollapsed ? Offset.zero : const Offset(-0.08, 0),
                  child: AnimatedOpacity(
                    duration: animDuration,
                    curve: animCurve,
                    opacity: isCollapsed ? 1 : 0,
                    child: FilterPillRow(
                      children: _buildCollapsedPills(viewState, notifier),
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

  List<Widget> _buildExpandedPills(LibraryController notifier) {
    final widgets = <Widget>[];
    for (var i = 0; i < _primaryFilters.length; i++) {
      if (i > 0) widgets.add(const SizedBox(width: AppSpacing.md));
      final entry = _primaryFilters[i];
      widgets.add(
        FilterSinglePill(
          label: entry.$2,
          selected: false,
          onPressed: () => notifier.setFilter(entry.$1),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildCollapsedPills(
    LibraryViewState viewState,
    LibraryController notifier,
  ) {
    final widgets = <Widget>[
      FilterSinglePill(
        label: _primaryLabel(viewState.filter),
        selected: true,
        onPressed: () {},
        showCloseControl: true,
        onClose: notifier.clearFilter,
      ),
    ];

    // Sub-filter pills for Playlists: "By you" / "By Spotify"
    if (viewState.filter == LibraryFilter.playlists) {
      widgets.add(const SizedBox(width: AppSpacing.md));
      widgets.add(
        FilterSinglePill(
          label: 'By you',
          selected:
              viewState.playlistSubFilter == LibraryPlaylistSubFilter.byYou,
          onPressed: () =>
              notifier.setPlaylistSubFilter(LibraryPlaylistSubFilter.byYou),
        ),
      );
      widgets.add(const SizedBox(width: AppSpacing.md));
      widgets.add(
        FilterSinglePill(
          label: 'By Spotify',
          selected:
              viewState.playlistSubFilter == LibraryPlaylistSubFilter.bySpotify,
          onPressed: () =>
              notifier.setPlaylistSubFilter(LibraryPlaylistSubFilter.bySpotify),
        ),
      );
    }

    return widgets;
  }

  static String _primaryLabel(LibraryFilter filter) {
    return switch (filter) {
      LibraryFilter.all => 'All',
      LibraryFilter.playlists => 'Playlists',
      LibraryFilter.podcasts => 'Podcasts',
      LibraryFilter.albums => 'Albums',
      LibraryFilter.artists => 'Artists',
    };
  }
}
