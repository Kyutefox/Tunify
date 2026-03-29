import 'package:flutter/material.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/shell/shell_context.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/desktop_tokens.dart';
import 'package:tunify/ui/widgets/player/mini_player.dart';
import 'package:tunify/ui/widgets/common/button.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

const double kCollectionActionRowHeight = 56;

class CollectionDetailScaffold extends StatefulWidget {
  const CollectionDetailScaffold({
    super.key,
    required this.isEmpty,
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
  final GlobalKey _titleKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();  // anchor for local coordinate conversion

  // Scroll offset at which the page title is exactly at the AppBar bottom.
  // Computed once after first layout; falls back to a safe default until then.
  double _titleHideOffset = 320.0;
  bool _titleOffsetMeasured = false;

  static const double _fadeDuration = 40.0; // px over which the fade happens

  bool get _useNewLayout =>
      widget.title != null &&
      widget.headerExpandedChild != null &&
      widget.actionRow != null;

  @override
  void initState() {
    super.initState();
    if (_useNewLayout) {
      _scrollController.addListener(_onScroll);
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureTitleOffset());
    }
  }

  void _measureTitleOffset() {
    if (_titleOffsetMeasured) return;
    final ctx = _titleKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = stackBox != null
        ? box.localToGlobal(Offset(0, box.size.height), ancestor: stackBox).dy
        : box.localToGlobal(Offset(0, box.size.height)).dy;
    final isDesktop = ShellContext.isDesktopOf(context);
    final topPadding = isDesktop ? 0.0 : MediaQuery.of(context).padding.top;
    final appBarBottom = kToolbarHeight + topPadding;
    _titleHideOffset = stackBox != null ? origin - appBarBottom : origin - appBarBottom;
    _titleOffsetMeasured = true;
    _onScroll();
  }

  void _onScroll() {
    if (!_titleOffsetMeasured) _measureTitleOffset();
    final offset = _scrollController.offset;
    final fadeStart = _titleHideOffset - _fadeDuration;
    final opacity = ((offset - fadeStart) / _fadeDuration).clamp(0.0, 1.0);
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
    final isDesktop = ShellContext.isDesktopOf(context);
    final topPadding = isDesktop ? 0.0 : MediaQuery.of(context).padding.top;
    final appBarHeight = kToolbarHeight + topPadding;
    final hasPalette = widget.paletteColor != null;
    final hasPlayButton = widget.playButton != null && _useNewLayout;

    final pinnedBg = hasPalette
        ? PaletteTheme.appBarBackground(widget.paletteColor!, background: AppColorsScheme.of(context).background)
        : AppColorsScheme.of(context).background;

    return Stack(
      key: _stackKey,
      children: [
        Scaffold(
          backgroundColor: AppColorsScheme.of(context).background,
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
                            color: AppColorsScheme.of(context).textPrimary,
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
                                style: TextStyle(
                                  color: AppColorsScheme.of(context).textPrimary,
                                  fontSize: AppFontSize.xxl,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              )
                            : const SizedBox.shrink(),
                      ),
                      centerTitle: true,
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
                        color: AppColorsScheme.of(context).textPrimary,
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
              cacheExtent: 1000,
              controller: _useNewLayout ? _scrollController : null,
              physics: const BouncingScrollPhysics(),
              slivers: _useNewLayout
                  ? _buildSlivers(appBarHeight, hasPalette)
                  : [
                      if (hasPalette)
                        SliverToBoxAdapter(child: SizedBox(height: appBarHeight)),
                      if (widget.headerSliver != null) widget.headerSliver!,
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
        if (hasPlayButton && !widget.isEmpty)
          _DockingPlayButton(
            scrollController: _scrollController,
            appBarHeight: appBarHeight,
            actionRowKey: _actionRowKey,
            stackKey: _stackKey,
            child: widget.playButton!,
          ),
        if (widget.actionRow != null && _useNewLayout && !widget.isEmpty)
          _DockingActionRow(
            scrollController: _scrollController,
            appBarHeight: appBarHeight,
            actionRowKey: _actionRowKey,
            stackKey: _stackKey,
            height: widget.actionRowHeight,
            child: widget.actionRow!,
          ),
      ],
    );
  }

  List<Widget> _buildSlivers(double appBarHeight, bool hasPalette) {
    final headerSliver = SliverToBoxAdapter(
      child: hasPalette
          ? Stack(
              clipBehavior: Clip.none,
              children: [
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
                _TitleKeyInjector(titleKey: _titleKey, child: widget.headerExpandedChild!),
              ],
            )
          : _TitleKeyInjector(titleKey: _titleKey, child: widget.headerExpandedChild!),
    );

    return [
      if (hasPalette)
        SliverToBoxAdapter(child: SizedBox(height: appBarHeight)),
      headerSliver,
      SliverToBoxAdapter(
        child: SizedBox(
          key: _actionRowKey,
          height: widget.actionRowHeight,
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
      if (widget.searchField != null && !widget.isEmpty) ...[
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
    required this.stackKey,
    required this.child,
  });

  final ScrollController scrollController;
  final double appBarHeight;
  final GlobalKey actionRowKey;
  final GlobalKey stackKey;
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
    final stackBox = widget.stackKey.currentContext?.findRenderObject() as RenderBox?;
    final screenTop = stackBox != null
        ? box.localToGlobal(Offset.zero, ancestor: stackBox).dy
        : box.localToGlobal(Offset.zero).dy;
    final scroll = widget.scrollController.hasClients ? widget.scrollController.offset : 0.0;
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

/// Mirrors [_DockingPlayButton] but for the action row — absolutely positioned
/// above the gradient so icons render crisp with no palette bleed.
class _DockingActionRow extends StatefulWidget {
  const _DockingActionRow({
    required this.scrollController,
    required this.appBarHeight,
    required this.actionRowKey,
    required this.stackKey,
    required this.height,
    required this.child,
  });

  final ScrollController scrollController;
  final double appBarHeight;
  final GlobalKey actionRowKey;
  final GlobalKey stackKey;
  final double height;
  final Widget child;

  @override
  State<_DockingActionRow> createState() => _DockingActionRowState();
}

class _DockingActionRowState extends State<_DockingActionRow> {
  final ValueNotifier<double> _topNotifier = ValueNotifier(-1.0);
  double? _contentTopY;

  @override
  void initState() {
    super.initState();
    _topNotifier.value = widget.appBarHeight + 320.0;
    widget.scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final ctx = widget.actionRowKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final stackBox = widget.stackKey.currentContext?.findRenderObject() as RenderBox?;
    final screenTop = stackBox != null
        ? box.localToGlobal(Offset.zero, ancestor: stackBox).dy
        : box.localToGlobal(Offset.zero).dy;
    final scroll = widget.scrollController.hasClients ? widget.scrollController.offset : 0.0;
    _contentTopY = screenTop + scroll;
    _updatePosition(scroll);
  }

  void _updatePosition(double scroll) {
    final contentTop = _contentTopY ?? (widget.appBarHeight + 320.0);
    final rawTop = contentTop - scroll;
    _topNotifier.value = rawTop;
  }

  void _onScroll() {
    if (!mounted) return;
    final scroll = widget.scrollController.offset;
    if (_contentTopY == null) _measure();
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
        // Not yet measured — render at estimated position
        if (top == -1.0) return const SizedBox.shrink();
        // Fully scrolled behind appbar — hide
        if (top + widget.height <= widget.appBarHeight) return const SizedBox.shrink();
        return Positioned(
          top: top,
          left: 0,
          right: 0,
          height: widget.height,
          child: ClipRect(
            clipper: _TopClipper(
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

/// Clips [clipTop] pixels from the top of a widget — used to slide the
/// action row under the appbar as it scrolls up.
class _TopClipper extends CustomClipper<Rect> {
  const _TopClipper({required this.clipTop});
  final double clipTop;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, clipTop, size.width, size.height - clipTop);

  @override
  bool shouldReclip(_TopClipper old) => old.clipTop != clipTop;
}

/// Injects [titleKey] into a [CollectionDetailExpandedContent] child.
/// If the child is not a [CollectionDetailExpandedContent], renders it unchanged.
class _TitleKeyInjector extends StatelessWidget {
  const _TitleKeyInjector({required this.titleKey, required this.child});
  final GlobalKey titleKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (child is CollectionDetailExpandedContent) {
      final c = child as CollectionDetailExpandedContent;
      return CollectionDetailExpandedContent(
        cover: c.cover,
        title: c.title,
        subtitle: c.subtitle,
        titleKey: titleKey,
      );
    }
    return child;
  }
}


class CollectionDetailExpandedContent extends StatelessWidget {
  const CollectionDetailExpandedContent({
    super.key,
    required this.cover,
    required this.title,
    this.subtitle,
    this.titleKey,
  });

  final Widget cover;
  final String title;
  final Widget? subtitle;
  final Key? titleKey;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: t.spacing.base,
        vertical: t.spacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cover,
          SizedBox(height: t.spacing.xl),
          Text(
            key: titleKey,
            title,
            style: TextStyle(
              color: AppColorsScheme.of(context).textPrimary,
              fontSize: t.font.h2,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: t.spacing.xs),
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
    final t = AppTokens.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: t.spacing.base,
        vertical: t.spacing.sm,
      ),
      child: Row(
        children: [
          const SizedBox(width: 40),
          Expanded(
            child: Text(
              'Title',
              style: TextStyle(
                color: AppColorsScheme.of(context).textMuted,
                fontSize: t.font.sm,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (showDurationColumn)
            Text(
              'Duration',
              style: TextStyle(
                color: AppColorsScheme.of(context).textMuted,
                fontSize: t.font.sm,
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
