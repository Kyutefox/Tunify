import 'package:flutter/material.dart';

import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

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
        (useGradient ? Colors.white : variant == AppButtonVariant.filled ? Colors.white : AppColors.primary);
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
                      fontSize: AppFontSize.xl,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                label,
                style: TextStyle(
                  color: effectiveForeground,
                  fontSize: AppFontSize.xl,
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
              color: isDisabled ? AppColorsScheme.of(context).textMuted : AppColors.primary,
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
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.input),
              boxShadow: isDisabled ? null : [
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
    this.onPressed,
    this.tooltip,
    this.style = AppIconButtonStyle.ghost,
    this.size = 48,
    this.iconSize = 24,
    this.color,
    this.onPressedWithContext,
    this.iconAlignment = Alignment.center,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  /// Called with the button's own [BuildContext] — use this when you need
  /// to compute the button's screen rect for dropdown positioning.
  final void Function(BuildContext ctx)? onPressedWithContext;
  final String? tooltip;
  final AppIconButtonStyle style;
  final double size;
  final double iconSize;
  final Color? color;
  /// Alignment of the icon within the touch target. Use [Alignment.centerRight]
  /// when the button is at the trailing edge of a list tile so the icon sits
  /// flush with the right content boundary instead of being center-padded.
  final AlignmentGeometry iconAlignment;

  void _handleTap(BuildContext ctx) {
    if (onPressedWithContext != null) {
      onPressedWithContext!(ctx);
    } else {
      onPressed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColorsScheme.of(context).textPrimary;
    
    // Wrap in Builder first so the context passed to _handleTap has the
    // button's full size and position for accurate dropdown positioning
    return Builder(
      builder: (btnCtx) {
        Widget button;
        
        if (style == AppIconButtonStyle.ghost) {
          button = Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: (onPressedWithContext != null || onPressed != null)
                  ? () => _handleTap(btnCtx)
                  : null,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: size,
                height: size,
                child: Align(
                  alignment: iconAlignment,
                  child: IconTheme(
                    data: IconThemeData(size: iconSize, color: effectiveColor),
                    child: icon,
                  ),
                ),
              ),
            ),
          );
        } else {
          // filled and outlined share the same visual — glass circle with border
          button = Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColorsScheme.of(context).surfaceLight,
              border: Border.all(color: AppColorsScheme.of(context).surfaceHighlight, width: 0.5),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (onPressedWithContext != null || onPressed != null)
                    ? () => _handleTap(btnCtx)
                    : null,
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
      },
    );
  }
}

/// Small text-only button used in section headers (e.g. "Clear", "See all").
