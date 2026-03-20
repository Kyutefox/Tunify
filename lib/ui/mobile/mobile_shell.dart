import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_icons.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/connectivity_provider.dart';
import '../../shared/providers/home_state_provider.dart';
import '../../shared/providers/library_provider.dart';
import '../../shared/providers/player_state_provider.dart';
import '../../shared/providers/search_provider.dart';
import '../components/ui/sheet.dart';
import '../components/ui/widgets/mini_player.dart';
import '../layout/shell_context.dart';
import '../screens/home_screen.dart';
import '../screens/library/create_library_item_screen.dart';
import '../screens/library_screen.dart';
import '../screens/loading_screen.dart';
import '../screens/search_screen.dart';
import '../theme/app_colors.dart';

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
    AppIcons.add,
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
              duration: const Duration(milliseconds: 300),
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

  void _showCreateSheet() {
    showAppSheet(
      context,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: kSheetHorizontalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetOptionTile(
              icon: AppIcons.playlistAdd,
              label: 'Create playlist',
              showChevron: false,
              onTap: () async {
                Navigator.of(context).pop();
                final name = await Navigator.of(context).push<String>(
                  MaterialPageRoute<String>(
                    builder: (_) => const CreateLibraryItemScreen(
                      mode: CreateLibraryItemMode.createPlaylist,
                    ),
                  ),
                );
                if (name != null && name.trim().isNotEmpty && mounted) {
                  await ref
                      .read(libraryProvider.notifier)
                      .createPlaylist(name.trim());
                }
              },
            ),
            SheetOptionTile(
              icon: AppIcons.newFolder,
              label: 'Create folder',
              showChevron: false,
              onTap: () async {
                Navigator.of(context).pop();
                final name = await Navigator.of(context).push<String>(
                  MaterialPageRoute<String>(
                    builder: (_) => const CreateLibraryItemScreen(
                      mode: CreateLibraryItemMode.createFolder,
                    ),
                  ),
                );
                if (name != null && name.trim().isNotEmpty && mounted) {
                  await ref
                      .read(libraryProvider.notifier)
                      .createFolder(name.trim());
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBar() {
    const navToPage = [0, 1, 2, -1];
    const pageToNav = [0, 1, 2];

    final activeNavIndex =
        _selectedIndex >= 0 && _selectedIndex < pageToNav.length
            ? pageToNav[_selectedIndex]
            : 0;

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
        padding:
            EdgeInsets.only(bottom: bottomPadding > 0 ? bottomPadding : 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(4, (i) {
            final selected = activeNavIndex == i;
            final isCreate = i == 3;

            return Expanded(
              child: isCreate
                  ? _NavCreateButton(onTap: _showCreateSheet)
                  : _NavItem(
                      icon: _navIcons[i],
                      selected: selected,
                      onTap: () {
                        final pageIndex = navToPage[i];
                        if (pageIndex < 0) return;
                        if (_selectedIndex == 1 && pageIndex != 1) {
                          ref.read(searchProvider.notifier).search('');
                        }
                        final wasOnHome = _selectedIndex == 0;
                        setState(() => _selectedIndex = pageIndex);
                        if (pageIndex == 0 && !wasOnHome) {
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

    if (isOnline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orangeAccent.withValues(alpha: 0.12),
      child: const Row(
        children: [
          Icon(Icons.wifi_off, size: 18, color: Colors.orangeAccent),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "You're offline — some features may be limited",
              style: TextStyle(color: Colors.orangeAccent, fontSize: 13),
            ),
          ),
        ],
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

class _NavCreateButton extends StatelessWidget {
  const _NavCreateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.primary.withValues(alpha: 0.3),
          highlightColor: AppColors.primary.withValues(alpha: 0.2),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: AppIcon(
                icon: AppIcons.add,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
