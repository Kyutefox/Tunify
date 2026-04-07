import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/features/search/search_provider.dart';
import 'package:tunify/ui/widgets/auth/user_avatar_button.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/desktop_tokens.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

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
      height: DesktopLayout.topBarHeight,
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Stack(
        children: [
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
                      const SizedBox(width: DesktopSpacing.sm),
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
                  padding: const EdgeInsets.only(right: DesktopSpacing.base),
                  child: const UserAvatarButton(),
                ),
              ],
            ),
          ),

          // Center: home + search bar
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HomeBtn(
                  isActive: widget.selectedIndex == 0,
                  onTap: widget.onHomePressed,
                ),
                const SizedBox(width: DesktopSpacing.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                      maxWidth: DesktopLayout.searchMaxWidth),
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
        width: DesktopLayout.navBtnSize,
        height: DesktopLayout.navBtnSize,
        decoration: BoxDecoration(
          color: AppColorsScheme.of(context).surface,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AppIcon(
            icon: icon,
            size: DesktopIconSize.md,
            color: enabled
                ? AppColorsScheme.of(context).textPrimary
                : AppColorsScheme.of(context)
                    .textPrimary
                    .withValues(alpha: 0.22),
          ),
        ),
      ),
    );
  }
}

/// Clean single-layer search bar for the desktop top bar.
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
        color: AppColorsScheme.of(context).surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isActive
              ? AppColorsScheme.of(context).textPrimary.withValues(alpha: 0.28)
              : AppColorsScheme.of(context).textPrimary.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: DesktopSpacing.md),
          AppIcon(
              icon: AppIcons.search,
              size: DesktopIconSize.sm,
              color: AppColorsScheme.of(context).textMuted),
          const SizedBox(width: DesktopSpacing.sm),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: AppColorsScheme.of(context).textPrimary,
                ),
                inputDecorationTheme: const InputDecorationTheme(
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: TextStyle(
                  color: AppColorsScheme.of(context).textPrimary,
                  fontSize: DesktopFontSize.base,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'What do you want to play?',
                  hintStyle: TextStyle(
                    color: AppColorsScheme.of(context)
                        .textMuted
                        .withValues(alpha: 0.7),
                    fontSize: DesktopFontSize.base,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: DesktopSpacing.sm),
                child: AppIcon(
                    icon: AppIcons.close,
                    size: DesktopIconSize.xs,
                    color: AppColorsScheme.of(context).textSecondary),
              ),
            ),
          Container(
            width: 1,
            height: 20,
            color: AppColorsScheme.of(context).textMuted.withValues(alpha: 0.3),
          ),
          GestureDetector(
            onTap: onBrowse,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: DesktopSpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                      icon: AppIcons.gridView,
                      size: DesktopIconSize.xs,
                      color: AppColorsScheme.of(context).textSecondary),
                  const SizedBox(width: DesktopSpacing.xs),
                  Text(
                    'Browse',
                    style: TextStyle(
                      color: AppColorsScheme.of(context).textSecondary,
                      fontSize: DesktopFontSize.sm,
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
        width: DesktopLayout.homeBtnSize,
        height: DesktopLayout.homeBtnSize,
        decoration: BoxDecoration(
          color: AppColorsScheme.of(context).surface,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AppIcon(
            icon: AppIcons.home,
            size: DesktopIconSize.md,
            color: isActive
                ? AppColorsScheme.of(context).textPrimary
                : AppColorsScheme.of(context)
                    .textPrimary
                    .withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
