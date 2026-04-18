part of 'library_item_options_sheet.dart';

class _SheetDragHandle extends StatelessWidget {
  const _SheetDragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: LibraryLayout.sheetHandleWidth,
      height: LibraryLayout.sheetHandleHeight,
      decoration: BoxDecoration(
        color: AppColors.silver.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(LibraryLayout.sheetHandleRadius),
      ),
    );
  }
}

class _SheetDivider extends StatelessWidget {
  const _SheetDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 0.5,
      thickness: 0.5,
      color: AppColors.separator10,
    );
  }
}

class _ItemHeader extends StatelessWidget {
  const _ItemHeader({required this.item});

  final LibraryItem item;

  @override
  Widget build(BuildContext context) {
    final isCircular = item.kind == LibraryItemKind.artist;
    final radius = isCircular
        ? LibraryLayout.sheetArtworkSize / 2
        : AppBorderRadius.subtle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          LibraryCollectionArtwork(
            item: item,
            size: LibraryLayout.sheetArtworkSize,
            borderRadius: radius,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyBold,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetCircleButton extends StatelessWidget {
  const _SheetCircleButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.busy = false,
    this.enabled = true,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback? onTap;
  final bool busy;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && onTap != null && !busy;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: canTap ? onTap : null,
        customBorder: const CircleBorder(),
        splashColor: AppColors.brandGreen.withValues(alpha: 0.12),
        highlightColor: AppColors.brandGreen.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: enabled ? 1 : 0.35,
                child: Container(
                  width: LibraryLayout.sheetQuickCircleSize,
                  height: LibraryLayout.sheetQuickCircleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.midDark,
                    border: Border.all(color: AppColors.separator10),
                  ),
                  child: Center(
                    child: busy
                        ? SizedBox(
                            width: LibraryLayout.sheetQuickProgressSize,
                            height: LibraryLayout.sheetQuickProgressSize,
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          )
                        : AppIcon(
                            icon: icon,
                            color: AppColors.silver,
                            size: LibraryLayout.sheetOptionIconSize,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.quickActionLabel.copyWith(
                  color: enabled ? AppColors.white : AppColors.silver,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            AppIcon(
              icon: icon,
              size: LibraryLayout.sheetOptionIconSize,
              color: AppColors.silver,
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionAction {
  const _OptionAction({
    required this.icon,
    required this.label,
    this.customTap,
  });

  final List<List<dynamic>> icon;
  final String label;

  /// When set, the options sheet does not auto-pop; the callback owns navigation.
  final void Function()? customTap;
}
