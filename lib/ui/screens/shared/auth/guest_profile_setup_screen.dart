import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/widgets/auth/guest_profile_setup_form.dart';
import 'package:tunify/ui/widgets/common/button.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';

class GuestProfileSetupScreen extends ConsumerWidget {
  const GuestProfileSetupScreen({super.key, this.isInitial = true});

  final bool isInitial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.5),
                  radius: 1.0,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                if (!isInitial)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: AppSpacing.sm, top: AppSpacing.sm),
                      child: AppIconButton(
                        icon: AppIcon(
                            icon: AppIcons.back,
                            color: AppColors.textPrimary,
                            size: 22),
                        onPressed: () => Navigator.of(context).pop(),
                        style: AppIconButtonStyle.ghost,
                      ),
                    ),
                  ),
                const Spacer(),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: GuestProfileSetupForm(isInitial: isInitial),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
