import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/theme/app_button_styles.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/avatar/network_avatar_image.dart';
import 'package:tunify/v2/features/auth/domain/entities/user_entity.dart';
import 'package:tunify/v2/features/auth/presentation/providers/auth_session_provider.dart';
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
  final ValueNotifier<double> _dragDx = ValueNotifier<double>(0);

  static const double _closeVelocity = 500;

  @override
  void dispose() {
    _dragDx.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _dragDx.value = (_dragDx.value + d.delta.dx).clamp(-widget.panelWidth, 0.0);
  }

  void _onDragEnd(DragEndDetails d) {
    final vx = d.velocity.pixelsPerSecond.dx;
    final threshold = widget.panelWidth * 0.2;
    final shouldClose = _dragDx.value <= -threshold || vx < -_closeVelocity;
    if (shouldClose) {
      widget.onDismiss();
      return;
    }
    _dragDx.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      behavior: HitTestBehavior.opaque,
      child: ValueListenableBuilder<double>(
        valueListenable: _dragDx,
        builder: (context, dragDx, child) {
          return Transform.translate(
            offset: Offset(dragDx, 0),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _HomeUserMenuPanelBody extends ConsumerWidget {
  const _HomeUserMenuPanelBody({
    required this.panelWidth,
    required this.onOpenSettings,
    required this.onDismiss,
  });

  final double panelWidth;
  final VoidCallback onOpenSettings;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user =
        ref.watch(authSessionProvider).whenOrNull(data: (value) => value);
    final displayName = _displayName(user);
    final profileSubtitle = _profileSubtitle(user);
    final avatarUrl = avatarUrlFromUser(user);

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
                Expanded(
                  child: SingleChildScrollView(
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
                                  child: avatarUrl == null
                                      ? AvatarFallbackIcon(
                                          size: HomeMenuLayout.avatarIconSizePt,
                                        )
                                      : NetworkAvatarImage(
                                          url: avatarUrl,
                                          fallbackIconSize:
                                              HomeMenuLayout.avatarIconSizePt,
                                        ),
                                ),
                                const SizedBox(
                                  width: HomeMenuLayout.titleAvatarGapPt,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text.rich(
                                        TextSpan(
                                          text: displayName,
                                          style: AppTextStyles.menuTitleName,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text.rich(
                                        TextSpan(
                                          text: profileSubtitle,
                                          style: AppTextStyles.menuViewProfile,
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
                            color: AppColors.separator10,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    HomeMenuLayout.titleRowLeadingPadPt,
                    HomeMenuLayout.sectionGapPt,
                    HomeMenuLayout.titleRowTrailingPadPt,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: panelWidth,
                        height: 1,
                        child: const ColoredBox(
                          color: AppColors.separator10,
                        ),
                      ),
                      const SizedBox(height: HomeMenuLayout.itemListGapPt),
                      AppButtonStyles.darkPill(
                        label: 'Log out',
                        width: double.infinity,
                        onPressed: () async {
                          final container = ProviderScope.containerOf(context);
                          final nav =
                              Navigator.of(context, rootNavigator: true);
                          nav.pop();
                          await container
                              .read(authSessionProvider.notifier)
                              .signOut();
                        },
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

String _displayName(UserEntity? user) {
  final preferred = user?.displayName?.trim();
  if (preferred != null && preferred.isNotEmpty) {
    return preferred;
  }
  final username = user?.username.trim();
  if (username != null && username.isNotEmpty) {
    return username;
  }
  return 'User';
}

String _profileSubtitle(UserEntity? user) {
  final email = user?.email.trim();
  if (email != null && email.isNotEmpty) {
    return email;
  }
  return 'View profile';
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
                    size: HomeMenuLayout.menuItemIconSizePt,
                  ),
                ),
              ),
              const SizedBox(width: HomeMenuLayout.menuItemIconGapPt),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: label,
                    style: AppTextStyles.menuItemLabel,
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
