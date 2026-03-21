import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/ui/button.dart';
import '../components/ui/input_field.dart';
import '../components/ui/sheet.dart';
import '../../config/app_icons.dart';
import '../../config/app_strings.dart';
import '../../shared/providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.initialSignUp = false});
  final bool initialSignUp;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showRawSheet(
        context,
        child: AuthBottomSheet(initialSignUp: widget.initialSignUp),
      );
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(backgroundColor: AppColors.background);
}


class AuthBottomSheet extends ConsumerStatefulWidget {
  const AuthBottomSheet({super.key, this.initialSignUp = false});
  final bool initialSignUp;

  @override
  ConsumerState<AuthBottomSheet> createState() => _AuthBottomSheetState();
}

class _AuthBottomSheetState extends ConsumerState<AuthBottomSheet>
    with WidgetsBindingObserver {
  late bool _isSignUp;
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  // Tracks the real keyboard height in logical pixels, bypassing the global
  // _NoKeyboardShift wrapper which zeroes viewInsets for all other screens.
  double _keyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialSignUp;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final view = View.of(context);
    final height = view.viewInsets.bottom / view.devicePixelRatio;
    if (height != _keyboardHeight) {
      setState(() => _keyboardHeight = height);
    }
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

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _formKey.currentState?.reset();
      ref.read(authNotifierProvider.notifier).clearError();
    });
  }

  void _unfocus() => FocusManager.instance.primaryFocus?.unfocus();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final bottomInset = _keyboardHeight;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.xl),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.98),
          border: const Border(
            top: BorderSide(color: AppColors.glassBorder, width: 0.5),
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              top: AppSpacing.md,
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
            ),
            child: GestureDetector(
              onTap: _unfocus,
              behavior: HitTestBehavior.translucent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  AnimatedSwitcher(
                    duration: AppDuration.normal,
                    child: Text(
                      _isSignUp ? 'Create Account' : 'Welcome Back',
                      key: ValueKey(_isSignUp),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.1,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  AnimatedSwitcher(
                    duration: AppDuration.normal,
                    child: Text(
                      _isSignUp
                          ? 'Your library, your way.'
                          : 'Sign in to continue to ${AppStrings.appName}',
                      key: ValueKey('sub_$_isSignUp'),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AnimatedSize(
                          duration: AppDuration.normal,
                          curve: AppCurves.emphasized,
                          child: _isSignUp
                              ? Column(
                                  children: [
                                    AppInputField(
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
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),

                        AppInputField(
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
                            final emailRe =
                                RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
                            if (!emailRe.hasMatch(v.trim())) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppSpacing.md),

                        AppInputField(
                          controller: _passwordCtrl,
                          labelText: 'Password',
                          prefixIcon: AppIcon(
                            icon: AppIcons.lock,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                          obscureText: _obscurePassword,
                          suffixIcon: GestureDetector(
                            onTap: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            child: AppIcon(
                              icon: _obscurePassword
                                  ? AppIcons.visibility
                                  : AppIcons.visibilityOff,
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
                        ),
                      ],
                    ),
                  ),

                  if (authState.emailConfirmationPending)
                    Container(
                      margin: const EdgeInsets.only(top: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.40),
                        ),
                      ),
                      child: Row(
                        children: [
                          AppIcon(
                              icon: AppIcons.markEmailUnread,
                              color: AppColors.accent,
                              size: 18),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Account created! Check your email to confirm your address, then sign in.',
                              style: TextStyle(
                                  color: AppColors.accent, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: AppDuration.normal),

                  if (authState.error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.accentRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.accentRed.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          AppIcon(
                            icon: AppIcons.errorOutline,
                            color: AppColors.accentRed,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              authState.error!,
                              style: const TextStyle(
                                color: AppColors.accentRed,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: AppDuration.fast).shakeX(),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  AppButton(
                    label: _isSignUp ? 'Create Account' : 'Sign In',
                    onPressed: _submit,
                    useGradient: true,
                    fullWidth: true,
                    isLoading: authState.isLoading,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  Center(
                    child: GestureDetector(
                      onTap: _toggleMode,
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                          children: [
                            TextSpan(
                              text: _isSignUp
                                  ? 'Already have an account? '
                                  : "Don't have an account? ",
                            ),
                            TextSpan(
                              text: _isSignUp ? 'Sign In' : 'Sign Up',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
