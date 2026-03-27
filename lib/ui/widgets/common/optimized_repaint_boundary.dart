import 'package:flutter/material.dart';

/// Optimized RepaintBoundary wrapper for expensive widgets.
/// Use this to isolate widgets that don't need to repaint when parent rebuilds.
class OptimizedRepaintBoundary extends StatelessWidget {
  const OptimizedRepaintBoundary({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: child);
  }
}

/// Wrapper for album artwork to prevent repaints during position updates
class AlbumArtworkBoundary extends StatelessWidget {
  const AlbumArtworkBoundary({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: child);
  }
}

/// Wrapper for player controls to prevent repaints during position updates
class PlayerControlsBoundary extends StatelessWidget {
  const PlayerControlsBoundary({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: child);
  }
}

/// Wrapper for queue list to prevent repaints during playback
class QueueListBoundary extends StatelessWidget {
  const QueueListBoundary({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: child);
  }
}
