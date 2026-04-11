import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:tunify/v1/data/models/mood.dart';
import 'package:tunify/v1/features/home/home_state_provider.dart';
import 'package:tunify/v1/ui/theme/design_tokens.dart';
import 'package:tunify/v1/ui/widgets/player/mood_browse_sheet.dart';
import 'package:tunify/v1/ui/widgets/common/click_region.dart';
import 'package:tunify/v1/ui/widgets/common/section_header.dart';

/// Mood section: moods and genres from the main home feed API.
/// Shows skeleton while home is loading; uses [moodsProvider] when loaded.
class MoodSection extends ConsumerWidget {
  const MoodSection({super.key, this.showAll = false});

  /// When true, shows all moods with "Browse All" header and no "See all" button.
  /// When false (default), shows [_visibleCount] moods with "Browse By Mood" header.
  final bool showAll;

  static const int _visibleCount = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(homeIsLoadingProvider);
    final moods = ref.watch(moodsProvider);

    if (isLoading && moods.isEmpty) {
      return _MoodSectionSkeleton(showAll: showAll);
    }
    if (moods.isEmpty) return const SizedBox.shrink();

    final visible =
        showAll ? moods : moods.take(_visibleCount).toList(growable: false);
    final hasSeeAll = !showAll && moods.length > _visibleCount;
    const hPad = AppSpacing.base;

    void onSeeAll() {
      showMoodBrowseSheet(context, moods: moods);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: showAll ? 'Browse All' : 'Browse By Mood',
          seeAllLabel: hasSeeAll ? 'See all' : null,
          onSeeAll: hasSeeAll ? onSeeAll : null,
          useCompactStyle: true,
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.md),
        ),
        _MoodGrid(visibleMoods: visible, allMoods: moods),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

({int columns, double hPad, double aspectRatio}) _moodGridLayout(
    BuildContext context) {
  return (
    columns: 2,
    hPad: AppSpacing.base,
    aspectRatio: 1.6,
  );
}

class _MoodGrid extends StatelessWidget {
  const _MoodGrid({required this.visibleMoods, required this.allMoods});
  final List<Mood> visibleMoods;
  final List<Mood> allMoods;

  @override
  Widget build(BuildContext context) {
    final (:columns, :hPad, :aspectRatio) = _moodGridLayout(context);

    // PERF: Replaced GridView.builder(shrinkWrap: true) with a Column/Row
    // layout. shrinkWrap forces layout of all items to measure intrinsic height,
    // defeating GridView's lazy-loading purpose entirely. Since mood count is
    // bounded (≤8 visible, ≤~30 showAll), a manual Column/Row has no downside
    // and eliminates the GridView scroll controller + relayout overhead.
    final rowCount = (visibleMoods.length / columns).ceil();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int r = 0; r < rowCount; r++) ...[
            if (r > 0) const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                for (int c = 0; c < columns; c++) ...[
                  if (c > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: () {
                      final i = r * columns + c;
                      if (i >= visibleMoods.length) {
                        // Fill remainder of last row with transparent spacer
                        return AspectRatio(aspectRatio: aspectRatio);
                      }
                      return AspectRatio(
                        aspectRatio: aspectRatio,
                        child: _MoodTile(
                          mood: visibleMoods[i],
                          allMoods: allMoods,
                        ),
                      );
                    }(),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Individual mood tile extracted to a const-constructible widget so Flutter
/// can reuse the element during reconciliation.
class _MoodTile extends StatelessWidget {
  const _MoodTile({required this.mood, required this.allMoods});
  final Mood mood;
  final List<Mood> allMoods;

  @override
  Widget build(BuildContext context) {
    return ClickRegion(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          showMoodBrowseSheet(context, initialMood: mood, moods: allMoods);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            decoration: BoxDecoration(
              gradient: mood.gradient,
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                mood.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSize.md,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(color: Colors.black38, blurRadius: 6),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodSectionSkeleton extends StatelessWidget {
  const _MoodSectionSkeleton({this.showAll = false});

  final bool showAll;

  static const int _skeletonCount = 10;

  @override
  Widget build(BuildContext context) {
    final fakeMoods = List.generate(
      _skeletonCount,
      (i) => const Mood(
        id: 'skeleton',
        label: 'Loading mood',
        query: 'loading',
        gradient: LinearGradient(colors: [Colors.white, Colors.white]),
      ),
    );
    return Skeletonizer(
      enabled: true,
      child: IgnorePointer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: showAll ? 'Browse All' : 'Browse By Mood',
              useCompactStyle: true,
            ),
            _MoodGrid(visibleMoods: fakeMoods, allMoods: fakeMoods),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
