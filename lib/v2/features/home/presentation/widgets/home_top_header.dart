import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/features/auth/domain/entities/user_entity.dart';
import 'package:tunify/v2/features/auth/presentation/providers/auth_session_provider.dart';
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
    final sessionUser = ref.watch(authSessionProvider).whenOrNull(data: (user) => user);

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
              avatarUrl: _avatarUrl(sessionUser),
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
    required this.avatarUrl,
  });

  final double diameter;
  final double iconSize;
  final String? avatarUrl;

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
          child: ClipOval(
            child: avatarUrl == null
              ? Center(
                  child: Icon(
                    Icons.person_rounded,
                    size: iconSize,
                    color: AppColors.white,
                  ),
                )
                : _NetworkAvatarImage(
                    url: avatarUrl!,
                    fallbackIconSize: iconSize,
                  ),
          ),
        ),
      ),
    );
  }
}

class _NetworkAvatarImage extends StatelessWidget {
  const _NetworkAvatarImage({
    required this.url,
    required this.fallbackIconSize,
  });

  final String url;
  final double fallbackIconSize;

  @override
  Widget build(BuildContext context) {
    if (_isSvg(url)) {
      return SvgPicture.network(
        url,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => _AvatarFallbackIcon(size: fallbackIconSize),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _AvatarFallbackIcon(size: fallbackIconSize),
    );
  }
}

class _AvatarFallbackIcon extends StatelessWidget {
  const _AvatarFallbackIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.person_rounded,
        size: size,
        color: AppColors.white,
      ),
    );
  }
}

bool _isSvg(String url) {
  final lower = url.toLowerCase();
  if (lower.contains('.svg')) {
    return true;
  }
  final uri = Uri.tryParse(lower);
  if (uri == null) {
    return lower.contains('/svg');
  }
  return uri.path.endsWith('/svg') || uri.path.endsWith('.svg');
}

String? _avatarUrl(UserEntity? user) {
  final raw = user?.photoUrl?.trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return raw;
}
