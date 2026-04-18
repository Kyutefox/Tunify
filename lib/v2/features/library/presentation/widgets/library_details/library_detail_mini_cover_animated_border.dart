import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_details_layout.dart';

/// Animation constants for the mini cover border animation.
class _MiniCoverAnimationConstants {
  static const double rotationRounds = 1.5;
  static const Duration rotationDuration = Duration(milliseconds: 1200);
  static const Duration mergeDuration = Duration(milliseconds: 300);
  static const double snakeLength = 0.25;
  static const double strokeWidth = 2.0;
  static const int pathSteps = 20;
}

/// Animated border wrapper with two snake arcs that chase each other then merge.
class LibraryDetailMiniCoverAnimatedBorder extends StatefulWidget {
  const LibraryDetailMiniCoverAnimatedBorder({
    super.key,
    required this.child,
    this.width = LibraryDetailsLayout.playlistActionMiniCoverWidth,
    this.height = LibraryDetailsLayout.playlistActionMiniCoverHeight,
    this.borderRadius = LibraryDetailsLayout.miniCoverCornerRadius,
  });

  final Widget child;
  final double width;
  final double height;
  final double borderRadius;

  @override
  State<LibraryDetailMiniCoverAnimatedBorder> createState() =>
      _LibraryDetailMiniCoverAnimatedBorderState();
}

class _LibraryDetailMiniCoverAnimatedBorderState
    extends State<LibraryDetailMiniCoverAnimatedBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _mergeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _MiniCoverAnimationConstants.rotationDuration *
              _MiniCoverAnimationConstants.rotationRounds +
          _MiniCoverAnimationConstants.mergeDuration,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: _MiniCoverAnimationConstants.rotationRounds * 360.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    _mergeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          _MiniCoverAnimationConstants.rotationRounds /
              (_MiniCoverAnimationConstants.rotationRounds + LibraryDetailsLayout.miniCoverBorderCurveOffset),
          1.0,
          curve: Curves.easeOut,
        ),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width + LibraryDetailsLayout.miniCoverBorderOffset,
      height: widget.height + LibraryDetailsLayout.miniCoverBorderOffset,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final rotation = _rotationAnimation.value;
          final mergeProgress = _mergeAnimation.value;

          return Stack(
            alignment: Alignment.center,
            children: [
              // First chasing snake
              if (mergeProgress < 1.0)
                _SnakeSegment(
                  width: widget.width + LibraryDetailsLayout.miniCoverBorderOffset,
                  height: widget.height + LibraryDetailsLayout.miniCoverBorderOffset,
                  borderRadius: widget.borderRadius + LibraryDetailsLayout.miniCoverBorderRadiusOffset,
                  color: AppColors.silver,
                  strokeWidth: _MiniCoverAnimationConstants.strokeWidth,
                  rotation: rotation,
                ),
              // Second chasing snake (offset by 180 degrees)
              if (mergeProgress < 1.0)
                _SnakeSegment(
                  width: widget.width + LibraryDetailsLayout.miniCoverBorderOffset,
                  height: widget.height + LibraryDetailsLayout.miniCoverBorderOffset,
                  borderRadius: widget.borderRadius + LibraryDetailsLayout.miniCoverBorderRadiusOffset,
                  color: AppColors.silver,
                  strokeWidth: _MiniCoverAnimationConstants.strokeWidth,
                  rotation: rotation + LibraryDetailsLayout.miniCoverBorderRotationOffset,
                ),
              // Merged full border (appears after animation)
              if (mergeProgress > 0.0)
                Opacity(
                  opacity: mergeProgress,
                  child: _FullBorder(
                    width: widget.width + LibraryDetailsLayout.miniCoverBorderOffset,
                    height: widget.height + LibraryDetailsLayout.miniCoverBorderOffset,
                    borderRadius: widget.borderRadius + LibraryDetailsLayout.miniCoverBorderRadiusOffset,
                    color: AppColors.silver,
                    strokeWidth: _MiniCoverAnimationConstants.strokeWidth,
                  ),
                ),
              // Mini cover child
              child!,
            ],
          );
        },
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: widget.child,
        ),
      ),
    );
  }
}

class _SnakeSegment extends StatelessWidget {
  const _SnakeSegment({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.color,
    required this.strokeWidth,
    required this.rotation,
  });

  final double width;
  final double height;
  final double borderRadius;
  final Color color;
  final double strokeWidth;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _SnakeSegmentPainter(
            width: width,
            height: height,
            borderRadius: borderRadius,
            color: color,
            strokeWidth: strokeWidth,
            rotation: rotation,
          ),
        ),
      ),
    );
  }
}

class _SnakeSegmentPainter extends CustomPainter {
  _SnakeSegmentPainter({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.color,
    required this.strokeWidth,
    required this.rotation,
  });

  final double width;
  final double height;
  final double borderRadius;
  final Color color;
  final double strokeWidth;
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Calculate position along the border perimeter (0-1.0)
    final normalizedRotation = (rotation % 360) / 360;

    // Draw smooth path following border with bezier curves
    final path = _calculateSnakePath(
      normalizedRotation,
      _MiniCoverAnimationConstants.snakeLength,
    );

    canvas.drawPath(path, paint);
  }

  Path _calculateSnakePath(double position, double length) {
    final path = Path();
    final perimeter = _calculatePerimeter();
    final startPx = position * perimeter;
    final steps = _MiniCoverAnimationConstants.pathSteps;

    for (int i = 0; i < steps; i++) {
      final t = i / (steps - 1);
      final currentPx = startPx + t * length * perimeter;
      final point = _getPointOnPerimeter(currentPx);
      
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        // Use quadratic bezier for smooth curves
        final prevPx = startPx + ((i - 1) / (steps - 1)) * length * perimeter;
        final prevPoint = _getPointOnPerimeter(prevPx);
        final midPx = (prevPx + currentPx) / 2;
        final midPoint = _getPointOnPerimeter(midPx);
        path.quadraticBezierTo(prevPoint.dx, prevPoint.dy, midPoint.dx, midPoint.dy);
      }
    }

    return path;
  }

  Offset _getPointOnPerimeter(double px) {
    final perimeter = _calculatePerimeter();
    final normalizedPx = px % perimeter;

    // Calculate edge lengths
    final topEdge = width - strokeWidth;
    final rightEdge = height - strokeWidth;
    final bottomEdge = width - strokeWidth;

    // Determine which edge
    if (normalizedPx < topEdge) {
      // Top edge
      return Offset(strokeWidth / 2 + normalizedPx, strokeWidth / 2);
    } else if (normalizedPx < topEdge + rightEdge) {
      // Right edge
      return Offset(width - strokeWidth / 2, strokeWidth / 2 + (normalizedPx - topEdge));
    } else if (normalizedPx < topEdge + rightEdge + bottomEdge) {
      // Bottom edge
      return Offset(width - strokeWidth / 2 - (normalizedPx - topEdge - rightEdge), height - strokeWidth / 2);
    } else {
      // Left edge
      return Offset(strokeWidth / 2, height - strokeWidth / 2 - (normalizedPx - topEdge - rightEdge - bottomEdge));
    }
  }

  double _calculatePerimeter() {
    return 2 * (width - strokeWidth) + 2 * (height - strokeWidth);
  }

  @override
  bool shouldRepaint(_SnakeSegmentPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.color != color;
  }
}

class _FullBorder extends StatelessWidget {
  const _FullBorder({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.color,
    required this.strokeWidth,
  });

  final double width;
  final double height;
  final double borderRadius;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: color,
          width: strokeWidth,
        ),
      ),
    );
  }
}
