import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_button_styles.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/features/auth/presentation/widgets/auth_input_field.dart';

/// Sign Up Step 3: Username
///
/// Registration flow - create username
class SignupUsernameScreen extends StatefulWidget {
  const SignupUsernameScreen({super.key});

  @override
  State<SignupUsernameScreen> createState() => _SignupUsernameScreenState();
}

class _SignupUsernameScreenState extends State<SignupUsernameScreen> {
  final _usernameController = TextEditingController();
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _usernameController.text.trim().isNotEmpty && _agreedToTerms;
  }

  @override
  Widget build(BuildContext context) {
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

                // Username input
                AuthInputField(
                  label: 'Username',
                  controller: _usernameController,
                  keyboardType: TextInputType.text,
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Terms agreement checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.white,
                          ),
                          children: [
                            const TextSpan(text: 'I agree to the Tunify '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  // TODO: Navigate to Terms of use
                                },
                                child: Text(
                                  'Terms of use',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.brandGreen,
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  // TODO: Navigate to Privacy Policy
                                },
                                child: Text(
                                  'Privacy Policy',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.brandGreen,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Checkbox on the right
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _agreedToTerms = !_agreedToTerms;
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _agreedToTerms
                                ? AppColors.brandGreen
                                : AppColors.lightBorder,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          color: _agreedToTerms
                              ? AppColors.brandGreen
                              : Colors.transparent,
                        ),
                        child: _agreedToTerms
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: AppColors.nearBlack,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Create account button
                AppButtonStyles.brandGreenLargePill(
                  label: 'Create account',
                  width: double.infinity,
                  onPressed: _isFormValid
                      ? () {
                          // TODO: Complete registration
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
