import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/features/auth/auth_provider.dart';
import 'package:tunify/features/settings/guest_profile_provider.dart';
import 'package:tunify/ui/screens/detail/desktop_settings_screen.dart';
import 'package:tunify/ui/shell/shell_context.dart';
import 'package:tunify/ui/screens/guest_profile_setup_screen.dart';
import 'package:tunify/ui/screens/home/home_settings_sheet.dart';
import 'package:tunify/ui/screens/home/home_shared.dart';
import 'package:tunify/ui/screens/home/home_user_menu.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_routes.dart';
import 'package:tunify/ui/widgets/sheet.dart';
import 'adaptive_menu.dart';

/// Derives the current user's display name and avatar URL from auth/guest
/// providers, renders a 36 px circular avatar, and opens the user menu on tap.
///
/// Mobile: [HomeUserMenuSheet] bottom sheet (rich backdrop-blur design).
/// Desktop: [showAdaptiveMenu] dropdown with the same options.
class UserAvatarButton extends ConsumerWidget {
  const UserAvatarButton({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isGuest = ref.watch(guestModeProvider);
    final guestUsername = isGuest ? ref.watch(guestUsernameProvider).value : null;
    final username = (user?.userMetadata?['username'] as String?) ??
        (user?.email?.split('@').first) ??
        (isGuest ? (guestUsername ?? 'Guest') : 'V');
    final avatarUrl =
        'https://api.dicebear.com/9.x/fun-emoji/png?seed=${Uri.encodeComponent(username)}&size=72';

    return GestureDetector(
      onTap: () {
        if (ShellContext.isDesktopOf(context)) {
          _showDesktopMenu(context, ref, username, user?.email, avatarUrl);
        } else {
          _showMobileSheet(context, ref, username, user?.email);
        }
      },
      child: ClipOval(
        clipBehavior: Clip.hardEdge,
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          memCacheWidth: cachePx(context, size),
          memCacheHeight: cachePx(context, size),
          placeholder: (_, __) => _fallback(size),
          errorWidget: (_, __, ___) => _fallback(size),
        ),
      ),
    );
  }

  static Widget _fallback(double size) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
        ),
        child: Center(
          child: AppIcon(icon: AppIcons.person, color: Colors.white, size: size * 0.5),
        ),
      );
}

// ── Mobile: rich backdrop-blur sheet ─────────────────────────────────────────

void _showMobileSheet(
  BuildContext context,
  WidgetRef ref,
  String username,
  String? email,
) {
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
                appPageRoute<void>(
                  builder: (_) => const GuestProfileSetupScreen(isInitial: false),
                ),
              );
            }
          : null,
    ),
  );
}

// ── Desktop: adaptive dropdown ────────────────────────────────────────────────

void _showDesktopMenu(
  BuildContext context,
  WidgetRef ref,
  String username,
  String? email,
  String avatarUrl,
) {
  final isGuest = ref.read(guestModeProvider);

  // Compact header: avatar + name + email
  final header = Row(
    children: [
      ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.sm + 2),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              username,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppFontSize.md,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (email != null)
              Text(
                email,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: AppFontSize.xs,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    ],
  );

  // Build the anchor rect from the avatar widget's position.
  // We use a post-frame callback trick: the caller (UserAvatarButton.build)
  // already has the RenderBox — but since this is a free function we compute
  // it from the context passed in.
  final box = context.findRenderObject() as RenderBox?;
  Rect? anchorRect;
  if (box != null && box.hasSize) {
    anchorRect = box.localToGlobal(Offset.zero) & box.size;
  }

  showAdaptiveMenu(
    context,
    header: header,
    anchorRect: anchorRect,
    entries: [
      if (isGuest)
        AppMenuEntry(
          icon: AppIcons.edit,
          label: 'Edit Profile',
          onTap: () => ShellContext.pushDetail(
            context,
            const GuestProfileSetupScreen(isInitial: false),
          ),
        ),
      AppMenuEntry(
        icon: AppIcons.settings,
        label: 'Settings',
        onTap: () => ShellContext.pushDetail(
          context,
          const DesktopSettingsScreen(),
        ),
      ),
      const AppMenuEntry.divider(),
      AppMenuEntry(
        icon: AppIcons.logout,
        label: 'Sign Out',
        color: AppColors.secondary,
        onTap: () async {
          if (isGuest) {
            ref.read(guestModeProvider.notifier).exitGuestMode();
          } else {
            await ref.read(authNotifierProvider.notifier).signOut();
          }
        },
      ),
    ],
  );
}

/// Convenience function — call from non-widget code that already has a ref.
void showUserMenu(BuildContext context, WidgetRef ref) {
  final user = ref.read(currentUserProvider);
  final isGuest = ref.read(guestModeProvider);
  final guestUsername = isGuest ? ref.read(guestUsernameProvider).value : null;
  final username = (user?.userMetadata?['username'] as String?) ??
      (user?.email?.split('@').first) ??
      (isGuest ? (guestUsername ?? 'Guest') : 'V');
  final avatarUrl =
      'https://api.dicebear.com/9.x/fun-emoji/png?seed=${Uri.encodeComponent(username)}&size=72';

  if (ShellContext.isDesktopOf(context)) {
    _showDesktopMenu(context, ref, username, user?.email, avatarUrl);
  } else {
    _showMobileSheet(context, ref, username, user?.email);
  }
}
