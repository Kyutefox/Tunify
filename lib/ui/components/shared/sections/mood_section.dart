import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/mood.dart';
import '../../../../shared/providers/home_state_provider.dart';
import '../../../../ui/theme/app_colors.dart';
import '../../../../ui/theme/design_tokens.dart';
import '../../ui/widgets/mood_browse_sheet.dart';
import '../../ui/widgets/section_header.dart';
import '../../../../ui/layout/shell_context.dart';

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

    final visible = showAll ? moods : moods.take(_visibleCount).toList(growable: false);
    final hasSeeAll = !showAll && moods.length > _visibleCount;
    final isDesktop = ShellContext.isDesktopOf(context);
    final hPad = isDesktop ? AppSpacing.xl : AppSpacing.base;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: showAll ? 'Browse All' : 'Browse By Mood',
          seeAllLabel: hasSeeAll ? 'See all' : null,
          onSeeAll: hasSeeAll
              ? () => showMoodBrowseSheet(context, moods: moods)
              : null,
          useCompactStyle: true,
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.md),
        ),
        _MoodGrid(visibleMoods: visible, allMoods: moods),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _MoodGrid extends StatelessWidget {
  const _MoodGrid({required this.visibleMoods, required this.allMoods});
  final List<Mood> visibleMoods;
  final List<Mood> allMoods;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ShellContext.isDesktopOf(context);
    final columns = isDesktop ? 5 : 2;
    final hPad = isDesktop ? AppSpacing.xl : AppSpacing.base;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.6,
        ),
        itemCount: visibleMoods.length,
        itemBuilder: (_, i) {
          final mood = visibleMoods[i];
          return GestureDetector(
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
                      fontSize: 13,
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
          );
        },
      ),
    );
  }
}

class _MoodSectionSkeleton extends StatelessWidget {
  const _MoodSectionSkeleton({this.showAll = false});

  final bool showAll;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ShellContext.isDesktopOf(context);
    final columns = isDesktop ? 5 : 2;
    final hPad = isDesktop ? AppSpacing.xl : AppSpacing.base;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: showAll ? 'Browse All' : 'Browse By Mood',
          useCompactStyle: true,
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.md),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.6,
            ),
            itemCount: 10,
            itemBuilder: (_, __) => Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}
