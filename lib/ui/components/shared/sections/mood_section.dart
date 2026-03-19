import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/mood.dart';
import '../../../../shared/providers/home_state_provider.dart';
import '../../../../ui/theme/app_colors.dart';
import '../../../../ui/theme/design_tokens.dart';
import '../../ui/widgets/mood_browse_sheet.dart';
import '../../ui/widgets/section_header.dart';

/// Mood section: moods and genres from the main home feed API.
/// Shows skeleton while home is loading; uses [moodsProvider] when loaded.
class MoodSection extends ConsumerWidget {
  const MoodSection({super.key});

  static const int _visibleCount = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(homeIsLoadingProvider);
    final moods = ref.watch(moodsProvider);

    if (isLoading && moods.isEmpty) {
      return const _MoodSectionSkeleton();
    }
    if (moods.isEmpty) return const SizedBox.shrink();

    final visible = moods.take(_visibleCount).toList(growable: false);
    final hasSeeAll = moods.length > _visibleCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Browse By Mood',
          seeAllLabel: hasSeeAll ? 'See all' : null,
          onSeeAll: hasSeeAll
              ? () => showMoodBrowseSheet(context, moods: moods)
              : null,
          useCompactStyle: true,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 3.0,
        ),
        itemCount: visibleMoods.length,
        itemBuilder: (_, i) {
          final mood = visibleMoods[i];
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              showMoodBrowseSheet(context, initialMood: mood, moods: allMoods);
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: mood.gradient,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  mood.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
  const _MoodSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Browse By Mood',
          useCompactStyle: true,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 3.0,
            children: List.generate(
              8,
              (_) => Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}
