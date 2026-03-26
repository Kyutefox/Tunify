import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/core/constants/app_strings.dart';
import 'package:tunify/features/auth/auth_provider.dart';
import 'package:tunify/ui/widgets/common/button.dart';
import 'package:tunify/ui/widgets/common/input_field.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';

class AuthForm extends ConsumerStatefulWidget {
  const AuthForm({
    super.key,
    this.initialSignUp = false,
    this.showHeader = true,
    this.onToggle,
  });
  final bool initialSignUp;
  final bool showHeader;
  final VoidCallback? onToggle;

  @override
  ConsumerState<AuthForm> createState() => AuthFormState();
}

class AuthFormState extends ConsumerState<AuthForm> {
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

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _formKey.currentState?.reset();
      ref.read(authNotifierProvider.notifier).clearError();
    });
    widget.onToggle?.call();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(authNotifierProvider.notifier).clearError();
    final notifier = ref.read(authNotifierProvider.notifier);
    bool ok;
    if (_isSignUp) {
      ok = await notifier.signUp(
        username: _usernameCtrl.text,
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
    } else {
      ok = await notifier.signIn(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
    }
    if (ok && mounted) {
      final pending = ref.read(authNotifierProvider).emailConfirmationPending;
      if (!pending) {
        Navigator.of(context).pop();
      }
    }
  }

  String get _title => _isSignUp ? 'Create Account' : 'Welcome Back';
  String get _subtitle => _isSignUp
      ? 'Your library, your way.'
      : 'Sign in to continue to ${AppStrings.appName}';
  String get _submitLabel => _isSignUp ? 'Create Account' : 'Sign In';
  String get _toggleText =>
      _isSignUp ? 'Already have an account? ' : "Don't have an account? ";
  String get _toggleAction => _isSignUp ? 'Sign In' : 'Sign Up';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader) ...[
          AnimatedSwitcher(
            duration: AppDuration.normal,
            child: Text(
              _title,
              key: ValueKey(_title),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppFontSize.h1,
                fontWeight: FontWeight.w800,
                letterSpacing: AppLetterSpacing.display,
                height: AppLineHeight.tight,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedSwitcher(
            duration: AppDuration.normal,
            child: Text(
              _subtitle,
              key: ValueKey(_subtitle),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppFontSize.base,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        _buildFormFields(),
        const SizedBox(height: AppSpacing.lg),
        _buildStatusBanners(authState),
        const SizedBox(height: AppSpacing.xl),
        _buildSubmitButton(authState),
        const SizedBox(height: AppSpacing.md),
        _buildToggleLink(),
      ],
    );
  }

  Widget _buildFormFields() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AnimatedSize(
            duration: AppDuration.normal,
            curve: AppCurves.emphasized,
            child: _isSignUp
                ? Column(
                    children: [
                      _buildUsernameField(),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          _buildEmailField(),
          const SizedBox(height: AppSpacing.md),
          _buildPasswordField(),
        ],
      ),
    );
  }

  Widget _buildUsernameField() {
    return AppInputField(
      controller: _usernameCtrl,
      labelText: 'Username',
      prefixIcon: AppIcon(
        icon: AppIcons.personOutline,
        color: AppColors.textMuted,
        size: 18,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Username is required';
        }
        if (v.trim().length < 3) {
          return 'At least 3 characters';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return AppInputField(
      controller: _emailCtrl,
      labelText: 'Email',
      prefixIcon: AppIcon(
        icon: AppIcons.mail,
        color: AppColors.textMuted,
        size: 18,
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Email is required';
        }
        final emailRe = RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
        if (!emailRe.hasMatch(v.trim())) {
          return 'Enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return AppInputField(
      controller: _passwordCtrl,
      labelText: 'Password',
      prefixIcon: AppIcon(
        icon: AppIcons.lock,
        color: AppColors.textMuted,
        size: 18,
      ),
      obscureText: _obscurePassword,
      suffixIcon: GestureDetector(
        onTap: () => setState(() => _obscurePassword = !_obscurePassword),
        child: AppIcon(
          icon: _obscurePassword ? AppIcons.visibility : AppIcons.visibilityOff,
          color: AppColors.textMuted,
          size: 18,
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) {
          return 'Password is required';
        }
        if (v.length < 6) {
          return 'At least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildStatusBanners(AuthActionState authState) {
    return Column(
      children: [
        if (authState.emailConfirmationPending) ...[
          const SizedBox(height: AppSpacing.md),
          _buildInfoBanner(
            icon: AppIcons.markEmailUnread,
            message:
                'Account created! Check your email to confirm your address, then sign in.',
            color: AppColors.primary,
          ),
        ],
        if (authState.error != null) ...[
          const SizedBox(height: AppSpacing.md),
          _buildInfoBanner(
            icon: AppIcons.errorOutline,
            message: authState.error!,
            color: AppColors.accentRed,
          ).animate().fadeIn(duration: AppDuration.fast).shakeX(),
        ],
      ],
    );
  }

  Widget _buildInfoBanner({
    required List<List<dynamic>> icon,
    required String message,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          AppIcon(icon: icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: AppFontSize.md),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AuthActionState authState) {
    return AppButton(
      label: _submitLabel,
      onPressed: _submit,
      useGradient: true,
      fullWidth: true,
      isLoading: authState.isLoading,
    );
  }

  Widget _buildToggleLink() {
    return Center(
      child: GestureDetector(
        onTap: _toggleMode,
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppFontSize.base,
            ),
            children: [
              TextSpan(text: _toggleText),
              TextSpan(
                text: _toggleAction,
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
