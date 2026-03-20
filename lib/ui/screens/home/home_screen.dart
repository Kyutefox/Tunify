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
          // Desktop has its own top bar — skip the mobile app bar.
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
                    const SliverToBoxAdapter(child: _DesktopGreetingHeader()),
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

// ── Desktop-only greeting header ──────────────────────────────────────────────

class _DesktopGreetingHeader extends ConsumerWidget {
  const _DesktopGreetingHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = ref.watch(greetingProvider);
    final user = ref.watch(currentUserProvider);
    final isGuest = ref.watch(guestModeProvider);
    final guestUsername = isGuest ? ref.watch(guestUsernameProvider).value : null;
    final username = (user?.userMetadata?['username'] as String?) ??
        (user?.email?.split('@').first) ??
        (isGuest ? (guestUsername ?? 'Guest') : '');

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: Text(
              username.isNotEmpty ? '$greeting, $username' : greeting,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Home',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
