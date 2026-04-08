import 'package:flutter/material.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/features/auth/auth_provider.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/widgets/common/input_field.dart';

/// Email / password (and optional username) fields for onboarding auth.
class OnboardingCredentialFields extends StatelessWidget {
  const OnboardingCredentialFields({
    super.key,
    required this.formKey,
    required this.usernameCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.isSignUp,
    required this.obscurePassword,
    required this.onToggleObscure,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool isSignUp;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          AnimatedSize(
            duration: AppDuration.normal,
            curve: AppCurves.emphasized,
            child: isSignUp
                ? Column(
                    children: [
                      OnboardingLabeledField(
                        controller: usernameCtrl,
                        label: 'Username',
                        hint: 'Choose a username',
                        prefixIcon: AppIcons.personOutline,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Username is required';
                          }
                          if (v.trim().length < 3) {
                            return 'At least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.base),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          OnboardingLabeledField(
            controller: emailCtrl,
            label: 'Email',
            hint: 'your@email.com',
            prefixIcon: AppIcons.mail,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              final re = RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
              if (!re.hasMatch(v.trim())) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.base),
          OnboardingLabeledField(
            controller: passwordCtrl,
            label: 'Password',
            hint: '••••••••',
            prefixIcon: AppIcons.lock,
            obscureText: obscurePassword,
            suffixIcon: GestureDetector(
              onTap: onToggleObscure,
              child: AppIcon(
                icon: obscurePassword
                    ? AppIcons.visibility
                    : AppIcons.visibilityOff,
                size: UISize.iconMd,
                color: AppColors.textMuted,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'At least 6 characters';
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class OnboardingLabeledField extends StatelessWidget {
  const OnboardingLabeledField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final List<List<dynamic>> prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle.labelBase.copyWith(
            color: AppColors.textSecondary.withValues(alpha: UIOpacity.high),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        AppInputField(
          controller: controller,
          hintText: hint,
          prefixIcon: AppIcon(
            icon: prefixIcon,
            size: UISize.iconMd,
            color: AppColors.textMuted,
          ),
          suffixIcon: suffixIcon,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: InputFieldStyle.outlined,
        ),
      ],
    );
  }
}

class OnboardingAuthStatusBanners extends StatelessWidget {
  const OnboardingAuthStatusBanners({super.key, required this.authState});

  final AuthActionState authState;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (authState.emailConfirmationPending)
          OnboardingNoticeBanner(
            icon: AppIcons.markEmailUnread,
            message:
                'Account created! Check your email to confirm your address, then sign in.',
            color: AppColors.primary,
          ),
        if (authState.error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          OnboardingNoticeBanner(
            icon: AppIcons.errorOutline,
            message: authState.error!,
            color: AppColors.accentRed,
          ),
        ],
      ],
    );
  }
}

class OnboardingNoticeBanner extends StatelessWidget {
  const OnboardingNoticeBanner({
    super.key,
    required this.icon,
    required this.message,
    required this.color,
  });

  final List<List<dynamic>> icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: UIOpacity.subtle + UIOpacity.faint),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: color.withValues(alpha: UIOpacity.medium),
          width: UIStroke.hairline,
        ),
      ),
      child: Row(
        children: [
          AppIcon(icon: icon, color: color, size: UISize.iconMd),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: AppFontSize.md,
                height: AppLineHeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingAuthModeToggleLink extends StatelessWidget {
  const OnboardingAuthModeToggleLink({
    super.key,
    required this.isSignUp,
    required this.onToggle,
  });

  final bool isSignUp;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final prefix =
        isSignUp ? 'Already have an account? ' : "Don't have an account? ";
    final action = isSignUp ? 'Sign In' : 'Sign Up';
    return Center(
      child: GestureDetector(
        onTap: onToggle,
        child: RichText(
          text: TextSpan(
            style: AppTextStyle.bodyBase.copyWith(
              color: AppColors.textSecondary.withValues(alpha: UIOpacity.high),
            ),
            children: [
              TextSpan(text: prefix),
              TextSpan(
                text: action,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
