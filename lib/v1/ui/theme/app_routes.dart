import 'package:flutter/material.dart';

import 'package:tunify/v1/ui/system/keyboard_insets_unmask.dart';
import 'package:tunify/v1/ui/theme/design_tokens.dart';

/// Snappy fade+micro-slide transition.
/// Push: 240ms easeOutCubic — fast settle, no drag.
/// Pop:  200ms easeOutCubic — even snappier exit.
///
/// Set [keyboardInsetsUnmasked] for explicit form pages (e.g. sign in, sign up,
/// profile setup) so the app-wide keyboard freeze in [MaterialApp.builder] does
/// not apply while that route is on screen.
PageRouteBuilder<T> appPageRoute<T>({
  required WidgetBuilder builder,
  bool fullscreenDialog = false,
  bool keyboardInsetsUnmasked = false,
}) {
  return PageRouteBuilder<T>(
    fullscreenDialog: fullscreenDialog,
    pageBuilder: (context, animation, secondaryAnimation) {
      final page = builder(context);
      return keyboardInsetsUnmasked
          ? KeyboardInsetsUnmaskScope(child: page)
          : page;
    },
    transitionDuration: AppDuration.fastPlus,
    reverseTransitionDuration: AppDuration.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppCurves.decelerate,
        reverseCurve: AppCurves.decelerate,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
