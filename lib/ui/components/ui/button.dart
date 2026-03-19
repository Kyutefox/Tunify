import 'package:flutter/material.dart';

import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/design_tokens.dart';

enum AppButtonVariant {
  filled,
  outlined,
  text,
}

enum AppIconButtonStyle {
  ghost,
  filled,
  outlined,
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.variant = AppButtonVariant.filled,
    this.useGradient = false,
    this.fullWidth = false,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
  });

  final VoidCallback? onPressed;
  final String label;
  final Widget? icon;
  final bool isLoading;
  final AppButtonVariant variant;
  final bool useGradient;
  final bool fullWidth;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final effectiveForeground = foregroundColor ??
        (variant == AppButtonVariant.filled ? Colors.white : AppColors.primary);
    final isDisabled = onPressed == null || isLoading;

    Widget child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: effectiveForeground,
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon!,
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    label,
                    style: TextStyle(
                      color: effectiveForeground,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                label,
                style: TextStyle(
                  color: effectiveForeground,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
    );

    final h = height ?? 52;
    if (variant == AppButtonVariant.text) {
      return SizedBox(
        width: fullWidth ? double.infinity : null,
        height: h,
        child: TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: effectiveForeground,
            shape: shape,
          ),
          child: child,
        ),
      );
    }

    if (variant == AppButtonVariant.outlined) {
      return SizedBox(
        width: fullWidth ? double.infinity : null,
        height: h,
        child: OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: effectiveForeground,
            side: BorderSide(
              color: isDisabled ? AppColors.textMuted : AppColors.primary,
            ),
            shape: shape,
          ),
          child: child,
        ),
      );
    }

    final bgColor = backgroundColor ?? AppColors.primary;
    if (useGradient) {
      return SizedBox(
        width: fullWidth ? double.infinity : null,
        height: h,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.input),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDisabled ? null : onPressed,
              borderRadius: BorderRadius.circular(AppRadius.input),
              child: Center(child: child),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: h,
      child: FilledButton(
        onPressed: isDisabled ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: effectiveForeground,
          shape: shape,
        ),
        child: child,
      ),
    );
  }
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.style = AppIconButtonStyle.ghost,
    this.size = 48,
    this.iconSize = 24,
    this.color,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final AppIconButtonStyle style;
  final double size;
  final double iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textPrimary;
    Widget button = Material(
      color: style == AppIconButtonStyle.ghost ? Colors.transparent : null,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: IconTheme(
              data: IconThemeData(size: iconSize, color: effectiveColor),
              child: icon,
            ),
          ),
        ),
      ),
    );

    if (style == AppIconButtonStyle.filled) {
      button = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.glassWhite,
          border: Border.all(color: AppColors.glassBorder, width: 0.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Center(
              child: IconTheme(
                data: IconThemeData(size: iconSize, color: effectiveColor),
                child: icon,
              ),
            ),
          ),
        ),
      );
    } else if (style == AppIconButtonStyle.outlined) {
      button = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.glassWhite,
          border: Border.all(color: AppColors.glassBorder, width: 0.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Center(
              child: IconTheme(
                data: IconThemeData(size: iconSize, color: effectiveColor),
                child: icon,
              ),
            ),
          ),
        ),
      );
    }

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }
    return button;
  }
}

/// Small text-only button used in section headers (e.g. "Clear", "See all").
