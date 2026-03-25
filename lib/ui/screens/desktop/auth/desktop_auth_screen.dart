import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:tunify/ui/widgets/auth/auth_shared.dart';
import 'package:tunify/ui/widgets/auth/desktop_auth_layout.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';

class DesktopAuthScreen extends StatelessWidget {
  const DesktopAuthScreen({super.key, this.initialSignUp = false});
  final bool initialSignUp;

  @override
  Widget build(BuildContext context) {
    return DesktopAuthLayout(
      rightContent: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(
              color: AppColors.glassBorder,
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: AuthForm(initialSignUp: initialSignUp, showHeader: false),
        ).animate().fadeIn(duration: AppDuration.slow).slideY(
              begin: 0.1,
              end: 0,
              duration: AppDuration.slow,
              curve: Curves.easeOut,
            ),
      ),
    );
  }
}
