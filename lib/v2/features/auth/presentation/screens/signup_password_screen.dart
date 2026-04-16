import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_button_styles.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/features/auth/presentation/providers/form_validation_provider.dart';
import 'package:tunify/v2/features/auth/presentation/screens/signup_username_screen.dart';
import 'package:tunify/v2/features/auth/presentation/widgets/auth_input_field.dart';

/// Sign Up Step 2: Password
///
/// Registration flow - create password
/// Uses Riverpod for form validation state per RULES.md
class SignupPasswordScreen extends ConsumerStatefulWidget {
  const SignupPasswordScreen({super.key});

  @override
  ConsumerState<SignupPasswordScreen> createState() =>
      _SignupPasswordScreenState();
}

class _SignupPasswordScreenState extends ConsumerState<SignupPasswordScreen> {
  final _passwordController = TextEditingController();
  final ValueNotifier<bool> _obscurePassword = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _passwordController.dispose();
    _obscurePassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(formValidationProvider);
    final formNotifier = ref.read(formValidationProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.nearBlack,
      appBar: AppBar(
        backgroundColor: AppColors.nearBlack,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: AppIcon(icon: AppIcons.back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Sign up',
          style: AppTextStyles.featureHeading.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),

                // Password input
                ValueListenableBuilder<bool>(
                  valueListenable: _obscurePassword,
                  builder: (context, obscurePassword, _) {
                    return AuthInputField(
                      label: 'Password',
                      controller: _passwordController,
                      isPassword: true,
                      obscureText: obscurePassword,
                      onToggleVisibility: () =>
                          _obscurePassword.value = !obscurePassword,
                      onChanged: formNotifier.setPassword,
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.xxxl),

                // Next button
                // Disabled when password is empty
                AppButtonStyles.brandGreenLargePill(
                  label: 'Next',
                  width: double.infinity,
                  onPressed: formState.isSignUpPasswordValid
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const SignupUsernameScreen(),
                            ),
                          );
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
