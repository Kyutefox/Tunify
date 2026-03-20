import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/home_state_provider.dart';
import '../../shared/providers/library_provider.dart';
import '../../shared/providers/search_provider.dart';
import '../layout/shell_context.dart';
import '../screens/home_screen.dart';
import '../screens/library/create_library_item_screen.dart';
import '../screens/library_screen.dart';
import '../screens/search_screen.dart';
import '../theme/app_colors.dart';
import 'desktop_player_bar.dart';
import 'desktop_search_dropdown.dart';
import 'desktop_sidebar.dart';
import 'desktop_top_bar.dart';

/// Top-level shell for the macOS desktop layout.
///
/// Layout (Spotify-inspired):
/// ```
/// ┌─────────────────────────────────────────────────┐
/// │           DesktopTopBar  (64 px)                 │
/// ├──────────────┬──────────────────────────────────┤
/// │  Sidebar     │  Content Navigator                │
/// │  300 px      │  Home · Search · Library          │
/// │              │  + detail pages pushed in-place   │
/// ├──────────────┴──────────────────────────────────┤
/// │           DesktopPlayerBar  (92 px)              │
/// └─────────────────────────────────────────────────┘
/// ```
///
/// The main content area is a nested [Navigator] so that detail pages
/// (playlists, albums, artists, liked songs) render inside the content
/// panel rather than full-screen. [Navigator.pop] works naturally inside
/// those pages; the top-bar back button pops the same navigator.
class DesktopShell extends ConsumerStatefulWidget {
  const DesktopShell({super.key});

  @override
  ConsumerState<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<DesktopShell> {
  /// 0 = Home · 1 = Search (unused on desktop) · 2 = Library
  int _selectedIndex = 0;

  final List<int> _history = [0];
  final List<int> _future = [];

  // ── Search overlay ───────────────────────────────────────────────────────────
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _searchOverlayOpen = false;

  /// Drives tab switches inside the nested Navigator's initial route.
  final _tabIndexNotifier = ValueNotifier<int>(0);

  /// Key for the nested Navigator in the main content area.
  final _contentNavKey = GlobalKey<NavigatorState>();

  /// Rebuilds the shell whenever the nested Navigator pushes/pops so that
  /// [_canGoBack] / [_canGoForward] stay accurate in the top bar.
  late final _ContentNavObserver _contentNavObserver =
      _ContentNavObserver(() {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      });

  bool get _contentCanPop =>
      _contentNavKey.currentState?.canPop() ?? false;

  bool get _canGoBack => _contentCanPop || _history.length > 1;

  /// Forward only makes sense when no detail page is on the stack.
  bool get _canGoForward => _future.isNotEmpty && !_contentCanPop;

  @override
  void dispose() {
    _tabIndexNotifier.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openSearchOverlay() {
    if (!_searchOverlayOpen) setState(() => _searchOverlayOpen = true);
  }

  void _closeSearchOverlay() {
    if (!_searchOverlayOpen) return;
    setState(() => _searchOverlayOpen = false);
    _searchController.clear();
    _searchFocusNode.unfocus();
    ref.read(searchProvider.notifier).search('');
  }

  // ── Tab navigation ──────────────────────────────────────────────────────────

  void _navigateTo(int index) {
    // Close search overlay whenever navigating.
    if (_searchOverlayOpen) _closeSearchOverlay();

    // Pop all detail pages so we land on the tabs layer.
    _contentNavKey.currentState?.popUntil((r) => r.isFirst);

    if (index == _selectedIndex) return;

    if (_selectedIndex == 1 && index != 1) {
      ref.read(searchProvider.notifier).search('');
    }

    final wasOnHome = _selectedIndex == 0;
    _future.clear();
    _history.add(index);
    setState(() => _selectedIndex = index);
    _tabIndexNotifier.value = index;

    if (index == 0 && !wasOnHome) {
      ref.read(homeProvider.notifier).refresh();
    }
  }

  void _goBack() {
    // If a detail page is showing, pop it inside the content navigator.
    if (_contentCanPop) {
      _contentNavKey.currentState?.pop();
      return;
    }

    if (!_canGoBack) return;
    final current = _history.removeLast();
    _future.insert(0, current);
    final prev = _history.last;

    if (_selectedIndex == 1 && prev != 1) {
      ref.read(searchProvider.notifier).search('');
    }

    setState(() => _selectedIndex = prev);
    _tabIndexNotifier.value = prev;
  }

  void _goForward() {
    if (!_canGoForward) return;
    final next = _future.removeAt(0);
    _history.add(next);

    if (_selectedIndex == 1 && next != 1) {
      ref.read(searchProvider.notifier).search('');
    }

    setState(() => _selectedIndex = next);
    _tabIndexNotifier.value = next;
  }

  // ── Detail navigation (called from sidebar) ─────────────────────────────────

  void _pushDetail(Widget page) {
    _contentNavKey.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  static const double _gap = 8;
  static const double _radius = 12;
  static const double _topBarHeight = 64;

  // Dropdown aligns exactly with the search bar in DesktopTopBar.
  // Left  = outer gap + sidebar + panel gap + home btn (40) + home→search gap (8)
  static const double _dropdownLeft =
      _gap + kDesktopSidebarWidth + _gap + 40 + 8;
  // Right = outer gap + content right padding (16) + search→avatar gap (12) + avatar (36)
  static const double _dropdownRight = _gap + 16 + 12 + 36;

  @override
  Widget build(BuildContext context) {
    return ShellContext(
      isDesktop: true,
      child: Scaffold(
        // True-black canvas — visible in the gaps between floating panels.
        backgroundColor: const Color(0xFF0A0A0A),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(_gap),
              child: Column(
                children: [
              // ── Nav bar — background-level panel (blends with canvas) ─────
              ClipRRect(
                borderRadius: BorderRadius.circular(_radius),
                child: DesktopTopBar(
                  selectedIndex: _selectedIndex,
                  canGoBack: _canGoBack,
                  canGoForward: _canGoForward,
                  onBack: _goBack,
                  onForward: _goForward,
                  onHomePressed: () => _navigateTo(0),
                  onSearchActivated: (_) => _openSearchOverlay(),
                  searchController: _searchController,
                  searchFocusNode: _searchFocusNode,
                  sidebarWidth: kDesktopSidebarWidth,
                  isSearchOverlayOpen: _searchOverlayOpen,
                ),
              ),

              const SizedBox(height: _gap),

              // ── Middle row: sidebar + main content ─────────────────────────
              Expanded(
                child: Row(
                  children: [
                    // Sidebar — elevated surface panel
                    ClipRRect(
                      borderRadius: BorderRadius.circular(_radius),
                      child: DesktopSidebar(
                        onCreatePlaylist: () => _showCreateDialog(
                            CreateLibraryItemMode.createPlaylist),
                        onCreateFolder: () => _showCreateDialog(
                            CreateLibraryItemMode.createFolder),
                        onNavigateTo: _pushDetail,
                      ),
                    ),

                    const SizedBox(width: _gap),

                    // Main content — elevated surface panel
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(_radius),
                        child: ColoredBox(
                          color: AppColors.surface,
                          child: Navigator(
                            key: _contentNavKey,
                            observers: [_contentNavObserver],
                            onGenerateRoute: (_) => MaterialPageRoute<void>(
                              builder: (_) => ValueListenableBuilder<int>(
                                valueListenable: _tabIndexNotifier,
                                builder: (_, idx, __) => IndexedStack(
                                  index: idx,
                                  children: const [
                                    HomeScreen(),
                                    SearchScreen(),
                                    LibraryScreen(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: _gap),

              // ── Player bar — background-level panel (same layer as nav) ────
              ClipRRect(
                borderRadius: BorderRadius.circular(_radius),
                child: const DesktopPlayerBar(),
              ),
                ],
              ),
            ),

            // ── Search overlay ───────────────────────────────────────────────
            if (_searchOverlayOpen) ...[
              // Dismiss barrier (covers everything except the search TapRegion)
              Positioned.fill(
                child: TapRegion(
                  groupId: 'desktop-search',
                  onTapOutside: (_) => _closeSearchOverlay(),
                  child: const SizedBox.expand(),
                ),
              ),
              // Dropdown panel — left/right match the search bar exactly.
              Positioned(
                top: _gap + _topBarHeight + _gap,
                left: _dropdownLeft,
                right: _dropdownRight,
                child: TapRegion(
                  groupId: 'desktop-search',
                  child: DesktopSearchDropdown(
                    onResultTapped: _closeSearchOverlay,
                    onQuerySelected: (q) {
                      _searchController.text = q;
                      _searchController.selection =
                          TextSelection.fromPosition(
                        TextPosition(offset: q.length),
                      );
                      ref.read(searchProvider.notifier).search(q);
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Opens the same [CreateLibraryItemScreen] used by the mobile shell so the
  /// creation flow is identical on both platforms.
  Future<void> _showCreateDialog(CreateLibraryItemMode mode) async {
    final name = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => CreateLibraryItemScreen(mode: mode),
      ),
    );
    if (name != null && name.trim().isNotEmpty && mounted) {
      if (mode == CreateLibraryItemMode.createPlaylist) {
        await ref.read(libraryProvider.notifier).createPlaylist(name.trim());
      } else {
        await ref.read(libraryProvider.notifier).createFolder(name.trim());
      }
    }
  }
}

// ── Navigator observer ────────────────────────────────────────────────────────

/// Notifies the shell whenever the content [Navigator] changes so the
/// back/forward button states stay accurate.
class _ContentNavObserver extends NavigatorObserver {
  _ContentNavObserver(this._onChanged);

  final VoidCallback _onChanged;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _onChanged();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _onChanged();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _onChanged();
}
