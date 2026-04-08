import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/features/auth/auth_provider.dart';
import 'package:tunify/features/settings/avatar_provider.dart';
import 'package:tunify/features/settings/guest_profile_provider.dart';
import 'package:tunify/data/repositories/database_repository.dart'
    show databaseRepositoryProvider;
import 'package:tunify/features/home/home_state_provider.dart';
import 'package:tunify/features/library/library_provider.dart';
import 'package:tunify/features/search/recent_search_provider.dart';
import 'package:tunify/ui/screens/shared/auth/guest_profile_setup_screen.dart';
import 'package:tunify/ui/screens/shared/home/home_settings_sheet.dart';
import 'package:tunify/ui/screens/shared/home/home_shared.dart';
import 'package:tunify/ui/screens/shared/home/home_user_menu.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/app_routes.dart';
import 'package:tunify/ui/widgets/common/sheet.dart';

void _refreshProvidersForSignOut(WidgetRef ref) {
  ref.read(homeProvider.notifier).onAuthChanged(null);
  ref.read(libraryProvider.notifier).onAuthChanged(null);
  ref.read(recentSearchProvider.notifier).onAuthChanged();
}

/// Derives the current user's display name and avatar URL from auth/guest
/// providers, renders a 36 px circular avatar, and opens the user menu on tap.
///
/// Mobile: [HomeUserMenuSheet] bottom sheet (rich backdrop-blur design).
/// Unified: [HomeUserMenuSheet] sheet with the same options.
class UserAvatarButton extends ConsumerWidget {
  const UserAvatarButton({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isGuest = ref.watch(guestModeProvider);
    final guestUsername =
        isGuest ? ref.watch(guestUsernameProvider).value : null;
    final cachedAvatarSeed =
        isGuest ? ref.watch(avatarSeedProvider).value : null;
    final username = (user?.userMetadata?['username'] as String?) ??
        (user?.email?.split('@').first) ??
        (isGuest ? (guestUsername ?? 'Guest') : 'V');
    final avatarSeed = cachedAvatarSeed ?? username;
    final avatarUrl = generateBotttsAvatarUrl(avatarSeed, size: 72);

    return GestureDetector(
      onTap: () {
        _showMobileSheet(context, ref, username, user?.email);
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
          child: AppIcon(
              icon: AppIcons.person, color: Colors.white, size: size * 0.5),
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
          await ref.read(databaseRepositoryProvider).clearAllLocalData();
          await ref.read(guestUsernameProvider.notifier).clearGuestData();
          await ref.read(avatarSeedProvider.notifier).clearAvatarSeed();
          ref.read(guestModeProvider.notifier).exitGuestMode();
          _refreshProvidersForSignOut(ref);
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
                  builder: (_) =>
                      const GuestProfileSetupScreen(isInitial: false),
                ),
              );
            }
          : null,
    ),
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
  _showMobileSheet(context, ref, username, user?.email);
}
