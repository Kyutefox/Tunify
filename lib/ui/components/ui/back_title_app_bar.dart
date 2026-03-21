import 'package:flutter/material.dart';

import '../../../config/app_icons.dart';
import '../../../ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';

/// Reusable app bar with back button and title. Use for secondary screens.
class BackTitleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BackTitleAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.backgroundColor,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Color? backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: AppIcon(
          icon: AppIcons.back,
          size: 24,
          color: AppColors.textPrimary,
        ),
        onPressed: onBack ?? () => Navigator.of(context).pop(),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppFontSize.xxl,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: actions,
    );
  }
}
