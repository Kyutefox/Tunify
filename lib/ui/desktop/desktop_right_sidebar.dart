import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../config/app_icons.dart';
import '../screens/player/player_screen.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

// ── Public API ────────────────────────────────────────────────────────────────

enum RightSidebarTab { queue, lyrics, devices }

extension _RightSidebarTabX on RightSidebarTab {
  String get label {
    switch (this) {
      case RightSidebarTab.queue:
        return 'Queue';
      case RightSidebarTab.lyrics:
        return 'Lyrics';
      case RightSidebarTab.devices:
        return 'Connect';
    }
  }

  List<List<dynamic>> get icon {
    switch (this) {
      case RightSidebarTab.queue:
        return AppIcons.queueMusic;
      case RightSidebarTab.lyrics:
        return AppIcons.lyrics;
      case RightSidebarTab.devices:
        return AppIcons.devices;
    }
  }
}

/// Which tab is open in the right sidebar. `null` = sidebar is closed.
final rightSidebarTabProvider = StateProvider<RightSidebarTab?>((ref) => null);

const double kDesktopRightSidebarWidth = 320.0;

// ── Widget ────────────────────────────────────────────────────────────────────

/// Right sidebar for the macOS desktop layout.
///
/// Shows three panels selectable via a tab bar at the top:
/// - Queue   — current playback queue with drag-to-reorder
/// - Lyrics  — synced/static lyrics for the current song
/// - Connect — Bluetooth / AirPlay / network device selector
///
/// Hidden by default; toggled from the player-bar icon buttons by writing to
/// [rightSidebarTabProvider]. When the active tab button is pressed again the
/// provider is set to `null` and the sidebar animates closed in [DesktopShell].
class DesktopRightSidebar extends ConsumerStatefulWidget {
  const DesktopRightSidebar({super.key});

  @override
  ConsumerState<DesktopRightSidebar> createState() =>
      _DesktopRightSidebarState();
}

class _DesktopRightSidebarState extends ConsumerState<DesktopRightSidebar> {
  final _queueScroll = ScrollController();
  final _lyricsScroll = ScrollController();
  final _devicesScroll = ScrollController();

  @override
  void dispose() {
    _queueScroll.dispose();
    _lyricsScroll.dispose();
    _devicesScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fallback to queue when provider holds null (sidebar still animating out).
    final activeTab =
        ref.watch(rightSidebarTabProvider) ?? RightSidebarTab.queue;

    return SizedBox(
      width: kDesktopRightSidebarWidth,
      child: Container(
        color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SidebarTabBar(activeTab: activeTab),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: child,
                ),
                child: _buildPanel(activeTab),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel(RightSidebarTab tab) {
    switch (tab) {
      case RightSidebarTab.queue:
        return QueuePanelContent(
          key: const ValueKey('queue'),
          scrollController: _queueScroll,
        );
      case RightSidebarTab.lyrics:
        return LyricsPanelContent(
          key: const ValueKey('lyrics'),
          scrollController: _lyricsScroll,
        );
      case RightSidebarTab.devices:
        return DevicesPanelContent(
          key: const ValueKey('devices'),
          scrollController: _devicesScroll,
        );
    }
  }
}

// ── Tab bar ───────────────────────────────────────────────────────────────────

class _SidebarTabBar extends ConsumerWidget {
  const _SidebarTabBar({required this.activeTab});

  final RightSidebarTab activeTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.glassBorder,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          ...RightSidebarTab.values.map(
            (tab) => Expanded(
              child: _TabButton(
                tab: tab,
                isActive: activeTab == tab,
                onTap: () =>
                    ref.read(rightSidebarTabProvider.notifier).state = tab,
              ),
            ),
          ),
          // Close button
          GestureDetector(
            onTap: () =>
                ref.read(rightSidebarTabProvider.notifier).state = null,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AppIcon(
                icon: AppIcons.chevronRight,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  final RightSidebarTab tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(icon: tab.icon, size: 16, color: color),
            const SizedBox(height: 3),
            Text(
              tab.label,
              style: TextStyle(
                color: color,
                fontSize: AppFontSize.micro,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: AppLetterSpacing.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
