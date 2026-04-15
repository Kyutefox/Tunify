import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_border_radius.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';

/// Reusable compact tile used in Search's horizontal explore rail.
class SearchExploreCard extends StatelessWidget {
  const SearchExploreCard({
    super.key,
    required this.title,
    required this.backgroundColor,
    required this.width,
    required this.padding,
    required this.titleFontSize,
  });

  final String title;
  final Color backgroundColor;
  final double width;
  final double padding;
  final double titleFontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.comfortable),
      ),
      padding: EdgeInsets.all(padding),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyBold.copyWith(fontSize: titleFontSize),
        ),
      ),
    );
  }
}
