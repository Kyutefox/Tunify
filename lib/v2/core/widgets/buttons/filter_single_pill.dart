import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/filter_pill_layout.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/core/widgets/buttons/filter_close_pill_button.dart';

/// Single library chip: inactive [#313131] / active [#1ED760] (Figma).
class FilterSinglePill extends StatelessWidget {
  const FilterSinglePill({
    super.key,
    required this.label,
    required this.selected,
    this.onPressed,
    this.showCloseControl = false,
    this.onClose,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final bool showCloseControl;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.filterPillActive : AppColors.filterPillInactive;
    final fg = selected ? AppColors.nearBlack : AppColors.white;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCloseControl) ...[
          FilterClosePillButton(onPressed: onClose),
          const SizedBox(width: FilterPillLayout.gapAfterClose),
        ],
        Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FilterPillLayout.cornerRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(FilterPillLayout.cornerRadius),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: FilterPillLayout.height),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FilterPillLayout.horizontalPadding,
                  vertical: FilterPillLayout.verticalPadding,
                ),
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.filterPillLabel.copyWith(color: fg),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
