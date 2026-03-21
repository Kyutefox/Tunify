import 'package:flutter/material.dart';

/// Snappy fade+micro-slide transition.
/// Push: 240ms easeOutCubic — fast settle, no drag.
/// Pop:  200ms easeOutCubic — even snappier exit.
PageRouteBuilder<T> appPageRoute<T>({
  required WidgetBuilder builder,
  bool fullscreenDialog = false,
}) {
  return PageRouteBuilder<T>(
    fullscreenDialog: fullscreenDialog,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionDuration: const Duration(milliseconds: 240),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutCubic,
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
