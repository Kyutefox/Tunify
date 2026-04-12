import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/features/home/presentation/constants/home_menu_layout.dart';
import 'package:tunify/v2/features/settings/presentation/screens/settings_screen.dart';

/// Figma “Menu” column only: #1F1F1F surface (padding 60 vertical, gap 16). No outer shell or modal scrim.
Future<void> showHomeUserMenu(BuildContext context) {
  final localizations = MaterialLocalizations.of(context);
  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: localizations.modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final size = MediaQuery.sizeOf(dialogContext);
      final shellMax = HomeMenuLayout.panelWidth(size.width);
      final sidebarW = HomeMenuLayout.menuSurfaceWidth(shellMax);
      return Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: sidebarW,
          height: size.height,
          child: _HomeUserMenuPanelBody(
              panelWidth: sidebarW,
              onOpenSettings: () {
                final nav = Navigator.of(dialogContext, rootNavigator: true);
                nav.pop();
                Future<void>.microtask(() {
                  nav.push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                });
              },
              onDismiss: () =>
                  Navigator.of(dialogContext, rootNavigator: true).pop(),
            ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

/// Swipe **left** (negative drag / fast left fling) to dismiss — avoids [Dismissible]
/// “still part of the tree” when closing via [Navigator.pop] on a dialog route.
class _SwipeToCloseMenuPanel extends StatefulWidget {
  const _SwipeToCloseMenuPanel({
    required this.panelWidth,
    required this.onDismiss,
    required this.child,
  });

  final double panelWidth;
  final VoidCallback onDismiss;
  final Widget child;

  @override
  State<_SwipeToCloseMenuPanel> createState() => _SwipeToCloseMenuPanelState();
}

class _SwipeToCloseMenuPanelState extends State<_SwipeToCloseMenuPanel> {
  double _dragDx = 0;

  static const double _closeVelocity = 500;

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() {
      _dragDx = (_dragDx + d.delta.dx).clamp(-widget.panelWidth, 0.0);
    });
  }

  void _onDragEnd(DragEndDetails d) {
    final vx = d.velocity.pixelsPerSecond.dx;
    final threshold = widget.panelWidth * 0.2;
    final shouldClose = _dragDx <= -threshold || vx < -_closeVelocity;
    if (shouldClose) {
      widget.onDismiss();
      return;
    }
    setState(() => _dragDx = 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      behavior: HitTestBehavior.opaque,
      child: Transform.translate(
        offset: Offset(_dragDx, 0),
        child: widget.child,
      ),
    );
  }
}

/// Figma tokens local to this menu (Circular Std → system UI).
abstract final class _HomeMenuColors {
  static const Color viewProfile = Color(0xFFDEDEDE);
  static const Color separator10 = Color.fromRGBO(255, 255, 255, 0.1);
}

class _HomeUserMenuPanelBody extends StatelessWidget {
  const _HomeUserMenuPanelBody({
    required this.panelWidth,
    required this.onOpenSettings,
    required this.onDismiss,
  });

  final double panelWidth;
  final VoidCallback onOpenSettings;
  final VoidCallback onDismiss;

  static const TextStyle _titleName = TextStyle(
    fontSize: 19,
    height: 23 / 19,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.white,
    decoration: TextDecoration.none,
  );

  static const TextStyle _viewProfile = TextStyle(
    fontSize: 12,
    height: 17 / 12,
    fontWeight: FontWeight.w400,
    color: _HomeMenuColors.viewProfile,
    decoration: TextDecoration.none,
  );

  static const TextStyle _itemLabel = TextStyle(
    fontSize: 15,
    height: 19 / 15,
    fontWeight: FontWeight.w400,
    color: AppColors.white,
    decoration: TextDecoration.none,
  );

  @override
  Widget build(BuildContext context) {
    return _SwipeToCloseMenuPanel(
      panelWidth: panelWidth,
      onDismiss: onDismiss,
      child: ColoredBox(
        color: AppColors.midDark,
        child: SafeArea(
          right: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: HomeMenuLayout.menuVerticalPaddingPt,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    HomeMenuLayout.titleRowLeadingPadPt,
                    0,
                    HomeMenuLayout.titleRowTrailingPadPt,
                    0,
                  ),
                  child: SizedBox(
                    height: HomeMenuLayout.avatarSizePt,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: HomeMenuLayout.avatarSizePt,
                          height: HomeMenuLayout.avatarSizePt,
                          decoration: const BoxDecoration(
                            color: AppColors.midCard,
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppColors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(
                          width: HomeMenuLayout.titleAvatarGapPt,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: 'Damon98',
                                  style: _titleName,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text.rich(
                                TextSpan(
                                  text: 'View profile',
                                  style: _viewProfile,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: HomeMenuLayout.sectionGapPt),
                SizedBox(
                  width: panelWidth,
                  height: 1,
                  child: const ColoredBox(
                    color: _HomeMenuColors.separator10,
                  ),
                ),
                const SizedBox(height: HomeMenuLayout.sectionGapPt),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    HomeMenuLayout.titleRowLeadingPadPt,
                    0,
                    HomeMenuLayout.titleRowTrailingPadPt,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MenuItemRow(
                        icon: Icons.newspaper_outlined,
                        label: "What's new",
                        onTap: () {},
                      ),
                      const SizedBox(
                        height: HomeMenuLayout.itemListGapPt,
                      ),
                      _MenuItemRow(
                        icon: Icons.history_rounded,
                        label: 'Listening history',
                        onTap: () {},
                      ),
                      const SizedBox(
                        height: HomeMenuLayout.itemListGapPt,
                      ),
                      _MenuItemRow(
                        icon: Icons.settings_outlined,
                        label: 'Settings and privacy',
                        onTap: onOpenSettings,
                      ),
                    ],
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

class _MenuItemRow extends StatelessWidget {
  const _MenuItemRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: HomeMenuLayout.menuItemRowHeightPt,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: HomeMenuLayout.menuIconBoxPt,
                height: HomeMenuLayout.menuIconBoxPt,
                child: Center(
                  child: Icon(
                    icon,
                    color: AppColors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: HomeMenuLayout.menuItemIconGapPt),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: label,
                    style: _HomeUserMenuPanelBody._itemLabel,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
