import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/song.dart';
import '../../../shared/providers/home_state_provider.dart';
import '../../../shared/providers/player_state_provider.dart';
import '../../layout/shell_context.dart';
import '../../theme/app_colors.dart';
import 'home_app_bar.dart';
import 'home_content.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/guest_profile_provider.dart';
import '../../theme/design_tokens.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeProvider.notifier).loadContent();
    });
  }

  void _play(Song song) {
    ref.read(playerProvider.notifier).playSong(song);
  }

  @override
  Widget build(BuildContext context) {
    final greeting = ref.watch(greetingProvider);

    final isDesktop = ShellContext.isDesktopOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isDesktop) HomeAppBar(greeting: greeting, asSliver: false),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(homeProvider.notifier).refresh();
              },
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              strokeWidth: 2.5,
              displacement: 80,
              child: CustomScrollView(
                cacheExtent: 500,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  if (isDesktop)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _DesktopGreetingDelegate(),
                    ),
                  HomeContent(onPlay: _play),
                  SliverToBoxAdapter(
                    child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Desktop sticky greeting header ───────────────────────────────────────────

class _DesktopGreetingDelegate extends SliverPersistentHeaderDelegate {
  static const double _height = 48.0;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _DesktopGreetingHeader(overlaps: overlapsContent || shrinkOffset > 0);
  }

  @override
  bool shouldRebuild(_DesktopGreetingDelegate old) => false;
}

class _DesktopGreetingHeader extends ConsumerWidget {
  const _DesktopGreetingHeader({this.overlaps = false});
  final bool overlaps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = ref.watch(greetingProvider);
    final user = ref.watch(currentUserProvider);
    final isGuest = ref.watch(guestModeProvider);
    final guestUsername = isGuest ? ref.watch(guestUsernameProvider).value : null;
    final username = (user?.userMetadata?['username'] as String?) ??
        (user?.email?.split('@').first) ??
        (isGuest ? (guestUsername ?? 'Guest') : '');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: overlaps ? AppColors.background.withValues(alpha: 0.95) : AppColors.background,
        border: overlaps
            ? Border(bottom: BorderSide(color: AppColors.surfaceLight, width: 0.5))
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, 0),
      alignment: Alignment.centerLeft,
      child: ShaderMask(
        shaderCallback: (bounds) =>
            AppColors.primaryGradient.createShader(bounds),
        child: Text(
          username.isNotEmpty ? '$greeting, $username' : greeting,
          style: const TextStyle(
            color: Colors.white,
            fontSize: AppFontSize.base,
            fontWeight: FontWeight.w600,
            letterSpacing: AppLetterSpacing.normal,
          ),
        ),
      ),
    );
  }
}
