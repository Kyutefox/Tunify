import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/widgets/sheet_drag_handle.dart';
import 'home_shared.dart';

class HomeUserMenuSheet extends StatelessWidget {
  const HomeUserMenuSheet({
    super.key,
    required this.username,
    required this.email,
    required this.onSignOut,
    this.onSettings,
    this.onEditProfile,
  });

  final String username;
  final String? email;
  final VoidCallback onSignOut;
  final VoidCallback? onSettings;
  final VoidCallback? onEditProfile;

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
                            fontSize: AppFontSize.xxl,
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
                              fontSize: AppFontSize.md,
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
              if (onEditProfile != null)
                _MenuRow(
                  icon: AppIcons.edit,
                  label: 'Edit Profile',
                  onTap: onEditProfile!,
                ),
              if (onSettings != null)
                _MenuRow(
                  icon: AppIcons.settings,
                  label: 'Settings',
                  onTap: onSettings!,
                ),
              _MenuRow(
                icon: AppIcons.logout,
                label: 'Sign Out',
                color: AppColors.secondary,
                onTap: onSignOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textPrimary,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            AppIcon(icon: icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: AppFontSize.lg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
