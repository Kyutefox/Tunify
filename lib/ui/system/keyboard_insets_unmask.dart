import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KeyboardInsetsUnmaskCountNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void push() => state = state + 1;

  void pop() => state = state > 0 ? state - 1 : 0;
}

/// While the count is above zero, [MaterialApp]'s keyboard freeze is off (real insets).
final keyboardInsetsUnmaskCountProvider =
    NotifierProvider<KeyboardInsetsUnmaskCountNotifier, int>(
  KeyboardInsetsUnmaskCountNotifier.new,
);

/// Opts the subtree out of the app-wide “freeze layout when keyboard opens” policy.
class KeyboardInsetsUnmaskScope extends ConsumerStatefulWidget {
  const KeyboardInsetsUnmaskScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<KeyboardInsetsUnmaskScope> createState() =>
      _KeyboardInsetsUnmaskScopeState();
}

class _KeyboardInsetsUnmaskScopeState
    extends ConsumerState<KeyboardInsetsUnmaskScope> {
  bool _didPush = false;

  @override
  void initState() {
    super.initState();
    // Avoid "modify provider while building" when this mounts under a route
    // transition (e.g. [SlideTransition]) — [MaterialApp] may be watching
    // the same notifier via [_NoKeyboardShift] during that build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(keyboardInsetsUnmaskCountProvider.notifier).push();
      _didPush = true;
    });
  }

  @override
  void dispose() {
    final notifier = ref.read(keyboardInsetsUnmaskCountProvider.notifier);
    final didPush = _didPush;
    super.dispose();
    Future.microtask(() {
      if (didPush) notifier.pop();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
