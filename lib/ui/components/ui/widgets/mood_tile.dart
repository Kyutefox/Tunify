import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../config/app_icons.dart';
import '../../../../models/mood.dart';

class MoodTile extends StatefulWidget {
  final Mood mood;
  final VoidCallback? onTap;
  final int index;
  final double width;
  final double height;

  const MoodTile({
    super.key,
    required this.mood,
    this.onTap,
    this.index = 0,
    this.width = 100,
    this.height = 120,
  });

  @override
  State<MoodTile> createState() => _MoodTileState();
}

class _MoodTileState extends State<MoodTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: widget.width,
        height: widget.height,
        margin: const EdgeInsets.only(right: 12),
        transform: Matrix4.identity()
          ..scaleByDouble(
              _isPressed ? 0.93 : 1.0, _isPressed ? 0.93 : 1.0, 1.0, 1.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: widget.mood.gradient,
                ),
              ),
              AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      (widget.width * 2) * _shimmerController.value -
                          widget.width,
                      0,
                    ),
                    child: Container(
                      width: widget.width / 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: 0.15),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.mood.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.mood.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (widget.mood.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.mood.subtitle!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 50))
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutCubic);
  }
}

class LargeMoodCard extends StatefulWidget {
  final Mood mood;
  final VoidCallback? onTap;
  final int index;

  const LargeMoodCard({
    super.key,
    required this.mood,
    this.onTap,
    this.index = 0,
  });

  @override
  State<LargeMoodCard> createState() => _LargeMoodCardState();
}

class _LargeMoodCardState extends State<LargeMoodCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final halfWidth = (MediaQuery.of(context).size.width - 52) / 2;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: halfWidth,
        height: 100,
        transform: Matrix4.identity()
          ..scaleByDouble(
              _isPressed ? 0.95 : 1.0, _isPressed ? 0.95 : 1.0, 1.0, 1.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: widget.mood.gradient,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            widget.mood.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.mood.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.mood.icon != null)
                      AppIcon(
                        icon: widget.mood.icon!,
                        color: Colors.white.withValues(alpha: 0.4),
                        size: 32,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 60))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, curve: Curves.easeOutCubic);
  }
}

class MoodGrid extends StatelessWidget {
  final List<Mood> moods;
  final Function(Mood)? onMoodTap;

  const MoodGrid({
    super.key,
    required this.moods,
    this.onMoodTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: moods.asMap().entries.map((entry) {
          return LargeMoodCard(
            mood: entry.value,
            index: entry.key,
            onTap: () => onMoodTap?.call(entry.value),
          );
        }).toList(),
      ),
    );
  }
}
