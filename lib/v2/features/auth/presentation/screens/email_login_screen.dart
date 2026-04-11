import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_button_styles.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/features/auth/presentation/providers/form_validation_provider.dart';
import 'package:tunify/v2/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:tunify/v2/features/auth/presentation/widgets/auth_input_field.dart';

/// Email/Phone Login Screen - Minimal form design
///
/// Clean layout with:
/// - Back button
/// - Centered "Sign in" title
/// - Email/username input
/// - Password input with eye icon
/// - Forgot password (right aligned)
/// - Sign in button
///
/// Per DESIGN.md:
/// - Background: #121212 (nearBlack)
/// - Inputs: #1f1f1f bg, 500px radius
/// - Primary CTA: Brand Green Large Pill
///
/// Uses Riverpod for form validation state per RULES.md
class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Sign in',
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

                // Email/username input
                AuthInputField(
                  label: 'Email or username',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: formNotifier.setEmail,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Password input
                AuthInputField(
                  label: 'Password',
                  controller: _passwordController,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  onChanged: formNotifier.setPassword,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Forgot password - right aligned
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot password',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxxl),

                // Sign in button
                // Form validation logic is in the provider per RULES.md
                AppButtonStyles.brandGreenLargePill(
                  label: 'Sign in',
                  width: double.infinity,
                  onPressed: formState.isLoginFormValid
                      ? () {
                          // TODO: Implement login
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
