import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';

/// Loading Screen
///
/// Dedicated loading page with Spotify-style 3-dot horizontal loader
/// Used for initialization and async operations
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({
    super.key,
    this.embedInParentScaffold = false,
  });

  /// When true, omits [Scaffold] so this can sit inside another scaffold (e.g. home feed).
  final bool embedInParentScaffold;

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Create staggered animations for each dot
    _animations = List.generate(3, (index) {
      final start = index * 0.2;
      final end = start + 0.6;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeInOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              // Calculate scale based on animation value
              // Goes from 0.6 to 1.0 and back
              final scale = 0.6 + (_animations[index].value * 0.4);
              final opacity = 0.4 + (_animations[index].value * 0.6);

              return Container(
                width: AppSpacing.lg,
                height: AppSpacing.lg,
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(
                    255,
                    255,
                    255,
                    opacity,
                  ),
                  shape: BoxShape.circle,
                ),
                transform: Matrix4.identity()..scaleByDouble(scale, scale, 1, 1),
                transformAlignment: Alignment.center,
              );
            },
          );
        }),
      ),
    );

    if (widget.embedInParentScaffold) {
      return ColoredBox(
        color: AppColors.nearBlack,
        child: dots,
      );
    }
    return Scaffold(
      backgroundColor: AppColors.nearBlack,
      body: dots,
    );
  }
}
