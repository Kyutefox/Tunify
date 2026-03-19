import 'package:flutter/material.dart';
import '../../../../ui/theme/app_colors.dart';

class NowPlayingIndicator extends StatefulWidget {
  const NowPlayingIndicator(
      {super.key, this.size = 24, this.barCount = 4, this.animate = true});

  final double size;
  final int barCount;

  final bool animate;

  @override
  State<NowPlayingIndicator> createState() => _NowPlayingIndicatorState();
}

class _NowPlayingIndicatorState extends State<NowPlayingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.barCount, (i) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 400 + (i * 120)),
        vsync: this,
      );
      if (widget.animate) {
        controller.repeat(reverse: true);
      }
      return controller;
    });
    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0.25, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();
  }

  @override
  void didUpdateWidget(NowPlayingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      for (final c in _controllers) {
        widget.animate ? c.repeat(reverse: true) : c.stop();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(widget.barCount, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, _) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.2),
              width: 3,
              height: widget.size * _animations[i].value,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          },
        );
      }),
    );
  }
}

class NowPlayingThumbnail extends StatelessWidget {
  const NowPlayingThumbnail({
    super.key,
    required this.isPlaying,
    required this.size,
    required this.child,
    this.isActuallyPlaying = true,
  });

  final bool isPlaying;
  final double size;
  final Widget child;

  final bool isActuallyPlaying;

  @override
  Widget build(BuildContext context) {
    if (!isPlaying) return child;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          child,
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: NowPlayingIndicator(
                    size: size * 0.45, animate: isActuallyPlaying),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
