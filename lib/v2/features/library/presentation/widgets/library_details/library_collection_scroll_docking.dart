import 'package:flutter/material.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_details_layout.dart';

/// Play button that tracks scroll then pins under the app bar (v1 [CollectionDetailScaffold]).
class LibraryCollectionDockingPlayButton extends StatefulWidget {
  const LibraryCollectionDockingPlayButton({
    super.key,
    required this.scrollController,
    required this.appBarHeight,
    required this.actionRowMeasureKey,
    required this.stackKey,
    required this.buttonDiameter,
    required this.child,
  });

  final ScrollController scrollController;
  final double appBarHeight;
  final GlobalKey actionRowMeasureKey;
  final GlobalKey stackKey;
  final double buttonDiameter;
  final Widget child;

  @override
  State<LibraryCollectionDockingPlayButton> createState() =>
      _LibraryCollectionDockingPlayButtonState();
}

class _LibraryCollectionDockingPlayButtonState
    extends State<LibraryCollectionDockingPlayButton> {
  static const double _rightPadding =
      LibraryDetailsLayout.collectionDockPlayRightInset;

  final ValueNotifier<double> _topNotifier = ValueNotifier(9999);
  double? _contentCenterY;
  late double _dockedCenterY;

  @override
  void initState() {
    super.initState();
    _dockedCenterY = widget.appBarHeight;
    _topNotifier.value =
        (widget.appBarHeight + 320) - widget.buttonDiameter / 2;
    widget.scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final ctx = widget.actionRowMeasureKey.currentContext;
    if (ctx == null) {
      return;
    }
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final stackBox =
        widget.stackKey.currentContext?.findRenderObject() as RenderBox?;
    final screenTop = stackBox != null
        ? box.localToGlobal(Offset.zero, ancestor: stackBox).dy
        : box.localToGlobal(Offset.zero).dy;
    final scroll = widget.scrollController.hasClients
        ? widget.scrollController.offset
        : 0.0;
    _contentCenterY = screenTop + scroll + box.size.height / 2;
    _updatePosition(scroll);
  }

  void _updatePosition(double scroll) {
    final contentCenter = _contentCenterY ?? (widget.appBarHeight + 320);
    final rawCenterY = contentCenter - scroll;
    final clampedCenterY = rawCenterY.clamp(_dockedCenterY, double.infinity);
    _topNotifier.value = clampedCenterY - widget.buttonDiameter / 2;
  }

  void _onScroll() {
    if (!mounted) {
      return;
    }
    final scroll = widget.scrollController.offset;
    if (_contentCenterY == null) {
      _measure();
    }
    _updatePosition(scroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _topNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _topNotifier,
      builder: (_, top, child) => Positioned(
        top: top,
        right: _rightPadding,
        child: child!,
      ),
      child: widget.child,
    );
  }
}

/// Full-width toolbar row that tracks scroll and clips under the app bar (v1).
class LibraryCollectionDockingActionRow extends StatefulWidget {
  const LibraryCollectionDockingActionRow({
    super.key,
    required this.scrollController,
    required this.appBarHeight,
    required this.actionRowMeasureKey,
    required this.stackKey,
    required this.height,
    required this.child,
  });

  final ScrollController scrollController;
  final double appBarHeight;
  final GlobalKey actionRowMeasureKey;
  final GlobalKey stackKey;
  final double height;
  final Widget child;

  @override
  State<LibraryCollectionDockingActionRow> createState() =>
      _LibraryCollectionDockingActionRowState();
}

class _LibraryCollectionDockingActionRowState
    extends State<LibraryCollectionDockingActionRow> {
  final ValueNotifier<double> _topNotifier = ValueNotifier(-1);
  double? _contentTopY;

  @override
  void initState() {
    super.initState();
    _topNotifier.value = widget.appBarHeight + 320;
    widget.scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final ctx = widget.actionRowMeasureKey.currentContext;
    if (ctx == null) {
      return;
    }
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final stackBox =
        widget.stackKey.currentContext?.findRenderObject() as RenderBox?;
    final screenTop = stackBox != null
        ? box.localToGlobal(Offset.zero, ancestor: stackBox).dy
        : box.localToGlobal(Offset.zero).dy;
    final scroll = widget.scrollController.hasClients
        ? widget.scrollController.offset
        : 0.0;
    _contentTopY = screenTop + scroll;
    _updatePosition(scroll);
  }

  void _updatePosition(double scroll) {
    final contentTop = _contentTopY ?? (widget.appBarHeight + 320);
    final rawTop = contentTop - scroll;
    _topNotifier.value = rawTop;
  }

  void _onScroll() {
    if (!mounted) {
      return;
    }
    final scroll = widget.scrollController.offset;
    if (_contentTopY == null) {
      _measure();
    }
    _updatePosition(scroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _topNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _topNotifier,
      builder: (_, top, child) {
        if (top == -1) {
          return const SizedBox.shrink();
        }
        if (top + widget.height <= widget.appBarHeight) {
          return const SizedBox.shrink();
        }
        return Positioned(
          top: top,
          left: 0,
          right: 0,
          height: widget.height,
          child: ClipRect(
            clipper: _LibraryCollectionTopClipper(
              clipTop: (widget.appBarHeight - top).clamp(0.0, widget.height),
            ),
            child: child!,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _LibraryCollectionTopClipper extends CustomClipper<Rect> {
  const _LibraryCollectionTopClipper({required this.clipTop});

  final double clipTop;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, clipTop, size.width, size.height - clipTop);

  @override
  bool shouldReclip(_LibraryCollectionTopClipper old) => old.clipTop != clipTop;
}
