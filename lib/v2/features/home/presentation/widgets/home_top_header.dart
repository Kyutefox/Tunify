import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/widgets/navigation/app_top_navigation.dart';
import 'package:tunify/v2/core/widgets/buttons/filter_double_pill.dart';
import 'package:tunify/v2/core/widgets/buttons/filter_single_pill.dart';
import 'package:tunify/v2/features/home/presentation/providers/home_providers.dart';
import 'package:tunify/v2/features/home/presentation/widgets/home_user_menu_panel.dart';

/// Pinned header: profile + Figma library filter pills (single + double segment).
class HomeTopHeader extends ConsumerWidget {
  const HomeTopHeader({super.key});

  /// Figma secondary segment label (same for Music and Podcasts rows).
  static const String _secondaryTrailingLabel = 'Following';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pills = ref.watch(homeFilterPillsProvider);
    final notifier = ref.read(homeFilterPillsProvider.notifier);
    return AppTopNavigation(
      leadingOnTap: () => showHomeUserMenu(context),
      middle: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterSinglePill(
              label: 'All',
              selected: pills.band == HomeContentBand.all,
              onPressed: notifier.selectAll,
            ),
            const SizedBox(width: AppSpacing.md),
            FilterDoublePill(
              primaryLabel: 'Music',
              secondaryLabel: _secondaryTrailingLabel,
              primarySelected: pills.band == HomeContentBand.music,
              secondarySelected:
                  pills.band == HomeContentBand.music && pills.musicSecondaryOn,
              secondaryRevealed: pills.musicSecondaryExpanded,
              onPrimaryPressed: notifier.tapMusicPrimary,
              onSecondaryPressed: notifier.tapMusicSecondary,
              showCloseControl: false,
            ),
            const SizedBox(width: AppSpacing.md),
            FilterDoublePill(
              primaryLabel: 'Podcasts',
              secondaryLabel: _secondaryTrailingLabel,
              primarySelected: pills.band == HomeContentBand.podcasts,
              secondarySelected: pills.band == HomeContentBand.podcasts &&
                  pills.podcastsSecondaryOn,
              secondaryRevealed: pills.podcastsSecondaryExpanded,
              onPrimaryPressed: notifier.tapPodcastsPrimary,
              onSecondaryPressed: notifier.tapPodcastsSecondary,
              showCloseControl: false,
            ),
          ],
        ),
      ),
    );
  }
}
