import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../config/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';
import '../../components/ui/sheet_drag_handle.dart';
import 'home_shared.dart';

class HomeUserMenuSheet extends StatelessWidget {
  const HomeUserMenuSheet({
    super.key,
    required this.username,
    required this.email,
    required this.onSignOut,
    this.onSettings,
  });

  final String username;
  final String? email;
  final VoidCallback onSignOut;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final avatarUrl =
        'https://api.dicebear.com/9.x/fun-emoji/png?seed=${Uri.encodeComponent(username)}&size=104';
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.xl),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.92),
            border: const Border(
              top: BorderSide(color: AppColors.glassBorder, width: 0.5),
            ),
          ),
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetDragHandle(),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatarUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      memCacheWidth: cachePx(context, 52),
                      memCacheHeight: cachePx(context, 52),
                      placeholder: (_, __) => Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                        ),
                        child: AppIcon(
                          icon: AppIcons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (email != null)
                          Text(
                            email!,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const Divider(
                color: AppColors.glassBorder,
                height: 1,
                thickness: 0.5,
              ),
              const SizedBox(height: AppSpacing.md),
              if (onSettings != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onSettings,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Row(
                      children: [
                        AppIcon(
                          icon: AppIcons.edit,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        const Text(
                          'Settings',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSignOut,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      AppIcon(
                        icon: AppIcons.logout,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                      SizedBox(width: AppSpacing.md),
                      Text(
                        'Sign Out',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
