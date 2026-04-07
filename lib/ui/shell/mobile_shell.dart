import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/features/auth/auth_provider.dart';
import 'package:tunify/features/settings/connectivity_provider.dart';
import 'package:tunify/features/home/home_state_provider.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/features/search/search_provider.dart';
import 'package:tunify/features/podcast/podcast_provider.dart';
import 'package:tunify/ui/widgets/player/mini_player.dart';
import 'package:tunify/ui/shell/shell_context.dart';
import 'package:tunify/ui/screens/desktop/home/home_screen.dart';
import '../screens/shared/library/library_screen.dart';
import '../screens/shared/auth/loading_screen.dart';
import '../screens/shared/search/search_screen.dart';
import '../screens/shared/podcast/podcast_screen.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

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
  /// Page index: 0=Home, 1=Search, 2=Library, 3=Podcasts
  int _selectedIndex = 0;

  static final _navIcons = [
    AppIcons.home,
    AppIcons.search,
    AppIcons.library,
    AppIcons.podcast,
  ];

  static const _navLabels = ['Home', 'Search', 'Library', 'Podcasts'];

  @override
  Widget build(BuildContext context) {
    final isGuest = ref.watch(guestModeProvider);
    final homeIsLoaded = ref.watch(homeIsLoadedProvider);
    final homeIsInitialLoading = ref.watch(homeIsInitialLoadingProvider);
    final hasSong = ref.watch(currentSongProvider) != null;

    final showGuestHomeFullScreenLoading =
        isGuest && _selectedIndex == 0 && homeIsInitialLoading && !homeIsLoaded;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayStyle = isDark
        ? const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          )
        : const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          );

    if (showGuestHomeFullScreenLoading) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: ShellContext(
          isDesktop: false,
          child: Scaffold(
            backgroundColor: AppColorsScheme.of(context).background,
            body: LoadingScreen(),
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: ShellContext(
        isDesktop: false,
        child: Scaffold(
          backgroundColor: AppColorsScheme.of(context).background,
          body: Column(
            children: [
              const _OfflineBanner(),
              Expanded(
                child: _buildCurrentScreen(),
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
      ), // ShellContext
    ); // AnnotatedRegion
  }

  Widget _buildCurrentScreen() {
    // IndexedStack keeps all three screens alive in the element tree so that
    // scroll positions, loaded data, and local state survive tab switches.
    // Off-screen children are Offstage: no painting, no hit-testing, but full
    // widget state preserved. Memory cost (~3× widget tree) is the intentional
    // trade-off for zero-flash, zero-rebuild tab navigation.
    return IndexedStack(
      index: _selectedIndex,
      children: const [
        HomeScreen(),
        SearchScreen(),
        LibraryScreen(),
        PodcastScreen(),
      ],
    );
  }

  Widget _buildNavBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 64 + bottomPadding,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color:
                AppColorsScheme.of(context).textPrimary.withValues(alpha: 0.10),
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding > 0 ? bottomPadding : 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(4, (i) {
            final selected = _selectedIndex == i;
            return Expanded(
              child: _NavItem(
                icon: _navIcons[i],
                label: _navLabels[i],
                selected: selected,
                onTap: () {
                  if (_selectedIndex == 1 && i != 1) {
                    ref.read(searchProvider.notifier).search('');
                  }
                  if (i == 3 && _selectedIndex != 3) {
                    ref.read(podcastProvider.notifier).load();
                  }
                  final wasOnHome = _selectedIndex == 0;
                  setState(() => _selectedIndex = i);
                  if (i == 0 && !wasOnHome) {
                    ref.read(homeProvider.notifier).visitHomepage();
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
                  AppIcon(
                      icon: AppIcons.wifiOff,
                      size: 18,
                      color: Colors.orangeAccent),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      "You're offline — some features may be limited",
                      style: TextStyle(
                          color: Colors.orangeAccent, fontSize: AppFontSize.md),
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
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const double _iconSize = 24.0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          splashColor: AppColors.primary.withValues(alpha: 0.12),
          highlightColor: AppColors.primary.withValues(alpha: 0.06),
          child: SizedBox(
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(
                  icon: icon,
                  color: selected
                      ? AppColorsScheme.of(context).textPrimary
                      : AppColorsScheme.of(context).textMuted,
                  size: _iconSize,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? AppColorsScheme.of(context).textPrimary
                        : AppColorsScheme.of(context).textMuted,
                    fontSize: AppFontSize.xs,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
