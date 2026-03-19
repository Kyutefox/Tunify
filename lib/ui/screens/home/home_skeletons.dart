import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';
import 'home_shared.dart';

class HomePageSkeleton extends StatelessWidget {
  const HomePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.base,
            0,
            AppSpacing.base,
            AppSpacing.md,
          ),
          child: SkeletonBox(width: 140, height: 20, radius: AppRadius.sm),
        ),
        SizedBox(
          height: 188,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, __) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(
                  width: 148,
                  height: 148,
                  radius: AppRadius.md,
                ),
                const SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: 100, height: 12, radius: AppRadius.xs),
                const SizedBox(height: AppSpacing.xs),
                SkeletonBox(width: 70, height: 10, radius: AppRadius.xs),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        const SectionSkeleton(
          titleWidth: 120,
          subtitleWidth: 156,
          child: QuickPicksRowSkeleton(),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.base,
            0,
            AppSpacing.base,
            AppSpacing.md,
          ),
          child: SkeletonBox(width: 160, height: 20, radius: AppRadius.sm),
        ),
        SizedBox(
          height: 188,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, __) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(
                  width: 148,
                  height: 148,
                  radius: AppRadius.md,
                ),
                const SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: 110, height: 12, radius: AppRadius.xs),
                const SizedBox(height: AppSpacing.xs),
                SkeletonBox(width: 80, height: 10, radius: AppRadius.xs),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.base,
            0,
            AppSpacing.base,
            AppSpacing.md,
          ),
          child: SkeletonBox(width: 130, height: 20, radius: AppRadius.sm),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: List.generate(
              6,
              (_) => SkeletonBox(
                width: 100,
                height: 100,
                radius: AppRadius.md,
              ),
            ),
          ),
        ),
      ],
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: const Duration(milliseconds: 1400),
          color: AppColors.surfaceHighlight,
        );
  }
}

class SectionSkeleton extends StatelessWidget {
  const SectionSkeleton({
    super.key,
    required this.titleWidth,
    required this.child,
    this.subtitleWidth,
  });

  final double titleWidth;
  final double? subtitleWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.base,
            0,
            AppSpacing.base,
            AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(
                      width: titleWidth,
                      height: 20,
                      radius: AppRadius.sm,
                    ),
                    if (subtitleWidth != null) ...[
                      const SizedBox(height: 4),
                      SkeletonBox(
                        width: subtitleWidth!,
                        height: 11,
                        radius: AppRadius.xs,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class SectionAsyncSwap extends StatelessWidget {
  const SectionAsyncSwap({
    super.key,
    required this.isLoading,
    required this.hasData,
    required this.loadedChild,
    required this.loadingChild,
  });

  final bool isLoading;
  final bool hasData;
  final Widget loadedChild;
  final Widget loadingChild;

  @override
  Widget build(BuildContext context) {
    if (hasData) return loadedChild;
    if (isLoading) {
      return loadingChild.animate(onPlay: (c) => c.repeat()).shimmer(
            duration: const Duration(milliseconds: 1400),
            color: AppColors.surfaceHighlight,
          );
    }
    return const SizedBox.shrink();
  }
}

class QuickPicksRowSkeleton extends StatelessWidget {
  const QuickPicksRowSkeleton({super.key});

  static const int _columns = 3;
  static const int _perColumn = 4;
  static const double _tileH = 64;
  static const double _gap = AppSpacing.sm;
  static const double _listH = _tileH * _perColumn + _gap * (_perColumn - 1);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _listH,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        itemCount: _columns,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, __) => Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            _perColumn,
            (rowIdx) => Padding(
              padding: EdgeInsets.only(
                bottom: rowIdx < _perColumn - 1 ? _gap : 0,
              ),
              child: QuickPickTileSkeleton(height: _tileH),
            ),
          ),
        ),
      ),
    );
  }
}

class QuickPickTileSkeleton extends StatelessWidget {
  const QuickPickTileSkeleton({super.key, required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          SkeletonBox(width: height, height: height, radius: AppRadius.md),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 120, height: 12, radius: AppRadius.xs),
                SizedBox(height: 4),
                SkeletonBox(width: 82, height: 10, radius: AppRadius.xs),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
    );
  }
}

class PlaylistsRowSkeleton extends StatelessWidget {
  const PlaylistsRowSkeleton({super.key});

  static const double _cardW = 148;
  static const double _cardH = 148;
  static const double _rowH = 196;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _rowH,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(
              width: _cardW,
              height: _cardH,
              radius: AppRadius.md,
            ),
            const SizedBox(height: AppSpacing.sm),
            SkeletonBox(width: 100, height: 12, radius: AppRadius.xs),
            const SizedBox(height: AppSpacing.xs),
            SkeletonBox(width: 70, height: 10, radius: AppRadius.xs),
          ],
        ),
      ),
    );
  }
}

class MoodGridSkeleton extends StatelessWidget {
  const MoodGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 3.0,
        children: List.generate(
          6,
          (_) => LayoutBuilder(
            builder: (_, c) => SkeletonBox(
              width: c.maxWidth,
              height: c.maxHeight,
              radius: AppRadius.md,
            ),
          ),
        ),
      ),
    );
  }
}

class ArtistsRowSkeleton extends StatelessWidget {
  const ArtistsRowSkeleton({super.key});

  static const double _avatarSize = 72;
  static const double _rowH = 108;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _rowH,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xl),
        itemBuilder: (_, __) => SizedBox(
          width: _avatarSize,
          child: Column(
            children: [
              SkeletonBox(
                width: _avatarSize,
                height: _avatarSize,
                radius: _avatarSize / 2,
              ),
              const SizedBox(height: AppSpacing.sm),
              SkeletonBox(width: 50, height: 10, radius: AppRadius.xs),
            ],
          ),
        ),
      ),
    );
  }
}

class DynamicSectionsSkeleton extends StatelessWidget {
  const DynamicSectionsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionSkeleton(
          titleWidth: 140,
          subtitleWidth: 100,
          child: QuickPicksRowSkeleton(),
        ),
        const SizedBox(height: AppSpacing.xxl),
        const SectionSkeleton(
          titleWidth: 120,
          child: PlaylistsRowSkeleton(),
        ),
      ],
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: const Duration(milliseconds: 1400),
          color: AppColors.surfaceHighlight,
        );
  }
}
