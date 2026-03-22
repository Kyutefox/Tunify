import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/features/auth/auth_provider.dart';
import 'package:tunify/features/settings/connectivity_provider.dart';
import 'package:tunify/features/home/home_state_provider.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/features/search/search_provider.dart';
import 'package:tunify/ui/widgets/items/mini_player.dart';
import 'package:tunify/ui/shell/shell_context.dart';
import 'package:tunify/ui/screens/home/home_screen.dart';
import '../screens/library_screen.dart';
import '../screens/loading_screen.dart';
import '../screens/search_screen.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';

/// Standard mobile shell: bottom nav bar + mini player + IndexedStack.
///
/// Used on iOS and Android. Wraps the tree with [ShellContext(isDesktop: false)]
/// so descendant screens and widgets can adapt their chrome accordingly.
class MobileShell extends ConsumerStatefulWidget {
  const MobileShell({super.key});

  @override
  ConsumerState<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends ConsumerState<MobileShell> {
  /// Page index: 0=Home, 1=Search, 2=Library
  int _selectedIndex = 0;

  static final _navIcons = [
    AppIcons.home,
    AppIcons.search,
    AppIcons.library,
  ];

  @override
  Widget build(BuildContext context) {
    final isGuest = ref.watch(guestModeProvider);
    final homeIsLoading = ref.watch(homeIsLoadingProvider);
    final homeIsLoaded = ref.watch(homeIsLoadedProvider);
    final hasSong = ref.watch(currentSongProvider) != null;

    final showGuestHomeFullScreenLoading =
        isGuest && _selectedIndex == 0 && homeIsLoading && !homeIsLoaded;

    if (showGuestHomeFullScreenLoading) {
      return ShellContext(
        isDesktop: false,
        child: const Scaffold(
          backgroundColor: AppColors.background,
          body: LoadingScreen(),
        ),
      );
    }

    return ShellContext(
      isDesktop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            const _OfflineBanner(),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: const [HomeScreen(), SearchScreen(), LibraryScreen()],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: AppDuration.fast,
              transitionBuilder: (child, anim) => SizeTransition(
                sizeFactor: CurvedAnimation(
                  parent: anim,
                  curve: Curves.easeOut,
                ),
                axisAlignment: -1,
                child: child,
              ),
              child: hasSong
                  ? const MiniPlayer(key: ValueKey('mini-player'))
                  : const SizedBox.shrink(key: ValueKey('hidden')),
            ),
            _buildNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 56 + bottomPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding > 0 ? bottomPadding : 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(3, (i) {
            final selected = _selectedIndex == i;
            return Expanded(
              child: _NavItem(
                icon: _navIcons[i],
                selected: selected,
                onTap: () {
                  if (_selectedIndex == 1 && i != 1) {
                    ref.read(searchProvider.notifier).search('');
                  }
                  final wasOnHome = _selectedIndex == 0;
                  setState(() => _selectedIndex = i);
                  if (i == 0 && !wasOnHome) {
                    ref.read(homeProvider.notifier).refresh();
                  }
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Isolated widgets ──────────────────────────────────────────────────────────

class _OfflineBanner extends ConsumerWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider).maybeWhen(
          data: (connected) => connected,
          orElse: () => true,
        );

    return AnimatedSwitcher(
      duration: AppDuration.normal,
      transitionBuilder: (child, anim) => SizeTransition(
        sizeFactor: CurvedAnimation(parent: anim, curve: AppCurves.decelerate),
        axisAlignment: -1,
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: isOnline
          ? const SizedBox.shrink(key: ValueKey('online'))
          : Container(
              key: const ValueKey('offline'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base, vertical: AppSpacing.sm),
              color: Colors.orangeAccent.withValues(alpha: 0.12),
              child: Row(
                children: [
                  AppIcon(icon: AppIcons.wifiOff, size: 18, color: Colors.orangeAccent),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      "You're offline — some features may be limited",
                      style:
                          TextStyle(color: Colors.orangeAccent, fontSize: AppFontSize.md),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final bool selected;
  final VoidCallback onTap;

  static const double _iconSize = 24.0;
  static const double _circleSize = 40.0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: AppColors.primary.withValues(alpha: 0.12),
          highlightColor: AppColors.primary.withValues(alpha: 0.06),
          child: SizedBox(
            width: _circleSize,
            height: _circleSize,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: _circleSize,
                height: _circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : Colors.transparent,
                ),
                child: Center(
                  child: AppIcon(
                    icon: icon,
                    color: selected ? AppColors.primary : AppColors.textMuted,
                    size: _iconSize,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
