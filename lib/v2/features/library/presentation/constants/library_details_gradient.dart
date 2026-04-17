import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_details_layout.dart';

/// Scaffold / scroll gradient stops for a loaded [LibraryDetailsModel].
List<Color> libraryDetailBackgroundGradientColors(LibraryDetailsModel details) {
  final fade = AppColors.nearBlack.withValues(
    alpha: LibraryDetailsLayout.bodyGradientNearBlackStopAlpha,
  );
  final mid = details.backgroundGradientMid;
  if (mid != null) {
    return [
      details.gradientTop,
      mid,
      fade,
      AppColors.nearBlack,
    ];
  }
  return [
    details.gradientTop,
    fade,
    AppColors.nearBlack,
  ];
}
