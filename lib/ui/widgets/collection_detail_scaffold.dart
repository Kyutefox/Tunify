import 'package:flutter/material.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';import 'package:tunify/ui/widgets/items/mini_player.dart';
import 'package:tunify/ui/widgets/button.dart';

const double kCollectionActionRowHeight = 56;
const double kCollectionSearchRowHeight = 56;
const double kCollectionShowTitleThreshold = 180;

class CollectionDetailScaffold extends StatefulWidget {
  const CollectionDetailScaffold({
    super.key,
    required this.isEmpty,
    required this.emptyChild,
    required this.bodySlivers,
    required this.hasSong,
    this.miniPlayerKey,
    this.title,
    this.headerExpandedChild,
    this.actionRow,
    this.actionRowHeight = kCollectionActionRowHeight,
    this.pills,
    this.searchField,
    this.headerSliver,
    this.paletteColor,
    this.playButton,
  });

  final bool isEmpty;
  final Widget emptyChild;
  final List<Widget> bodySlivers;
  final bool hasSong;
  final Key? miniPlayerKey;
  final String? title;
  final Widget? headerExpandedChild;
  final Widget? actionRow;
  final double actionRowHeight;
  final Widget? pills;
  final Widget? searchField;
  final Widget? headerSliver;
  final Color? paletteColor;
  final Widget? playButton;

  @override
  State<CollectionDetailScaffold> createState() =>
      _CollectionDetailScaffoldState();
}

class _CollectionDetailScaffoldState extends State<CollectionDetailScaffold> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _appBarOpacity = ValueNotifier(0.0);
  final GlobalKey _actionRowKey = GlobalKey();

  static const double _fadeStart = 140.0;
  static const double _fadeEnd = kCollectionShowTitleThreshold;

  bool get _useNewLayout =>
      widget.title != null &&
      widget.headerExpandedChild != null &&
      widget.actionRow != null;

  @override
  void initState() {
    super.initState();
    if (_useNewLayout) _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final opacity =
        ((offset - _fadeStart) / (_fadeEnd - _fadeStart)).clamp(0.0, 1.0);
    _appBarOpacity.value = opacity;
  }

  @override
  void dispose() {
    if (_useNewLayout) _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _appBarOpacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final appBarHeight = kToolbarHeight + topPadding;
    final hasPalette = widget.paletteColor != null;
    final hasPlayButton = widget.playButton != null && _useNewLayout;

    final pinnedBg = hasPalette
        ? PaletteTheme.appBarBackground(widget.paletteColor!)
        : AppColors.background;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          extendBodyBehindAppBar: hasPalette,
          appBar: _useNewLayout
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: ValueListenableBuilder<double>(
                    valueListenable: _appBarOpacity,
                    builder: (_, opacity, child) => ColoredBox(
                      color: pinnedBg.withValues(alpha: opacity),
                      child: child,
                    ),
                    child: AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      leading: Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.xs),
                        child: AppIconButton(
                          icon: AppIcon(
                            icon: AppIcons.back,
                            size: 22,
                            color: AppColors.textPrimary,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          iconSize: 22,
                        ),
                      ),
                      title: ValueListenableBuilder<double>(
                        valueListenable: _appBarOpacity,
                        builder: (_, opacity, __) => opacity >= 1.0
                            ? Text(
                                widget.title!,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: AppFontSize.xxl,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              )
                            : const SizedBox.shrink(),
                      ),
                      centerTitle: false,
                    ),
                  ),
                )
              : AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs),
                    child: AppIconButton(
                      icon: AppIcon(
                        icon: AppIcons.back,
                        size: 22,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      iconSize: 22,
                    ),
                  ),
                ),
          body: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.translucent,
            child: CustomScrollView(
              controller: _useNewLayout ? _scrollController : null,
              physics: const BouncingScrollPhysics(),
              slivers: widget.isEmpty
                  ? [widget.emptyChild]
                  : _useNewLayout
                      ? _buildSlivers(appBarHeight, hasPalette)
                      : [
                          if (hasPalette)
                            SliverToBoxAdapter(
                                child: SizedBox(height: appBarHeight)),
                          widget.headerSliver!,
                          ...widget.bodySlivers,
                        ],
            ),
          ),
          bottomNavigationBar: widget.hasSong
              ? SafeArea(
                  child: MiniPlayer(
                    key: widget.miniPlayerKey ??
                        const ValueKey('collection-detail-mini-player'),
                  ),
                )
              : null,
        ),
        if (hasPlayButton)
          _DockingPlayButton(
            scrollController: _scrollController,
            appBarHeight: appBarHeight,
            actionRowKey: _actionRowKey,
            child: widget.playButton!,
          ),
      ],
    );
  }

  List<Widget> _buildSlivers(double appBarHeight, bool hasPalette) {
    // The header sliver wraps the expanded content in a Stack so the palette
    // gradient sits behind it and scrolls with the page naturally.
    final headerSliver = SliverToBoxAdapter(
      child: hasPalette
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                // Gradient panel extends upward behind the AppBar area
                Positioned(
                  top: -appBarHeight,
                  left: 0,
                  right: 0,
                  height: appBarHeight + PaletteTheme.headerGradientContentHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: PaletteTheme.headerGradient(widget.paletteColor!),
                    ),
                  ),
                ),
                widget.headerExpandedChild!,
              ],
            )
          : widget.headerExpandedChild!,
    );

    return [
      if (hasPalette)
        SliverToBoxAdapter(child: SizedBox(height: appBarHeight)),
      headerSliver,
      SliverToBoxAdapter(
        child: SizedBox(
          key: _actionRowKey,
          height: widget.actionRowHeight,
          child: widget.actionRow,
        ),
      ),
      if (widget.pills != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.md,
              bottom: AppSpacing.xl,
            ),
            child: widget.pills,
          ),
        )
      else
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
      if (widget.searchField != null) ...[
        SliverToBoxAdapter(child: widget.searchField!),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
      ],
      ...widget.bodySlivers,
    ];
  }
}

class _DockingPlayButton extends StatefulWidget {
  const _DockingPlayButton({
    required this.scrollController,
    required this.appBarHeight,
    required this.actionRowKey,
    required this.child,
  });

  final ScrollController scrollController;
  final double appBarHeight;
  final GlobalKey actionRowKey;
  final Widget child;

  @override
  State<_DockingPlayButton> createState() => _DockingPlayButtonState();
}

class _DockingPlayButtonState extends State<_DockingPlayButton> {
  static const double _rightPadding = 16.0;
  static const double _btnSize = 56.0;

  final ValueNotifier<double> _topNotifier = ValueNotifier(9999.0);
  double? _contentCenterY;
  double _dockedCenterY = 0.0;

  @override
  void initState() {
    super.initState();
    _dockedCenterY = widget.appBarHeight;
    _topNotifier.value = (widget.appBarHeight + 320.0) - _btnSize / 2;
    widget.scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final ctx = widget.actionRowKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final screenTop = box.localToGlobal(Offset.zero).dy;
    final scroll = widget.scrollController.hasClients
        ? widget.scrollController.offset
        : 0.0;
    _contentCenterY = screenTop + scroll + box.size.height / 2;
    _updatePosition(scroll);
  }

  void _updatePosition(double scroll) {
    final contentCenter = _contentCenterY ?? (widget.appBarHeight + 320.0);
    final rawCenterY = contentCenter - scroll;
    final clampedCenterY = rawCenterY.clamp(_dockedCenterY, double.infinity);
    _topNotifier.value = clampedCenterY - _btnSize / 2;
  }

  void _onScroll() {
    if (!mounted) return;
    final scroll = widget.scrollController.offset;
    if (_contentCenterY == null) _measure();
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

/// Expanded header content — cover art, title, subtitle.
class CollectionDetailExpandedContent extends StatelessWidget {
  const CollectionDetailExpandedContent({
    super.key,
    required this.cover,
    required this.title,
    this.subtitle,
  });

  final Widget cover;
  final String title;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cover,
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppFontSize.h2,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            subtitle!,
          ],
        ],
      ),
    );
  }
}

/// Column label row above the track list.
class CollectionTrackListHeader extends StatelessWidget {
  const CollectionTrackListHeader({
    super.key,
    this.showDurationColumn = false,
  });

  final bool showDurationColumn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const SizedBox(width: 40),
          const Expanded(
            child: Text(
              'Title',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: AppFontSize.sm,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (showDurationColumn)
            const Text(
              'Duration',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: AppFontSize.sm,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
