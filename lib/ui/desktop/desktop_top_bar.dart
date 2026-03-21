import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_icons.dart';
import '../../shared/providers/search_provider.dart';
import '../components/shared/user_avatar_button.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

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
    required this.onBrowsePressed,
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

  /// Called when the Browse button is tapped.
  final VoidCallback onBrowsePressed;

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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.glassBorder,
            width: 0.5,
          ),
        ),
      ),
      child: Stack(
        children: [
          // ── Left: back/forward above sidebar | Right: avatar ─────────────
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: const UserAvatarButton(),
              ),
            ],
            ),
          ),

          // ── Center: home + search bar — true screen center ───────────────
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HomeBtn(
                  isActive: widget.selectedIndex == 0,
                  onTap: widget.onHomePressed,
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: TapRegion(
                    groupId: 'desktop-search',
                    child: _DesktopSearchBar(
                      controller: widget.searchController,
                      focusNode: widget.searchFocusNode,
                      isActive: _hasFocus || widget.isSearchOverlayOpen,
                      onChanged: _onChanged,
                      onSubmitted: _onSubmit,
                      onClear: () {
                        widget.searchController.clear();
                        _onChanged('');
                      },
                      onBrowse: widget.onBrowsePressed,
                    ),
                  ),
                ),
              ],
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

/// Clean single-layer search bar for the desktop top bar.
/// Matches the mobile _SearchBarPlaceholder style: filled container with a
/// single border, search icon, and a fully transparent TextField inside —
/// no double-border / double-background artefact.
class _DesktopSearchBar extends StatelessWidget {
  const _DesktopSearchBar({
    required this.controller,
    required this.focusNode,
    required this.isActive,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onBrowse,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isActive;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isActive
              ? Colors.white.withValues(alpha: 0.55)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          AppIcon(icon: AppIcons.search, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                textSelectionTheme: const TextSelectionThemeData(
                  cursorColor: Colors.white,
                ),
                inputDecorationTheme: const InputDecorationTheme(
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'What do you want to play?',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: onChanged,
                onSubmitted: onSubmitted,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AppIcon(
                    icon: AppIcons.close,
                    size: 14,
                    color: AppColors.textSecondary),
              ),
            ),
          // Divider
          Container(
            width: 1,
            height: 18,
            color: AppColors.textMuted.withValues(alpha: 0.3),
          ),
          // Browse button
          GestureDetector(
            onTap: onBrowse,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                      icon: AppIcons.gridView,
                      size: 14,
                      color: AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    'Browse',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AppIcon(
            icon: AppIcons.home,
            size: 20,
            color: isActive
                ? AppColors.background
                : AppColors.background.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}
