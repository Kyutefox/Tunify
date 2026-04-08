import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_strings.dart';
import 'package:tunify/features/auth/auth_provider.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/app_routes.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/widgets/common/button.dart';
import 'package:tunify/ui/widgets/onboarding/onboarding_back_label_button.dart';
import 'package:tunify/ui/widgets/onboarding/onboarding_glass_panel.dart';
import 'package:tunify/ui/widgets/onboarding/onboarding_hero_section.dart';
import 'package:tunify/ui/widgets/onboarding/onboarding_layout_sizing.dart';
import 'package:tunify/ui/widgets/onboarding/onboarding_sign_in_form.dart';
import 'package:tunify/ui/widgets/onboarding/onboarding_spaced_scroll_body.dart';

/// Full-screen sign in or sign up — pushed as its own route for page transitions.
class OnboardingAuthScreen extends ConsumerStatefulWidget {
  const OnboardingAuthScreen({super.key, required this.initialSignUp});
  final bool initialSignUp;

  @override
  ConsumerState<OnboardingAuthScreen> createState() =>
      _OnboardingAuthScreenState();
}

class _OnboardingAuthScreenState extends ConsumerState<OnboardingAuthScreen> {
  late bool _isSignUp;
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialSignUp;
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _goToOtherMode() {
    ref.read(authNotifierProvider.notifier).clearError();
    Navigator.of(context).pushReplacement(
      appPageRoute<void>(
        keyboardInsetsUnmasked: true,
        builder: (_) => OnboardingAuthScreen(initialSignUp: !_isSignUp),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(authNotifierProvider.notifier).clearError();
    final notifier = ref.read(authNotifierProvider.notifier);
    final bool ok;
    if (_isSignUp) {
      ok = await notifier.signUp(
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    } else {
      ok = await notifier.signIn(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    }
    if (ok && mounted) {
      final pending = ref.read(authNotifierProvider).emailConfirmationPending;
      if (!pending) Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  String get _title =>
      _isSignUp ? 'Create your\naccount' : 'Welcome\nback';
  String get _subtitle => _isSignUp
      ? 'Your library, your rules.'
      : 'Sign in to sync with ${AppStrings.appName}.';
  String get _submitLabel => _isSignUp ? 'Create Account' : 'Sign In';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final minH = OnboardingLayoutSizing.authCredentialsMinHeight(
      authState,
      isSignUp: _isSignUp,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: OnboardingSpacedScrollBody(
            minContentHeight: minH,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: OnboardingHeroSection(
                    title: _title,
                    subtitle: _subtitle,
                  ),
                ),
                const Spacer(flex: 2),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: OnboardingGlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OnboardingCredentialFields(
                          formKey: _formKey,
                          usernameCtrl: _usernameCtrl,
                          emailCtrl: _emailCtrl,
                          passwordCtrl: _passwordCtrl,
                          isSignUp: _isSignUp,
                          obscurePassword: _obscurePassword,
                          onToggleObscure: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        if (authState.emailConfirmationPending ||
                            authState.error != null)
                          const SizedBox(height: AppSpacing.md),
                        OnboardingAuthStatusBanners(authState: authState),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          label: _submitLabel,
                          onPressed: _submit,
                          useGradient: true,
                          fullWidth: true,
                          isLoading: authState.isLoading,
                          height: UISize.buttonHeightLg,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        OnboardingAuthModeToggleLink(
                          isSignUp: _isSignUp,
                          onToggle: _goToOtherMode,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Center(
                          child: OnboardingBackLabelButton(
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 1),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
