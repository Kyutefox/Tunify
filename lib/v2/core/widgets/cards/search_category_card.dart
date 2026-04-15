import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';

/// Reusable category card used by Search genre/browse grids.
class SearchCategoryCard extends StatelessWidget {
  const SearchCategoryCard({
    super.key,
    required this.title,
    required this.backgroundColor,
    required this.padding,
    required this.titleFontSize,
  });

  final String title;
  final Color backgroundColor;
  final double padding;
  final double titleFontSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.comfortable),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyBold.copyWith(fontSize: titleFontSize),
          ),
        ),
      ),
    );
  }
}
