import 'package:flutter/material.dart';

import 'package:tunify/ui/widgets/input_field.dart';
import 'package:tunify/ui/widgets/button.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/core/constants/app_icons.dart';

/// Centered empty state for [SharedSearchPage] with icon, heading and subheading.
/// Use when there is no query or no results so each page can customize the message.
class SearchPageEmptyState extends StatelessWidget {
  const SearchPageEmptyState({
    super.key,
    required this.icon,
    required this.heading,
    required this.subheading,
  });

  final Widget icon;
  final String heading;
  final String subheading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: AppSpacing.lg),
            Text(
              heading,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppFontSize.h2,
                fontWeight: FontWeight.w700,
                letterSpacing: AppLetterSpacing.heading,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subheading,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppFontSize.lg,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SharedSearchPage extends StatelessWidget {
  const SharedSearchPage({
    super.key,
    required this.controller,
    required this.onBack,
    required this.body,
    this.focusNode,
    this.onClear,
    this.hintText = 'Songs, artists, podcasts',
    this.autofocus = true,
  });

  final TextEditingController controller;
  final VoidCallback onBack;
  final Widget body;
  final FocusNode? focusNode;
  final VoidCallback? onClear;
  final String hintText;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.sm,
                AppSpacing.base,
                AppSpacing.sm,
              ),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AppIconButton(
                        icon: AppIcon(
                          icon: AppIcons.back,
                          size: 24,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: onBack,
                        size: 48,
                        iconSize: 24,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppInputField(
                          controller: controller,
                          focusNode: focusNode,
                          hintText: hintText,
                          textInputAction: TextInputAction.search,
                          style: InputFieldStyle.transparent,
                          autofocus: autofocus,
                        ),
                      ),
                      if (value.text.isNotEmpty)
                        AppIconButton(
                          icon: AppIcon(
                            icon: AppIcons.clear,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () {
                            controller.clear();
                            focusNode?.unfocus();
                            onClear?.call();
                          },
                          size: 40,
                          iconSize: 20,
                        )
                      else
                        const SizedBox(width: AppSpacing.sm),
                    ],
                  );
                },
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
