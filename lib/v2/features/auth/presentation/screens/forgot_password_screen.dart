import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_button_styles.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/features/auth/presentation/providers/form_validation_provider.dart';
import 'package:tunify/v2/features/auth/presentation/widgets/auth_input_field.dart';

/// Forgot Password Screen
///
/// Password recovery flow:
/// - Email/username input
/// - Send reset link button
///
/// Per DESIGN.md:
/// - Background: #121212 (nearBlack)
/// - Inputs: transparent bg, 1px #7c7c7c border, 6px radius
/// - Primary CTA: Brand Green Large Pill
///
/// Uses Riverpod for form validation state per RULES.md
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
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
          'Forgot password',
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

                const SizedBox(height: AppSpacing.xxxl),

                // Send reset link button
                // Email validation logic is in the provider per RULES.md
                AppButtonStyles.brandGreenLargePill(
                  label: 'Send reset link',
                  width: double.infinity,
                  onPressed: formState.isEmailValid
                      ? () {
                          // TODO: Implement password reset
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
