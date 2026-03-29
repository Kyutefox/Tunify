import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/ui/widgets/common/sheet.dart';
import 'package:tunify/ui/widgets/auth/auth_shared.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

class MobileAuthScreen extends ConsumerStatefulWidget {
  const MobileAuthScreen({super.key, this.initialSignUp = false});
  final bool initialSignUp;

  @override
  ConsumerState<MobileAuthScreen> createState() => _MobileAuthScreenState();
}

class _MobileAuthScreenState extends ConsumerState<MobileAuthScreen>
    with WidgetsBindingObserver {
  double _keyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  void _unfocus() => FocusManager.instance.primaryFocus?.unfocus();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.xl),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColorsScheme.of(context).surface.withValues(alpha: 0.98),
          border: const Border(
            top: BorderSide(color: AppColors.glassBorder, width: 0.5),
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: _keyboardHeight),
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
                        color: AppColorsScheme.of(context).textMuted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AuthForm(initialSignUp: widget.initialSignUp),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
        child: MobileAuthScreen(initialSignUp: widget.initialSignUp),
      );
    });
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(backgroundColor: AppColorsScheme.of(context).background);
}
