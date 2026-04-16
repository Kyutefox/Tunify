import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/art/artwork_or_gradient.dart';
import 'package:tunify/v2/core/widgets/buttons/tunify_play_circle_button.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_details_layout.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_strings.dart';
import 'package:tunify/v2/features/library/presentation/widgets/system_artwork.dart';

/// Scrollable body for [LibraryPlaylistDetailsScreen] (keeps the screen widget thin).
class LibraryDetailsScrollView extends StatelessWidget {
  const LibraryDetailsScrollView({
    super.key,
    required this.details,
    required this.bottomInset,
  });

  final LibraryDetailsModel details;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _BackHeader()),
        if (details.searchHint.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _SearchBar(
                hint: details.searchHint,
                showSortButton: details.showSortButton,
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: details.isStaticPlaylist
                ? LibraryDetailsLayout.staticSearchToTitleGap
                : LibraryDetailsLayout.defaultSearchToHeroGap,
          ),
        ),
        SliverToBoxAdapter(child: _HeroSection(details: details)),
        if (details.type != LibraryDetailsType.artist)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: _PlaylistActionBar(details: details),
            ),
          )
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: _ArtistActionBar(details: details),
            ),
          ),
        if (details.chips.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: details.chips
                      .map(
                        (label) => Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.md),
                          child: _ChipPill(label: label),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
          ),
        if (details.artistTabs.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: details.artistTabs
                    .map(
                      (tab) => Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xl),
                        child: Text(
                          tab,
                          style: AppTextStyles.body.copyWith(
                            color: tab == details.artistTabs.first
                                ? AppColors.white
                                : AppColors.silver,
                            fontWeight: tab == details.artistTabs.first
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
        if (details.type == LibraryDetailsType.artist &&
            details.artistTabs.isNotEmpty)
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xxxl),
          ),
        if (details.type == LibraryDetailsType.artist)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Text(
                LibraryStrings.popular,
                style: AppTextStyles.featureHeading,
              ),
            ),
          ),
        if (details.showAddRow)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: _AddToPlaylistRow(),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverList.separated(
            itemCount: details.tracks.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) => _TrackRow(
              track: details.tracks[index],
              item: details.item,
            ),
          ),
        ),
        if (details.statsLine.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              child: Center(
                child: Text(
                  details.statsLine,
                  style: AppTextStyles.micro.copyWith(
                    color: AppColors.silver,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: bottomInset + LibraryDetailsLayout.scrollBottomExtraPadding,
          ),
        ),
      ],
    );
  }
}

class _BackHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.white,
            size: LibraryDetailsLayout.backButtonIconSize,
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.hint,
    required this.showSortButton,
  });

  final String hint;
  final bool showSortButton;

  @override
  Widget build(BuildContext context) {
    final field = Expanded(
      child: Container(
        height: LibraryDetailsLayout.searchBarHeight,
        decoration: BoxDecoration(
          color: LibraryDetailsLayout.searchFieldFill,
          borderRadius: BorderRadius.circular(
            LibraryDetailsLayout.searchBarCornerRadius,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: AppColors.white,
              size: LibraryDetailsLayout.searchLeadingIconSize,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              hint,
              style: AppTextStyles.smallBold.copyWith(
                fontSize: LibraryDetailsLayout.searchHintFontSize,
              ),
            ),
          ],
        ),
      ),
    );

    if (!showSortButton) return Row(children: [field]);

    return Row(
      children: [
        field,
        const SizedBox(width: AppSpacing.sm),
        Container(
          height: LibraryDetailsLayout.searchBarHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: LibraryDetailsLayout.searchFieldFill,
            borderRadius: BorderRadius.circular(
              LibraryDetailsLayout.searchBarCornerRadius,
            ),
          ),
          child: Center(
            child: Text(
              LibraryStrings.sort,
              style: AppTextStyles.smallBold.copyWith(
                fontSize: LibraryDetailsLayout.searchHintFontSize,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.details});
  final LibraryDetailsModel details;

  @override
  Widget build(BuildContext context) {
    if (details.type == LibraryDetailsType.artist) {
      return _ArtistHero(details: details);
    }
    return _PlaylistHero(details: details);
  }
}

class _PlaylistHero extends StatelessWidget {
  const _PlaylistHero({required this.details});
  final LibraryDetailsModel details;

  @override
  Widget build(BuildContext context) {
    if (details.isStaticPlaylist) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(details.title, style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(
              details.subtitlePrimary,
              style: AppTextStyles.caption.copyWith(color: AppColors.silver),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: _Cover(
            item: details.item,
            size: LibraryDetailsLayout.heroCoverSize,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(details.title, style: AppTextStyles.sectionTitle),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              _CircleButton(icon: Icons.add),
              const SizedBox(width: AppSpacing.sm),
              CircleAvatar(
                radius: LibraryDetailsLayout.ownerAvatarRadius,
                backgroundColor: AppColors.darkSurface,
                child: Icon(
                  Icons.person,
                  color: AppColors.silver,
                  size: LibraryDetailsLayout.ownerAvatarIconSize,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(details.subtitlePrimary, style: AppTextStyles.bodyBold),
            ],
          ),
        ),
        if (details.subtitleSecondary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Icon(
                  Icons.language,
                  size: LibraryDetailsLayout.metaGlobeIconSize,
                  color: AppColors.silver,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  details.subtitleSecondary,
                  style: AppTextStyles.small.copyWith(color: AppColors.silver),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ArtistHero extends StatelessWidget {
  const _ArtistHero({required this.details});
  final LibraryDetailsModel details;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: LibraryDetailsLayout.artistHeroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ArtworkOrGradient(imageUrl: details.heroImageUrl),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.nearBlack],
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.title,
                  style: AppTextStyles.sectionTitle.copyWith(
                    fontSize: LibraryDetailsLayout.artistNameFontSize,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  details.subtitlePrimary,
                  style: AppTextStyles.body.copyWith(color: AppColors.silver),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistActionBar extends StatelessWidget {
  const _PlaylistActionBar({required this.details});
  final LibraryDetailsModel details;

  @override
  Widget build(BuildContext context) {
    final isStatic = details.isStaticPlaylist;
    return Row(
      children: [
        if (!isStatic) ...[
          _MiniCover(item: details.item),
          const SizedBox(width: AppSpacing.sm),
        ],
        _ActionIcon(icon: AppIcons.download),
        _ActionIcon(icon: AppIcons.share),
        _ActionIcon(icon: AppIcons.moreVert),
        const Spacer(),
        Icon(
          Icons.shuffle_rounded,
          color: AppColors.brandGreen,
          size: LibraryDetailsLayout.shuffleIconSize,
        ),
        const SizedBox(width: AppSpacing.lg),
        TunifyPlayCircleButton(
          diameter: LibraryDetailsLayout.playButtonDiameter,
          iconSize: LibraryDetailsLayout.playButtonIconSize,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _ArtistActionBar extends StatelessWidget {
  const _ArtistActionBar({required this.details});
  final LibraryDetailsModel details;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MiniCover(item: details.item),
        const SizedBox(width: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.lightBorder),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            details.subtitleSecondary,
            style: AppTextStyles.smallBold,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _ActionIcon(icon: AppIcons.moreVert),
        const Spacer(),
        Icon(
          Icons.shuffle_rounded,
          color: AppColors.brandGreen,
          size: LibraryDetailsLayout.shuffleIconSize,
        ),
        const SizedBox(width: AppSpacing.lg),
        TunifyPlayCircleButton(
          diameter: LibraryDetailsLayout.playButtonDiameter,
          iconSize: LibraryDetailsLayout.playButtonIconSize,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _ChipPill extends StatelessWidget {
  const _ChipPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final icon = switch (label) {
      'Add' => Icons.add,
      'Edit' => Icons.menu,
      'Sort' => Icons.swap_vert,
      _ => Icons.edit_outlined,
    };
    return Container(
      height: LibraryDetailsLayout.chipPillHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.midDark,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: AppColors.white, size: LibraryDetailsLayout.chipIconSize),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontSize: LibraryDetailsLayout.chipLabelFontSize,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddToPlaylistRow extends StatelessWidget {
  const _AddToPlaylistRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: LibraryDetailsLayout.addRowLeadingSize,
          height: LibraryDetailsLayout.addRowLeadingSize,
          color: AppColors.darkSurface,
          child: Icon(
            Icons.add,
            color: AppColors.silver,
            size: LibraryDetailsLayout.addRowPlusIconSize,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          LibraryStrings.addToThisPlaylist,
          style: AppTextStyles.body.copyWith(color: AppColors.white),
        ),
      ],
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({
    required this.track,
    required this.item,
  });

  final LibraryDetailsTrack track;
  final LibraryItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _MiniCover(
          item: item,
          size: LibraryDetailsLayout.trackRowArtSize,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyBold.copyWith(
                  fontSize: LibraryDetailsLayout.trackTitleFontSize,
                ),
              ),
              SizedBox(height: LibraryDetailsLayout.trackTitleSubtitleGap),
              Text(
                track.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.small.copyWith(color: AppColors.silver),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppIcon(
          icon: AppIcons.moreVert,
          color: AppColors.silver,
          size: LibraryDetailsLayout.trackMoreIconSize,
        ),
      ],
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({
    required this.item,
    required this.size,
  });

  final LibraryItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final r = LibraryDetailsLayout.heroCoverCornerRadius;
    final child = item.systemArtwork != null
        ? SystemArtwork(type: item.systemArtwork!, size: size, borderRadius: r)
        : ArtworkOrGradient(imageUrl: item.imageUrl);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        boxShadow: [
          BoxShadow(
            color: LibraryDetailsLayout.heroCoverShadowColor,
            blurRadius: LibraryDetailsLayout.heroCoverShadowBlur,
            offset:
                const Offset(0, LibraryDetailsLayout.heroCoverShadowOffsetY),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: child,
      ),
    );
  }
}

class _MiniCover extends StatelessWidget {
  const _MiniCover({
    required this.item,
    this.size = LibraryDetailsLayout.miniCoverDefaultSize,
  });

  final LibraryItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final r = LibraryDetailsLayout.miniCoverCornerRadius;
    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: SizedBox(
        width: size,
        height: size,
        child: item.systemArtwork != null
            ? SystemArtwork(
                type: item.systemArtwork!,
                size: size,
                borderRadius: r,
              )
            : ArtworkOrGradient(imageUrl: item.imageUrl),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon});
  final List<List<dynamic>> icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {},
      icon: AppIcon(
        icon: icon,
        color: AppColors.silver,
        size: LibraryDetailsLayout.toolbarActionIconSize,
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: LibraryDetailsLayout.circleActionSize,
      height: LibraryDetailsLayout.circleActionSize,
      child: Material(
        color: AppColors.midDark,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {},
          child: Icon(
            icon,
            size: LibraryDetailsLayout.circleActionIconSize,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
