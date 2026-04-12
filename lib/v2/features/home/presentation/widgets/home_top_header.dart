import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/widgets/buttons/filter_double_pill.dart';
import 'package:tunify/v2/core/widgets/buttons/filter_single_pill.dart';
import 'package:tunify/v2/features/home/presentation/constants/home_layout.dart';
import 'package:tunify/v2/features/home/presentation/providers/home_providers.dart';
import 'package:tunify/v2/features/home/presentation/widgets/home_user_menu_panel.dart';

/// Pinned header: profile + Figma library filter pills (single + double segment).
class HomeTopHeader extends ConsumerWidget {
  const HomeTopHeader({super.key});

  /// Figma secondary segment label (same for Music and Podcasts rows).
  static const String _secondaryTrailingLabel = 'Following';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mq = MediaQuery.of(context);
    final pills = ref.watch(homeFilterPillsProvider);
    final notifier = ref.read(homeFilterPillsProvider.notifier);

    return Material(
      color: AppColors.nearBlack,
      child: Padding(
        padding: HomeLayout.headerPadding(mq),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ProfileAvatarButton(
              diameter: HomeLayout.profileAvatarDiameter,
              iconSize: HomeLayout.profileAvatarIconSize,
            ),
            SizedBox(width: AppSpacing.lg - AppSpacing.sm),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterSinglePill(
                      label: 'All',
                      selected: pills.band == HomeContentBand.all,
                      onPressed: notifier.selectAll,
                    ),
                    SizedBox(width: AppSpacing.md),
                    FilterDoublePill(
                      primaryLabel: 'Music',
                      secondaryLabel: _secondaryTrailingLabel,
                      primarySelected: pills.band == HomeContentBand.music,
                      secondarySelected:
                          pills.band == HomeContentBand.music &&
                              pills.musicSecondaryOn,
                      secondaryRevealed: pills.musicSecondaryExpanded,
                      onPrimaryPressed: notifier.tapMusicPrimary,
                      onSecondaryPressed: notifier.tapMusicSecondary,
                      showCloseControl: false,
                    ),
                    SizedBox(width: AppSpacing.md),
                    FilterDoublePill(
                      primaryLabel: 'Podcasts',
                      secondaryLabel: _secondaryTrailingLabel,
                      primarySelected: pills.band == HomeContentBand.podcasts,
                      secondarySelected:
                          pills.band == HomeContentBand.podcasts &&
                              pills.podcastsSecondaryOn,
                      secondaryRevealed: pills.podcastsSecondaryExpanded,
                      onPrimaryPressed: notifier.tapPodcastsPrimary,
                      onSecondaryPressed: notifier.tapPodcastsSecondary,
                      showCloseControl: false,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatarButton extends StatelessWidget {
  const _ProfileAvatarButton({
    required this.diameter,
    required this.iconSize,
  });

  final double diameter;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => showHomeUserMenu(context),
        child: Ink(
          height: diameter,
          width: diameter,
          decoration: const BoxDecoration(
            color: AppColors.midDark,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.person_rounded,
              size: iconSize,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
