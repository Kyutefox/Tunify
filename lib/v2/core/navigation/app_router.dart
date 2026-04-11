import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';

/// Custom page route with consistent dark background during transitions
///
/// Fixes the "glimpse" issue where previous/next content shows through
/// during page animations by ensuring the background stays nearBlack
/// throughout the entire transition.
class TunifyPageRoute<T> extends MaterialPageRoute<T> {
  TunifyPageRoute({
    required super.builder,
    super.settings,
    super.maintainState,
    super.fullscreenDialog,
  });

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Use a FadeTransition combined with SlideTransition
    // This creates a smooth transition without content glimpsing
    final slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
    ));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOut,
    ));

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: Container(
          // Ensure background stays consistent during transition
          color: AppColors.nearBlack,
          child: child,
        ),
      ),
    );
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);
}

/// Helper extension to use custom route for navigation
extension TunifyNavigation on BuildContext {
  /// Push a new route with Tunify's custom transition
  Future<T?> pushTunifyRoute<T>(Widget screen) {
    return Navigator.of(this).push(
      TunifyPageRoute(builder: (_) => screen),
    );
  }

  /// Replace current route with Tunify's custom transition
  Future<T?> pushReplacementTunifyRoute<T>(Widget screen) {
    return Navigator.of(this).pushReplacement(
      TunifyPageRoute(builder: (_) => screen),
    );
  }
}
