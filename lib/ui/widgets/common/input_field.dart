import 'package:flutter/material.dart';

import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

enum InputFieldStyle {
  outlined,
  transparent,
  filled,
}

class AppInputField extends StatelessWidget {
  const AppInputField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.maxLines = 1,
    this.style = InputFieldStyle.outlined,
    this.fillColor,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool autofocus;
  final int maxLines;
  final InputFieldStyle style;
  final Color? fillColor;

  InputDecoration _buildDecoration(BuildContext context) {
    final useLabel = labelText != null && labelText!.isNotEmpty;
    final useHint = hintText != null && hintText!.isNotEmpty;

    switch (style) {
      case InputFieldStyle.transparent:
        return InputDecoration(
          hintText: useHint ? hintText : null,
          hintStyle: TextStyle(
            color: AppColorsScheme.of(context).textMuted.withValues(alpha: 0.7),
            fontSize: AppFontSize.xl,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        );
      case InputFieldStyle.filled:
        return InputDecoration(
          hintText: useHint ? hintText : null,
          hintStyle: TextStyle(color: AppColorsScheme.of(context).textMuted),
          prefixIcon: prefixIcon != null
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: prefixIcon,
                )
              : null,
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: suffixIcon,
                )
              : null,
          filled: true,
          fillColor: fillColor ?? AppColorsScheme.of(context).surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        );
      case InputFieldStyle.outlined:
        return InputDecoration(
          labelText: useLabel ? labelText : null,
          labelStyle: TextStyle(
            color: AppColorsScheme.of(context).textSecondary,
            fontSize: AppFontSize.base,
          ),
          floatingLabelStyle: TextStyle(
            color: AppColorsScheme.of(context).textSecondary,
            fontSize: AppFontSize.md,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          floatingLabelAlignment: FloatingLabelAlignment.start,
          hintText: useHint ? hintText : null,
          hintStyle: TextStyle(color: AppColorsScheme.of(context).textMuted),
          prefixIcon: prefixIcon != null
              ? SizedBox(
                  width: 48,
                  child: Center(child: prefixIcon),
                )
              : null,
          suffixIcon: suffixIcon != null
              ? SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(child: suffixIcon),
                )
              : null,
          suffixIconConstraints:
              const BoxConstraints(minWidth: 48, minHeight: 48),
          filled: true,
          fillColor: fillColor ?? AppColorsScheme.of(context).surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide:
                BorderSide(color: AppColorsScheme.of(context).surfaceHighlight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide: BorderSide(
                color: AppColorsScheme.of(context).surfaceHighlight, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide: const BorderSide(color: AppColors.accentRed, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide:
                const BorderSide(color: AppColors.accentRed, width: 1.5),
          ),
          errorStyle: const TextStyle(
            color: AppColors.accentRed,
            fontSize: AppFontSize.sm,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.base,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final decoration = _buildDecoration(context);
    final textStyle = TextStyle(
      color: AppColorsScheme.of(context).textPrimary,
      fontSize: style == InputFieldStyle.transparent ? 16 : 15,
      height: AppLineHeight.normal,
      fontWeight: style == InputFieldStyle.transparent ? FontWeight.w500 : null,
    );

    if (validator != null) {
      return TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted != null ? (v) => onSubmitted!(v) : null,
        autofocus: autofocus,
        maxLines: obscureText ? 1 : maxLines,
        style: textStyle,
        cursorColor: AppColors.accent,
        decoration: decoration,
      );
    }

    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
      maxLines: obscureText ? 1 : maxLines,
      style: textStyle,
      cursorColor: AppColors.accent,
      decoration: decoration,
    );
  }
}
