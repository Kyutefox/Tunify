import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Scrollable viewport with a bounded minimum height so a child [Column] can
/// safely use [Spacer]s without overflowing on short layouts / keyboards.
class OnboardingSpacedScrollBody extends StatelessWidget {
  const OnboardingSpacedScrollBody({
    super.key,
    required this.minContentHeight,
    required this.child,
  });

  final double minContentHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = math.max(constraints.maxHeight, minContentHeight);
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          clipBehavior: Clip.none,
          child: SizedBox(height: h, child: child),
        );
      },
    );
  }
}
