import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/ui/button.dart';
import '../../components/ui/sheet.dart';
import '../../../config/app_icons.dart';
import '../../../config/app_strings.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/guest_profile_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';
import '../guest_profile_setup_screen.dart';
import 'home_shared.dart';
import 'home_settings_sheet.dart';
import 'home_user_menu.dart';

class HomeAppBar extends ConsumerWidget {
  const HomeAppBar({super.key, required this.greeting, this.asSliver = true});
  final String greeting;
  /// When true (default), returns [SliverAppBar]. When false, returns a fixed header widget.
  final bool asSliver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isGuest = ref.watch(guestModeProvider);
    final guestUsername = isGuest
        ? ref.watch(guestUsernameProvider).value
        : null;
    final username = (user?.userMetadata?['username'] as String?) ??
        (user?.email?.split('@').first) ??
        (isGuest ? (guestUsername ?? 'Guest') : 'V');
    final avatarUrl =
        'https://api.dicebear.com/9.x/fun-emoji/png?seed=${Uri.encodeComponent(username)}&size=72';

    final titleRow = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: Text(
                  '$greeting, $username',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppStrings.appName,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        AppIconButton(
          icon: AppIcon(icon: AppIcons.notifications, size: 24, color: AppColors.textPrimary),
          onPressed: () {},
          style: AppIconButtonStyle.filled,
          size: 36,
          iconSize: 16,
        ),
        const SizedBox(width: AppSpacing.sm),
        GestureDetector(
          onTap: () => _showUserMenu(context, ref, username, user?.email),
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
    );

    if (asSliver) {
      return SliverAppBar(
        floating: true,
        snap: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 72,
        title: titleRow,
      );
    }

    return Container(
      width: double.infinity,
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 72,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: titleRow,
            ),
          ),
        ),
      ),
    );
  }

  void _showUserMenu(
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
}
