import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_icons.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/guest_profile_provider.dart';
import '../../shared/providers/search_provider.dart';
import '../screens/guest_profile_setup_screen.dart';
import '../screens/home/home_settings_sheet.dart';
import '../screens/home/home_shared.dart';
import '../screens/home/home_user_menu.dart';
import '../components/ui/sheet.dart';
import '../theme/app_colors.dart';

/// Full-width top bar spanning both sidebar and content area.
///
/// Layout:
///   [sidebarWidth: < > ⌂ centered]  [gap]  [Expanded: search centered · avatar]
///
/// The nav buttons are positioned directly above the sidebar and the search
/// bar is centred (max 460 px wide) above the main content panel.
class DesktopTopBar extends ConsumerStatefulWidget {
  const DesktopTopBar({
    super.key,
    required this.selectedIndex,
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
    required this.onHomePressed,
    required this.onSearchActivated,
    required this.searchController,
    required this.searchFocusNode,
    required this.sidebarWidth,
    this.isSearchOverlayOpen = false,
  });

  final int selectedIndex;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onHomePressed;

  /// Called when the user activates the search bar (shell opens overlay).
  final ValueChanged<String> onSearchActivated;

  /// Owned by the shell so it can programmatically update the text.
  final TextEditingController searchController;
  final FocusNode searchFocusNode;

  /// Width reserved for the nav-button section (must match sidebar width).
  final double sidebarWidth;

  /// Whether the search overlay is open — drives the active border style.
  final bool isSearchOverlayOpen;

  @override
  ConsumerState<DesktopTopBar> createState() => _DesktopTopBarState();
}

class _DesktopTopBarState extends ConsumerState<DesktopTopBar> {
  bool _hasFocus = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    widget.searchFocusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    final hasFocus = widget.searchFocusNode.hasFocus;
    setState(() => _hasFocus = hasFocus);
    if (hasFocus) widget.onSearchActivated('');
  }

  @override
  void didUpdateWidget(DesktopTopBar old) {
    super.didUpdateWidget(old);
    if (old.searchFocusNode != widget.searchFocusNode) {
      old.searchFocusNode.removeListener(_onFocusChanged);
      widget.searchFocusNode.addListener(_onFocusChanged);
    }
    if (old.selectedIndex == 1 && widget.selectedIndex != 1) {
      widget.searchController.clear();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    widget.searchFocusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onSubmit(String query) {
    widget.onSearchActivated(query);
    if (query.isNotEmpty) {
      ref.read(searchProvider.notifier).search(query);
    }
  }

  void _onChanged(String query) {
    widget.onSearchActivated(query);
    setState(() {}); // update clear-button visibility
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      if (mounted) ref.read(searchProvider.notifier).search(query);
    });
  }

  void _showUserMenu(BuildContext context, String username, String? email) {
    final isGuest = ref.read(guestModeProvider);
    showRawSheet(
      context,
      child: HomeUserMenuSheet(
        username: username,
        email: email,
        onSignOut: () async {
          Navigator.of(context).pop();
          if (isGuest) {
            ref.read(guestModeProvider.notifier).exitGuestMode();
          } else {
            await ref.read(authNotifierProvider.notifier).signOut();
          }
        },
        onSettings: () {
          Navigator.of(context).pop();
          showRawSheet(context, child: const HomeSettingsSheet());
        },
        onEditProfile: isGuest
            ? () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const GuestProfileSetupScreen(isInitial: false),
                  ),
                );
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isGuest = ref.watch(guestModeProvider);
    final guestUsername =
        isGuest ? ref.watch(guestUsernameProvider).value : null;
    final username = (user?.userMetadata?['username'] as String?) ??
        (user?.email?.split('@').first) ??
        (isGuest ? (guestUsername ?? 'Guest') : 'V');
    final avatarUrl =
        'https://api.dicebear.com/9.x/fun-emoji/png?seed=${Uri.encodeComponent(username)}&size=72';

    return Container(
      height: 64,
      color: AppColors.surface,
      child: Row(
        children: [
          // ── Back / Forward — sits above the sidebar ──────────────────────
          SizedBox(
            width: widget.sidebarWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NavArrowBtn(
                  icon: AppIcons.back,
                  enabled: widget.canGoBack,
                  onTap: widget.onBack,
                ),
                const SizedBox(width: 10),
                _NavArrowBtn(
                  icon: AppIcons.forward,
                  enabled: widget.canGoForward,
                  onTap: widget.onForward,
                ),
              ],
            ),
          ),

          // Gap that mirrors the 8 px gutter between sidebar and content
          const SizedBox(width: 8),

          // ── Main content section — home · search · avatar ────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  // Home button left of the search bar
                  _HomeBtn(
                    isActive: widget.selectedIndex == 0,
                    onTap: widget.onHomePressed,
                  ),
                  const SizedBox(width: 8),

                  // Search bar fills remaining space
                  Expanded(
                    child: TapRegion(
                      groupId: 'desktop-search',
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (_hasFocus || widget.isSearchOverlayOpen)
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.18),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            AppIcon(
                              icon: AppIcons.search,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: widget.searchController,
                                focusNode: widget.searchFocusNode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'What do you want to play?',
                                  hintStyle: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: _onChanged,
                                onSubmitted: _onSubmit,
                              ),
                            ),
                            if (widget.searchController.text.isNotEmpty) ...[
                              GestureDetector(
                                onTap: () {
                                  widget.searchController.clear();
                                  _onChanged('');
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: AppIcon(
                                    icon: AppIcons.close,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ] else
                              const SizedBox(width: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Avatar
                  GestureDetector(
                    onTap: () => _showUserMenu(context, username, user?.email),
                    child: ClipOval(
                      clipBehavior: Clip.hardEdge,
                      child: CachedNetworkImage(
                        imageUrl: avatarUrl,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        memCacheWidth: cachePx(context, 36),
                        memCacheHeight: cachePx(context, 36),
                        placeholder: (_, __) => Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                          ),
                          child: AppIcon(
                            icon: AppIcons.person,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
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

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _NavArrowBtn extends StatelessWidget {
  const _NavArrowBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AppIcon(
            icon: icon,
            size: 20,
            color: enabled
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

class _HomeBtn extends StatelessWidget {
  const _HomeBtn({required this.isActive, required this.onTap});

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : AppColors.surfaceLight,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AppIcon(
            icon: AppIcons.home,
            size: 20,
            color: isActive ? AppColors.background : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
