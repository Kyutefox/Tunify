import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';

class SearchFocusHeader extends StatelessWidget {
  const SearchFocusHeader({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onBack,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onBack;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: AppColors.midDark,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      alignment: Alignment.center,
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: AppIcon(
                icon: AppIcons.back,
                size: 18,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              cursorColor: AppColors.brandGreen,
              style: AppTextStyles.caption.copyWith(
                fontSize: 14,
                height: 18 / 14,
                color: AppColors.white,
              ),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'What do you want to play?',
                hintStyle: TextStyle(color: AppColors.silver),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.trim().isEmpty) {
                return const SizedBox(width: 24, height: 24);
              }
              return InkWell(
                onTap: onClear,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: AppIcon(
                    icon: AppIcons.close,
                    size: 18,
                    color: AppColors.white,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
