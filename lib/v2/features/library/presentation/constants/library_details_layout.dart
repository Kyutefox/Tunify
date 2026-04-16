import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';

/// Layout, radii, and feature-local colors for library collection detail screens.
abstract final class LibraryDetailsLayout {
  LibraryDetailsLayout._();

  /// Vertical gap below search before hero/title (static system playlists).
  static const double staticSearchToTitleGap = AppSpacing.xxxl + AppSpacing.md;

  /// Vertical gap below search before hero (standard playlist / album).
  static const double defaultSearchToHeroGap = AppSpacing.xl;

  static const double searchBarHeight = 42;
  static const double searchBarCornerRadius = 8;
  static const double searchHintFontSize = 15;
  static const double searchLeadingIconSize = 20;

  /// Search field tint (library header gradient family).
  static const Color searchFieldTone = Color(0xFF6D8AA9);
  static const double searchFieldFillOpacity = 0.35;

  static Color get searchFieldFill =>
      searchFieldTone.withValues(alpha: searchFieldFillOpacity);

  static const double heroCoverSize = 260;
  static const double heroCoverCornerRadius = 8;
  static const double heroCoverShadowBlur = 20;
  static const double heroCoverShadowOffsetY = 10;
  static const Color heroCoverShadowColor = Color(0x66000000);

  static const double artistHeroHeight = 360;
  static const double artistNameFontSize = 27;

  static const double backButtonIconSize = 28;

  static const double ownerAvatarRadius = 14;
  static const double ownerAvatarIconSize = 14;
  static const double metaGlobeIconSize = 14;

  static const double shuffleIconSize = 30;
  static const double playButtonDiameter = 64;
  static const double playButtonIconSize = 30;

  static const double chipPillHeight = 38;
  static const double chipIconSize = 18;
  static const double chipLabelFontSize = 9.5;

  static const double addRowLeadingSize = 56;
  static const double addRowPlusIconSize = 36;

  static const double trackRowArtSize = 58;
  static const double trackTitleFontSize = 19;
  static const double trackTitleSubtitleGap = 2;
  static const double trackMoreIconSize = 20;

  static const double miniCoverDefaultSize = 34;
  static const double miniCoverCornerRadius = 4;

  static const double circleActionSize = 30;
  static const double circleActionIconSize = 18;

  static const double toolbarActionIconSize = 22;

  static const double bodyGradientNearBlackStopAlpha = 0.98;

  static const double scrollBottomExtraPadding = 12;
}
