import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_button_styles.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/features/auth/presentation/providers/auth_providers.dart';
import 'package:tunify/v2/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:tunify/v2/features/auth/presentation/providers/form_validation_provider.dart';
import 'package:tunify/v2/features/auth/presentation/screens/privacy_policy_screen.dart';
import 'package:tunify/v2/features/auth/presentation/screens/terms_of_use_screen.dart';
import 'package:tunify/v2/features/auth/presentation/widgets/auth_input_field.dart';
import 'package:tunify/v2/features/home/presentation/providers/home_providers.dart';
import 'package:tunify/v2/features/user/presentation/providers/user_providers.dart';

/// Sign Up Step 3: Username
///
/// Registration flow - create username
/// Uses Riverpod for form validation state per RULES.md:
/// - No business logic in UI
/// - State management through providers
class SignupUsernameScreen extends ConsumerStatefulWidget {
  const SignupUsernameScreen({super.key});

  @override
  ConsumerState<SignupUsernameScreen> createState() =>
      _SignupUsernameScreenState();
}

class _SignupUsernameScreenState extends ConsumerState<SignupUsernameScreen> {
  final _usernameController = TextEditingController();
  final ValueNotifier<bool> _isSubmitting = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _usernameController.dispose();
    _isSubmitting.dispose();
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
                  onChanged: formNotifier.setUsername,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Terms agreement checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // I agree to the Tunify
                          Text(
                            'I agree to the Tunify ',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                          // Terms of use link
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TermsOfUseScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Terms of use',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.brandGreen,
                              ),
                            ),
                          ),
                          // and
                          Text(
                            ' and ',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                          // Privacy Policy link
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PrivacyPolicyScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Privacy Policy',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.brandGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Circular checkbox on the right
                    GestureDetector(
                      onTap: formNotifier.toggleAgreedToTerms,
                      child: Container(
                        width: AppSpacing.checkboxSize,
                        height: AppSpacing.checkboxSize,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: formState.agreedToTerms
                                ? AppColors.brandGreen
                                : AppColors.lightBorder,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(50),
                          color: formState.agreedToTerms
                              ? AppColors.brandGreen
                              : Colors.transparent,
                        ),
                        child: formState.agreedToTerms
                            ? const Icon(
                                Icons.check,
                                size: AppSpacing.checkboxIconSize,
                                color: AppColors.nearBlack,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Create account button
                // Validation logic is in the provider per RULES.md
                ValueListenableBuilder<bool>(
                  valueListenable: _isSubmitting,
                  builder: (context, isSubmitting, _) {
                    return AppButtonStyles.brandGreenLargePill(
                      label:
                          isSubmitting ? 'Creating account…' : 'Create account',
                      width: double.infinity,
                      onPressed: formState.isUsernameStepValid && !isSubmitting
                          ? () async {
                              _isSubmitting.value = true;
                              final auth = ref.read(authRepositoryProvider);
                              final result = await auth.signUp(
                                formState.email.trim(),
                                formState.password,
                                formState.username.trim(),
                              );
                              if (!context.mounted) {
                                return;
                              }
                              _isSubmitting.value = false;
                              result.fold(
                                (user) {
                                  ref.invalidate(homeFeedProvider);
                                  ref.invalidate(currentUserProvider);
                                  ref
                                      .read(formValidationProvider.notifier)
                                      .reset();
                                  ref
                                      .read(authSessionProvider.notifier)
                                      .applySignedInUser(user);
                                },
                                (failure) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(failure.message)),
                                  );
                                },
                              );
                            }
                          : null,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
