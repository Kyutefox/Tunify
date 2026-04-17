import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_details_layout.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_details/library_collection_scroll_docking.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_details/library_detail_dock_action_widgets.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_details/library_detail_mini_cover.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_details/library_details_scroll_view.dart';

/// v1-style collection detail: pinned app bar title fade, docked toolbar + play over scroll.
/// Reusable for all detail types: playlist, static playlist, album, artist.
class LibraryDetailsScrollShell extends StatefulWidget {
  const LibraryDetailsScrollShell({
    super.key,
    required this.details,
    required this.bottomInset,
    required this.gradientColors,
  });

  final LibraryDetailsModel details;
  final double bottomInset;
  final List<Color> gradientColors;

  @override
  State<LibraryDetailsScrollShell> createState() =>
      _LibraryDetailsScrollShellState();
}

class _LibraryDetailsScrollShellState
    extends State<LibraryDetailsScrollShell>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _titleKey = GlobalKey();
  final GlobalKey _actionRowKey = GlobalKey();
  final ValueNotifier<double> _appBarOpacity = ValueNotifier(0);
  double _titleHideOffset = 320;
  bool _titleOffsetMeasured = false;
  static const double _fadeBandPx = 40;

  // ── Search mode ──
  bool _isSearchMode = false;
  late final AnimationController _searchAnimController;
  late final Animation<double> _searchAnim;
  final TextEditingController _searchTextController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ValueNotifier<String> _searchQuery = ValueNotifier('');

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _searchAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _searchAnim = CurvedAnimation(
      parent: _searchAnimController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _searchTextController.addListener(() {
      _searchQuery.value = _searchTextController.text;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTitleOffset());
  }

  void _enterSearchMode() {
    setState(() => _isSearchMode = true);
    _searchAnimController.forward();
    _searchFocusNode.requestFocus();
  }

  void _exitSearchMode() {
    _searchFocusNode.unfocus();
    _searchTextController.clear();
    _searchAnimController.reverse().then((_) {
      if (mounted) setState(() => _isSearchMode = false);
    });
  }

  void _measureTitleOffset() {
    if (_titleOffsetMeasured) {
      return;
    }
    final ctx = _titleKey.currentContext;
    if (ctx == null) {
      return;
    }
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = stackBox != null
        ? box.localToGlobal(Offset(0, box.size.height), ancestor: stackBox).dy
        : box.localToGlobal(Offset(0, box.size.height)).dy;
    final topPadding = MediaQuery.paddingOf(context).top;
    final appBarBottom = kToolbarHeight + topPadding;
    _titleHideOffset = origin - appBarBottom;
    _titleOffsetMeasured = true;
    _onScroll();
  }

  void _onScroll() {
    if (!_titleOffsetMeasured) {
      _measureTitleOffset();
    }
    final offset = _scrollController.offset;
    final fadeStart = _titleHideOffset - _fadeBandPx;
    _appBarOpacity.value =
        ((offset - fadeStart) / _fadeBandPx).clamp(0.0, 1.0).toDouble();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _appBarOpacity.dispose();
    _searchAnimController.dispose();
    _searchTextController.dispose();
    _searchFocusNode.dispose();
    _searchQuery.dispose();
    super.dispose();
  }

  Color _pinnedAppBarColor() {
    return Color.alphaBlend(
      widget.details.gradientTop.withValues(alpha: 0.42),
      AppColors.nearBlack,
    );
  }

  List<LibraryDetailsTrack> _filteredTracks(String query) {
    if (query.isEmpty) return widget.details.tracks;
    final q = query.toLowerCase();
    return widget.details.tracks
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.subtitle.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final appBarHeight = kToolbarHeight + topPad;
    final pinnedBg = _pinnedAppBarColor();
    final useDock = widget.details.tracks.isNotEmpty;

    return Stack(
      key: _stackKey,
      children: [
        Scaffold(
          backgroundColor: AppColors.nearBlack,
          extendBodyBehindAppBar: true,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: ValueListenableBuilder<double>(
              valueListenable: _appBarOpacity,
              builder: (_, opacity, child) => ColoredBox(
                color: pinnedBg.withValues(alpha: opacity.clamp(0.0, 1.0)),
                child: child,
              ),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.white,
                      size: 22,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                title: ValueListenableBuilder<double>(
                  valueListenable: _appBarOpacity,
                  builder: (_, opacity, __) => opacity >= 1.0
                      ? Text(
                          widget.details.title,
                          style: AppTextStyles.sectionTitle.copyWith(
                            fontSize: 17,
                            color: AppColors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      : const SizedBox.shrink(),
                ),
                centerTitle: true,
              ),
            ),
          ),
          body: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.translucent,
            child: LibraryDetailsScrollView(
              details: widget.details,
              bottomInset: widget.bottomInset,
              scrollController: _scrollController,
              titleMeasureKey: _titleKey,
              actionRowPlaceholderKey: _actionRowKey,
              appBarUnderlapHeight: appBarHeight,
              showInlineBackButton: false,
              headerScrollGradientColors:
                  widget.details.type == LibraryDetailsType.artist
                      ? const <Color>[]
                      : widget.gradientColors,
              onSearchTap: _enterSearchMode,
            ),
          ),
        ),
        if (useDock && !_isSearchMode) ...[
          LibraryCollectionDockingPlayButton(
            scrollController: _scrollController,
            appBarHeight: appBarHeight,
            actionRowMeasureKey: _actionRowKey,
            stackKey: _stackKey,
            buttonDiameter: LibraryDetailsLayout.playButtonDiameter,
            child: const LibraryDetailCollectionPlayButton(),
          ),
          LibraryCollectionDockingActionRow(
            scrollController: _scrollController,
            appBarHeight: appBarHeight,
            actionRowMeasureKey: _actionRowKey,
            stackKey: _stackKey,
            height: LibraryDetailsLayout.collectionDockedActionRowHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                0,
              ),
              child: widget.details.type == LibraryDetailsType.artist
                  ? LibraryArtistDockActionLeading(details: widget.details)
                  : LibraryPlaylistDockActionLeading(details: widget.details),
            ),
          ),
        ],
        // ── Search mode overlay ──
        if (_isSearchMode)
          PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _exitSearchMode();
            },
            child: AnimatedBuilder(
              animation: _searchAnim,
              builder: (context, _) {
                return FadeTransition(
                  opacity: _searchAnim,
                  child: _SearchModeOverlay(
                    animation: _searchAnim,
                    topPadding: topPad,
                    searchTextController: _searchTextController,
                    searchFocusNode: _searchFocusNode,
                    searchQuery: _searchQuery,
                    details: widget.details,
                    bottomInset: widget.bottomInset,
                    filteredTracks: _filteredTracks,
                    onBack: _exitSearchMode,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SearchModeOverlay extends StatelessWidget {
  const _SearchModeOverlay({
    required this.animation,
    required this.topPadding,
    required this.searchTextController,
    required this.searchFocusNode,
    required this.searchQuery,
    required this.details,
    required this.bottomInset,
    required this.filteredTracks,
    required this.onBack,
  });

  final Animation<double> animation;
  final double topPadding;
  final TextEditingController searchTextController;
  final FocusNode searchFocusNode;
  final ValueNotifier<String> searchQuery;
  final LibraryDetailsModel details;
  final double bottomInset;
  final List<LibraryDetailsTrack> Function(String) filteredTracks;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final pinnedBg = Color.alphaBlend(
      details.gradientTop.withValues(alpha: 0.42),
      AppColors.nearBlack,
    );

    return Material(
      color: AppColors.nearBlack,
      child: Column(
        children: [
          // Pinned search app bar — matches the scroll-pinned header style
          Container(
            color: pinnedBg,
            padding: EdgeInsets.only(top: topPadding),
            height: topPadding + kToolbarHeight,
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.white,
                        size: 22,
                      ),
                      onPressed: onBack,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    child: SizedBox(
                      height: LibraryDetailsLayout.searchBarHeight,
                      child: TextField(
                        controller: searchTextController,
                        focusNode: searchFocusNode,
                        style: AppTextStyles.smallBold.copyWith(
                          fontSize: LibraryDetailsLayout.searchHintFontSize,
                          color: AppColors.white,
                        ),
                        cursorColor: AppColors.white,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          hintText: details.searchHint,
                          hintStyle: AppTextStyles.smallBold.copyWith(
                            fontSize: LibraryDetailsLayout.searchHintFontSize,
                            color: AppColors.silver,
                          ),
                          filled: true,
                          fillColor: AppColors.midDark,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(
                              left: AppSpacing.md,
                              right: AppSpacing.sm,
                            ),
                            child: Icon(
                              Icons.search,
                              color: AppColors.white,
                              size: LibraryDetailsLayout.searchLeadingIconSize,
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              LibraryDetailsLayout.searchBarCornerRadius,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              LibraryDetailsLayout.searchBarCornerRadius,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              LibraryDetailsLayout.searchBarCornerRadius,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.fromLTRB(
                            0, 0, AppSpacing.md, 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Animated track list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                bottomInset +
                    LibraryDetailsLayout.scrollBottomExtraPadding,
              ),
              itemCount: details.tracks.length,
              itemBuilder: (context, index) {
                final track = details.tracks[index];
                final showThumbnail =
                    details.type != LibraryDetailsType.album;

                return _AnimatedTrackRow(
                  key: ValueKey(track.title + track.subtitle),
                  track: track,
                  searchQuery: searchQuery,
                  showThumbnail: showThumbnail,
                  item: details.item,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedTrackRow extends StatefulWidget {
  const _AnimatedTrackRow({
    super.key,
    required this.track,
    required this.searchQuery,
    required this.showThumbnail,
    required this.item,
  });

  final LibraryDetailsTrack track;
  final ValueNotifier<String> searchQuery;
  final bool showThumbnail;
  final LibraryItem item;

  @override
  State<_AnimatedTrackRow> createState() => _AnimatedTrackRowState();
}

class _AnimatedTrackRowState extends State<_AnimatedTrackRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final CurvedAnimation _curve;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1.0,
    );
    _curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    widget.searchQuery.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    widget.searchQuery.removeListener(_onQueryChanged);
    _curve.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final query = widget.searchQuery.value.toLowerCase();
    final matches = query.isEmpty ||
        widget.track.title.toLowerCase().contains(query) ||
        widget.track.subtitle.toLowerCase().contains(query);

    if (matches && !_visible) {
      _visible = true;
      _ctrl.forward();
    } else if (!matches && _visible) {
      _visible = false;
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _curve,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _curve,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.showThumbnail) ...[
                LibraryDetailMiniCover(
                  item: widget.item,
                  imageUrlOverride: widget.track.thumbUrl,
                  size: LibraryDetailsLayout.trackRowArtSize,
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.menuItemLabel,
                    ),
                    SizedBox(
                      height: LibraryDetailsLayout.trackTitleSubtitleGap,
                    ),
                    Text(
                      widget.track.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.silver,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppIcon(
                icon: AppIcons.moreVert,
                color: AppColors.silver,
                size: LibraryDetailsLayout.trackMoreIconSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
