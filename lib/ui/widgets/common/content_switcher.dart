import 'package:flutter/material.dart';

/// In-place content transition matching the Library screen behavior.
///
/// - Replaces outgoing child immediately (no overlap frame).
/// - Animates incoming child with fade + micro-slide.
class AppContentSwitcher extends StatefulWidget {
  const AppContentSwitcher({
    super.key,
    required this.contentKey,
    required this.child,
  });

  final ValueKey<String> contentKey;
  final Widget child;

  @override
  State<AppContentSwitcher> createState() => _AppContentSwitcherState();
}

class _AppContentSwitcherState extends State<AppContentSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  late Widget _current;
  late ValueKey<String> _currentKey;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      value: 1.0,
    );
    final curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _fade = curved;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(curved);

    _current = widget.child;
    _currentKey = widget.contentKey;
  }

  @override
  void didUpdateWidget(AppContentSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contentKey != _currentKey) {
      _current = widget.child;
      _currentKey = widget.contentKey;
      _ctrl.forward(from: 0.0);
    } else {
      _current = widget.child;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _current,
      ),
    );
  }
}
