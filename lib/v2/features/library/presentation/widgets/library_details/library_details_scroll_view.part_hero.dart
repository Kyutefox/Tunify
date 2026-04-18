part of 'library_details_scroll_view.dart';

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.details,
    required this.titleMeasureKey,
    required this.appBarUnderlapHeight,
  });

  final LibraryDetailsModel details;
  final GlobalKey titleMeasureKey;
  final double appBarUnderlapHeight;

  @override
  Widget build(BuildContext context) {
    if (details.type == LibraryDetailsType.artist) {
      return _ArtistHero(
        details: details,
        titleMeasureKey: titleMeasureKey,
        statusAndAppBarUnderlap: appBarUnderlapHeight,
      );
    }
    return _PlaylistHero(
      details: details,
      titleMeasureKey: titleMeasureKey,
    );
  }
}

class _PlaylistOwnerAvatar extends ConsumerWidget {
  const _PlaylistOwnerAvatar({required this.details});

  final LibraryDetailsModel details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = LibraryDetailsLayout.ownerAvatarRadius;
    final d = r * 2;
    final url = details.ownerAvatarUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: d,
          height: d,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 150),
            placeholder: (_, __) =>
                const ColoredBox(color: AppColors.darkSurface),
            errorWidget: (_, __, ___) => ColoredBox(
              color: AppColors.darkSurface,
              child: Icon(
                Icons.person,
                color: AppColors.silver,
                size: LibraryDetailsLayout.ownerAvatarIconSize,
              ),
            ),
          ),
        ),
      );
    }

    final item = details.item;
    final useSessionAvatar = item.kind == LibraryItemKind.playlist &&
        (item.isUserOwnedPlaylist ||
            item.creatorName == LibraryKnownCreators.you);
    if (useSessionAvatar) {
      final user =
          ref.watch(authSessionProvider).whenOrNull(data: (value) => value);
      final sessionUrl = avatarUrlFromUser(user);
      if (sessionUrl != null && sessionUrl.isNotEmpty) {
        return ClipOval(
          child: SizedBox(
            width: d,
            height: d,
            child: NetworkAvatarImage(
              url: sessionUrl,
              fallbackIconSize: LibraryDetailsLayout.ownerAvatarIconSize,
            ),
          ),
        );
      }
    }

    return CircleAvatar(
      radius: r,
      backgroundColor: AppColors.darkSurface,
      child: Icon(
        Icons.person,
        color: AppColors.silver,
        size: LibraryDetailsLayout.ownerAvatarIconSize,
      ),
    );
  }
}

class _PlaylistHero extends StatelessWidget {
  const _PlaylistHero({
    required this.details,
    required this.titleMeasureKey,
  });

  final LibraryDetailsModel details;
  final GlobalKey titleMeasureKey;

  @override
  Widget build(BuildContext context) {
    if (details.isStaticPlaylist) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              key: titleMeasureKey,
              details.title,
              style: AppTextStyles.sectionTitle,
            ),
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
            details: details,
            size: LibraryDetailsLayout.heroCoverSize,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            key: titleMeasureKey,
            details.title,
            style: AppTextStyles.sectionTitle,
          ),
        ),
        if (details.collectionDescription != null &&
            details.collectionDescription!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              details.collectionDescription!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.silver,
                height: 1.35,
              ),
            ),
          ),
        ],
        if (details.typeSubtitle != null && details.typeSubtitle!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              details.typeSubtitle!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.silver,
                height: 1.35,
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              if (!details.item.isEphemeralHomeTrackShelf) ...[
                _CircleButton(icon: Icons.add),
                const SizedBox(width: AppSpacing.sm),
              ],
              _PlaylistOwnerAvatar(details: details),
              const SizedBox(width: AppSpacing.sm),
              Text(details.subtitlePrimary, style: AppTextStyles.bodyBold),
            ],
          ),
        ),
      ],
    );
  }
}

class _ArtistHero extends StatelessWidget {
  const _ArtistHero({
    required this.details,
    required this.titleMeasureKey,
    required this.statusAndAppBarUnderlap,
  });

  final LibraryDetailsModel details;
  final GlobalKey titleMeasureKey;

  /// Pushes hero artwork under the transparent app bar / status inset (artist only).
  final double statusAndAppBarUnderlap;

  @override
  Widget build(BuildContext context) {
    final totalHeight =
        LibraryDetailsLayout.artistHeroHeight + statusAndAppBarUnderlap;
    return SizedBox(
      height: totalHeight,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.nearBlack,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: ArtworkOrGradient(
                      imageUrl: details.heroImageUrl,
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                    ),
                  );
                },
              ),
            ),
          ),
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
                  key: titleMeasureKey,
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

class _Cover extends StatelessWidget {
  const _Cover({
    required this.details,
    required this.size,
  });

  final LibraryDetailsModel details;
  final double size;

  @override
  Widget build(BuildContext context) {
    final r = LibraryDetailsLayout.heroCoverCornerRadius;
    final child = LibraryCollectionArtwork(
      item: details.item,
      preferredImageUrl: details.heroImageUrl,
      size: size,
      borderRadius: r,
      tracks: details.item.isUserOwnedPlaylist ? details.tracks : null,
    );

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
