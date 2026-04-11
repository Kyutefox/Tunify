import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tunify/v1/core/constants/app_icons.dart';
import 'package:tunify/v1/ui/theme/design_tokens.dart';
import 'package:tunify/v1/ui/theme/app_colors_scheme.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: AppBar(
        backgroundColor: backgroundColor ?? Colors.transparent,
        elevation: 0,
        systemOverlayStyle: overlayStyle,
        leading: IconButton(
          icon: AppIcon(
            icon: AppIcons.back,
            size: 24,
            color: AppColorsScheme.of(context).textPrimary,
          ),
          onPressed: onBack ?? () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: AppColorsScheme.of(context).textPrimary,
            fontSize: AppFontSize.xxl,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: actions,
      ),
    );
  }
}
