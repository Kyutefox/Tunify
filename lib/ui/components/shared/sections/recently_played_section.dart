import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_icons.dart';
import '../../../../models/song.dart';
import '../../../../shared/providers/home_state_provider.dart';
import '../../../../ui/screens/home/recently_played_screen.dart';
import '../../../../ui/theme/app_colors.dart';
import '../../../../ui/theme/design_tokens.dart';
import '../../../../ui/theme/app_routes.dart';
import '../../ui/widgets/section_header.dart';
import '../../../../ui/layout/shell_context.dart';
import '../../../../ui/desktop/desktop_right_sidebar.dart';

class RecentlyPlayedSection extends ConsumerStatefulWidget {
  const RecentlyPlayedSection({super.key, required this.onPlay});
  final void Function(Song song) onPlay;

  @override
  ConsumerState<RecentlyPlayedSection> createState() =>
      _RecentlyPlayedSectionState();
}

class _RecentlyPlayedSectionState extends ConsumerState<RecentlyPlayedSection> {
  final _pageCtrl = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl.addListener(() {
      final p = _pageCtrl.page?.round() ?? 0;
      if (p != _page) setState(() => _page = p);
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songs = ref.watch(recentlyPlayedProvider);
    if (songs.isEmpty) return const SizedBox(height: AppSpacing.sm);

    final isDesktop = ShellContext.isDesktopOf(context);
    final hPad = isDesktop ? AppSpacing.xl : AppSpacing.base;
    const gap = AppSpacing.md;

    final double maxWidth;
    final int cols;
    if (isDesktop) {
      final rightOpen = ref.watch(rightSidebarTabProvider) != null;
      final screenW = MediaQuery.sizeOf(context).width;
      maxWidth = ShellContext.desktopContentInnerWidth(
        screenWidth: screenW,
        rightSidebarOpen: rightOpen,
        hPad: hPad,
      );
      cols = (maxWidth / 160).floor().clamp(2, 5);
    } else {
      maxWidth = MediaQuery.sizeOf(context).width - hPad * 2;
      cols = 2;
    }

    final hasOverflow = songs.length > cols;
    final tileW = ((maxWidth - gap * (cols - 1)) / cols).floorToDouble();
    final tileH = tileW + 40.0;

    final pageItems = songs.take(cols).toList();
    final overflowPage = hasOverflow
        ? songs.sublist(cols).take(cols).toList()
        : <Song>[];

    Widget buildRow(List<Song> items) => Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              SizedBox(
                width: tileW,
                child: _RecentSongCard(
                  song: items[i],
                  size: tileW,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onPlay(items[i]);
                  },
                ),
              ),
            ],
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        SectionHeader(
          title: 'Recently Played',
          useCompactStyle: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasOverflow) ...[
                _NavBtn(
                  icon: AppIcons.back,
                  enabled: _page > 0,
                  onTap: () => _pageCtrl.animateToPage(0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut),
                ),
                const SizedBox(width: AppSpacing.xs),
                _NavBtn(
                  icon: AppIcons.forward,
                  enabled: _page == 0,
                  onTap: () => _pageCtrl.animateToPage(1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  appPageRoute<void>(
                    builder: (_) => const RecentlyPlayedScreen(),
                  ),
                ),
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppFontSize.md,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: hasOverflow
              ? _RecentlyPlayedPager(
                  height: tileH,
                  controller: _pageCtrl,
                  pages: [buildRow(pageItems), buildRow(overflowPage)],
                )
              : buildRow(pageItems),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _RecentlyPlayedPager extends StatelessWidget {
  const _RecentlyPlayedPager({
    required this.height,
    required this.controller,
    required this.pages,
  });
  final double height;
  final PageController controller;
  final List<Widget> pages;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: PageView(
        controller: controller,
        children: pages,
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.onTap, this.enabled = true});
  final List<List<dynamic>> icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.surfaceLight
              : AppColors.surfaceLight.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AppIcon(
            icon: icon,
            size: 14,
            color: enabled ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _RecentSongCard extends StatelessWidget {
  const _RecentSongCard({
    required this.song,
    required this.onTap,
    required this.size,
  });
  final Song song;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: CachedNetworkImage(
              imageUrl: song.thumbnailUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: size,
                height: size,
                color: AppColors.surfaceLight,
              ),
              errorWidget: (_, __, ___) => Container(
                width: size,
                height: size,
                color: AppColors.surfaceLight,
                child: AppIcon(
                  icon: AppIcons.musicNote,
                  color: AppColors.textMuted,
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            song.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppFontSize.md,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            song.artist,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: AppFontSize.xs,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}


