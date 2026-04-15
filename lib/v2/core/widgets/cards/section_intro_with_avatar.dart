import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';

/// Section label + title beside a circular mock-avatar.
class SectionIntroWithAvatar extends StatelessWidget {
  const SectionIntroWithAvatar({
    super.key,
    required this.avatarDiameter,
    required this.sectionLabel,
    required this.sectionTitle,
    required this.mockAvatarArgbColors,
  });

  final double avatarDiameter;
  final String sectionLabel;
  final String sectionTitle;
  final List<int> mockAvatarArgbColors;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipOval(
          child: SizedBox(
            width: avatarDiameter,
            height: avatarDiameter,
            child: const ColoredBox(color: AppColors.darkSurface),
          ),
        ),
        const SizedBox(width: AppSpacing.lg - AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sectionLabel, style: AppTextStyles.small),
                const SizedBox(height: AppSpacing.sm),
                Text(sectionTitle, style: AppTextStyles.sectionTitle),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
