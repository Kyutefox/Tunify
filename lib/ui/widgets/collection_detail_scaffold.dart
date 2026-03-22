import 'package:flutter/material.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/widgets/items/mini_player.dart';
import 'package:tunify/ui/widgets/button.dart';

/// Height of the pinned action row (play/shuffle etc).
const double kCollectionActionRowHeight = 56;

/// Height of the pinned search row when present.
const double kCollectionSearchRowHeight = 56;

/// Scroll offset past which the collection title is shown in the app bar.
const double kCollectionShowTitleThreshold = 180;

/// Reusable scaffold for collection-style detail pages (playlist, liked songs,
/// artist, album). Single scroll: cover, title and subtitle scroll together;
/// when the title scrolls under the app bar, the title appears next to the
/// back icon. The action row scrolls up then pins below the app bar; the list
/// scrolls under it.
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
  });

  final bool isEmpty;
  final Widget emptyChild;
  final List<Widget> bodySlivers;
  final bool hasSong;
  final Key? miniPlayerKey;

  /// Shown in app bar only when user has scrolled (title has gone under).
  final String? title;
  final Widget? headerExpandedChild;
  final Widget? actionRow;
  final double actionRowHeight;
  final Widget? pills;
  final Widget? searchField;

  /// Legacy: single header sliver when [title] / [actionRow] are not used.
  final Widget? headerSliver;

  @override
  State<CollectionDetailScaffold> createState() =>
      _CollectionDetailScaffoldState();
}

class _CollectionDetailScaffoldState extends State<CollectionDetailScaffold> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _showTitleInAppBar = ValueNotifier(false);

  bool get _useNewLayout =>
      widget.title != null &&
      widget.headerExpandedChild != null &&
      widget.actionRow != null;

  @override
  void initState() {
    super.initState();
    if (_useNewLayout) {
      _scrollController.addListener(_onScroll);
    }
  }

  void _onScroll() {
    final show = _scrollController.offset > kCollectionShowTitleThreshold;
    if (show != _showTitleInAppBar.value) {
      _showTitleInAppBar.value = show;
    }
  }

  @override
  void dispose() {
    if (_useNewLayout) {
      _scrollController.removeListener(_onScroll);
    }
    _scrollController.dispose();
    _showTitleInAppBar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _useNewLayout
          ? AppBar(
              backgroundColor: AppColors.background,
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
              title: ValueListenableBuilder<bool>(
                valueListenable: _showTitleInAppBar,
                builder: (_, show, __) => show
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
            )
          : AppBar(
              backgroundColor: AppColors.background,
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
                  ? _buildNewLayoutSlivers()
                  : [widget.headerSliver!, ...widget.bodySlivers],
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
    );
  }

  List<Widget> _buildNewLayoutSlivers() {
    return [
      SliverToBoxAdapter(
        child: widget.headerExpandedChild,
      ),
      SliverPersistentHeader(
        pinned: true,
        delegate: _StickyActionRowDelegate(
          height: widget.actionRowHeight,
          child: Container(
            color: AppColors.background,
            alignment: Alignment.centerLeft,
            child: widget.actionRow,
          ),
        ),
      ),
      if (widget.pills != null) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.md,
              bottom: AppSpacing.xl,
            ),
            child: widget.pills,
          ),
        ),
      ] else
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
      if (widget.searchField != null)
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyActionRowDelegate(
            height: kCollectionSearchRowHeight,
            child: Container(
              color: AppColors.background,
              alignment: Alignment.centerLeft,
              child: widget.searchField!,
            ),
          ),
        ),
      if (widget.searchField != null)
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
      ...widget.bodySlivers,
    ];
  }
}

class _StickyActionRowDelegate extends SliverPersistentHeaderDelegate {
  _StickyActionRowDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: height, child: child);
  }

  @override
  bool shouldRebuild(covariant _StickyActionRowDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}

/// Expanded (top) section for collection detail: cover, title, subtitle.
/// Use as [CollectionDetailScaffold.headerExpandedChild]. Scrolls with the list
/// until the action row pins.
class CollectionDetailExpandedContent extends StatelessWidget {
  const CollectionDetailExpandedContent({
    super.key,
    required this.cover,
    required this.title,
    required this.subtitle,
  });

  final Widget cover;
  final String title;
  final Widget subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        cover,
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppFontSize.display3,
              fontWeight: FontWeight.w800,
              letterSpacing: AppLetterSpacing.display,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: subtitle,
        ),
      ],
    );
  }
}

/// Standard header block for collection detail pages when not using the
/// new layout. Use as [CollectionDetailScaffold.headerSliver].
class CollectionDetailHeader extends StatelessWidget {
  const CollectionDetailHeader({
    super.key,
    required this.cover,
    required this.title,
    required this.subtitle,
    required this.actionRow,
    this.pills,
    this.searchField,
  });

  final Widget cover;
  final String title;
  final Widget subtitle;
  final Widget actionRow;
  final Widget? pills;
  final Widget? searchField;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cover,
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppFontSize.display3,
                fontWeight: FontWeight.w800,
                letterSpacing: AppLetterSpacing.display,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: subtitle,
          ),
          const SizedBox(height: AppSpacing.lg),
          actionRow,
          if (pills != null) ...[
            const SizedBox(height: AppSpacing.md),
            pills!,
            const SizedBox(height: AppSpacing.xl),
          ] else ...[
            const SizedBox(height: AppSpacing.xl),
          ],
          if (searchField != null) ...[
            searchField!,
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

/// Standard track list header row (# TITLE etc). Use in body slivers for
/// consistent styling.
class CollectionTrackListHeader extends StatelessWidget {
  const CollectionTrackListHeader({
    super.key,
    this.showDurationColumn = true,
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
          SizedBox(
            width: 24,
            child: Text(
              '#',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.9),
                fontSize: AppFontSize.sm,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const SizedBox(width: 48),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'TITLE',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.9),
                fontSize: AppFontSize.sm,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (showDurationColumn) ...[
            const SizedBox(width: 48),
            const SizedBox(width: 40),
          ],
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}
