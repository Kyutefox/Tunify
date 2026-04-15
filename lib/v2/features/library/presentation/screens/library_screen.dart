import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/navigation/app_top_navigation.dart';
import 'package:tunify/v2/core/widgets/navigation/user_menu_launcher.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.nearBlack,
      body: Column(
        children: [
          AppTopNavigation(
            leadingOnTap: () => launchUserMenu(context),
            middle: Text(
              'Your Library',
              style: AppTextStyles.sectionTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'Library view is coming next.',
                  style: AppTextStyles.caption,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
