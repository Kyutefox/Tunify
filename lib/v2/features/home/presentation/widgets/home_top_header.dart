import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_button_styles.dart';
import 'package:tunify/v2/features/home/presentation/constants/home_layout.dart';
import 'package:tunify/v2/features/home/presentation/providers/home_providers.dart';
import 'package:tunify/v2/features/settings/presentation/screens/settings_screen.dart';

/// Pinned header: profile + dark pill filters ([AppButtonStyles.navigationDarkPill]).
class HomeTopHeader extends ConsumerWidget {
  const HomeTopHeader({super.key});

  static const List<({String label, HomeChipFilter filter})> _chipSpecs = [
    (label: 'All', filter: HomeChipFilter.all),
    (label: 'Music', filter: HomeChipFilter.music),
    (label: 'Podcasts', filter: HomeChipFilter.podcasts),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mq = MediaQuery.of(context);
    final chip = ref.watch(homeChipFilterProvider);
    final chipNotifier = ref.read(homeChipFilterProvider.notifier);

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
                    for (var i = 0; i < _chipSpecs.length; i++) ...[
                      if (i > 0) SizedBox(width: AppSpacing.md),
                      AppButtonStyles.navigationDarkPill(
                        label: _chipSpecs[i].label,
                        selected: chip == _chipSpecs[i].filter,
                        onPressed: () => chipNotifier.select(_chipSpecs[i].filter),
                      ),
                    ],
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
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const SettingsScreen(),
            ),
          );
        },
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
