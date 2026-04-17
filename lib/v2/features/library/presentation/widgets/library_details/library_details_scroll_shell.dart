import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_details_layout.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_details/library_collection_scroll_docking.dart';
import 'package:tunify/v2/features/library/presentation/widgets/library_details/library_detail_dock_action_widgets.dart';
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
    extends State<LibraryDetailsScrollShell> {
  late final ScrollController _scrollController;
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _titleKey = GlobalKey();
  final GlobalKey _actionRowKey = GlobalKey();
  final ValueNotifier<double> _appBarOpacity = ValueNotifier(0);
  double _titleHideOffset = 320;
  bool _titleOffsetMeasured = false;
  static const double _fadeBandPx = 40;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTitleOffset());
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
    super.dispose();
  }

  Color _pinnedAppBarColor() {
    return Color.alphaBlend(
      widget.details.gradientTop.withValues(alpha: 0.42),
      AppColors.nearBlack,
    );
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
            ),
          ),
        ),
        if (useDock) ...[
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
      ],
    );
  }
}
