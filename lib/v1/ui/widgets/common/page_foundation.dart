import 'package:flutter/material.dart';

import 'package:tunify/v1/ui/theme/app_colors_scheme.dart';
import 'package:tunify/v1/ui/theme/design_tokens.dart';

/// Shared page scaffold foundation used across full-screen pages.
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsScheme.of(context).background,
      appBar: appBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: body,
    );
  }
}

/// Shared centered form body with optional keyboard-aware lift.
class AppCenteredFormBody extends StatelessWidget {
  const AppCenteredFormBody({
    super.key,
    required this.keyboardOpen,
    required this.keyboardShift,
    required this.child,
  });

  final bool keyboardOpen;
  final double keyboardShift;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardOpen ? keyboardShift : 0),
      child: AnimatedAlign(
        duration: AppDuration.fast,
        curve: AppCurves.decelerate,
        alignment: keyboardOpen ? const Alignment(0, -0.22) : Alignment.center,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xxxl,
            keyboardOpen ? AppSpacing.xl : AppSpacing.base,
            AppSpacing.xxxl,
            AppSpacing.base,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: child,
          ),
        ),
      ),
    );
  }
}
