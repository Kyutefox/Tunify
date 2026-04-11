import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/filter_pill_layout.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/buttons/filter_close_pill_button.dart';

/// Fused two-segment library chip (Figma “Chip submenu”, −16px overlap).
///
/// Outer [ClipRRect] caps the whole control. The **primary** segment always uses
/// a full pill radius (including the **right** edge) whether or not the secondary
/// is revealed; the secondary sits under the overlap with rounding on the
/// **outer** right only.
///
/// [secondaryRevealed] false: only the primary segment is visible (full pill).
/// True: secondary is under the primary with [FilterPillLayout.segmentOverlap];
/// width is animated so the trailing segment emerges from the seam.
class FilterDoublePill extends StatelessWidget {
  const FilterDoublePill({
    super.key,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.primarySelected,
    required this.secondarySelected,
    required this.secondaryRevealed,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.showCloseControl = false,
    this.onClose,
    this.expandDuration = const Duration(milliseconds: 280),
    this.expandCurve = Curves.easeOutCubic,
  });

  final String primaryLabel;
  final String secondaryLabel;
  final bool primarySelected;
  final bool secondarySelected;
  final bool secondaryRevealed;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final bool showCloseControl;
  final VoidCallback? onClose;
  final Duration expandDuration;
  final Curve expandCurve;

  static double _segmentWidth(
    BuildContext context,
    String label, {
    double extraLeftPadding = 0,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: AppTextStyles.filterPillLabel),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return painter.width +
        FilterPillLayout.horizontalPadding * 2 +
        extraLeftPadding;
  }

  @override
  Widget build(BuildContext context) {
    final r = FilterPillLayout.cornerRadius;
    final o = FilterPillLayout.segmentOverlap;
    final h = FilterPillLayout.height;
    final w1 = _segmentWidth(context, primaryLabel);
    final w2 = _segmentWidth(
      context,
      secondaryLabel,
      extraLeftPadding: FilterPillLayout.secondaryLeadingInset,
    );
    final totalWidth = w1 + w2 - o;
    final clipWidth = secondaryRevealed ? totalWidth : w1;

    final primaryBg = primarySelected
        ? AppColors.filterPillActive
        : AppColors.filterPillInactive;
    final primaryFg =
        primarySelected ? AppColors.nearBlack : AppColors.white;
    final secondaryBg = secondarySelected
        ? AppColors.filterPillDoubleSecond
        : AppColors.filterPillInactive;
    final secondaryFg = secondarySelected
        ? AppColors.filterPillDoubleSecondFg
        : AppColors.white;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCloseControl) ...[
          FilterClosePillButton(onPressed: onClose),
          const SizedBox(width: FilterPillLayout.gapAfterClose),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(r),
          clipBehavior: Clip.antiAlias,
          child: AnimatedContainer(
            duration: expandDuration,
            curve: expandCurve,
            width: clipWidth,
            height: h,
            child: secondaryRevealed
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: totalWidth,
                      height: h,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: w1 - o,
                            top: 0,
                            width: w2,
                            height: h,
                            child: IgnorePointer(
                              ignoring: !secondaryRevealed,
                              child: _FlatInkSegment(
                                background: secondaryBg,
                                foreground: secondaryFg,
                                label: secondaryLabel,
                                onTap: onSecondaryPressed,
                                extraLeftPadding:
                                    FilterPillLayout.secondaryLeadingInset,
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(r),
                                  bottomRight: Radius.circular(r),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: 0,
                            width: w1,
                            height: h,
                            child: _FlatInkSegment(
                              background: primaryBg,
                              foreground: primaryFg,
                              label: primaryLabel,
                              onTap: onPrimaryPressed,
                              borderRadius: BorderRadius.circular(r),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _FlatInkSegment(
                    background: primaryBg,
                    foreground: primaryFg,
                    label: primaryLabel,
                    onTap: onPrimaryPressed,
                    minWidth: w1,
                    borderRadius: BorderRadius.circular(r),
                  ),
          ),
        ),
      ],
    );
  }
}

class _FlatInkSegment extends StatelessWidget {
  const _FlatInkSegment({
    required this.background,
    required this.foreground,
    required this.label,
    this.onTap,
    this.extraLeftPadding = 0,
    this.minWidth,
    this.borderRadius,
  });

  final Color background;
  final Color foreground;
  final String label;
  final VoidCallback? onTap;
  final double extraLeftPadding;
  final double? minWidth;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final shape = borderRadius != null
        ? RoundedRectangleBorder(borderRadius: borderRadius!)
        : null;

    return Material(
      color: background,
      shape: shape,
      clipBehavior: borderRadius != null ? Clip.antiAlias : Clip.none,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: FilterPillLayout.height,
            minWidth: minWidth ?? 0,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              FilterPillLayout.horizontalPadding + extraLeftPadding,
              FilterPillLayout.verticalPadding,
              FilterPillLayout.horizontalPadding,
              FilterPillLayout.verticalPadding,
            ),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.filterPillLabel.copyWith(color: foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
