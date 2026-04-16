import 'package:flutter/material.dart';

abstract final class NavigationLayout {
  NavigationLayout._();

  static const double barHeight = 64;
  static const double topBorderWidth = 0.5;
  static const double iconSize = 24;
  static const double labelFontSize = 11;
  static const double labelGap = 2;
  static const FontWeight selectedLabelWeight = FontWeight.w700;
  static const FontWeight unselectedLabelWeight = FontWeight.w500;
}
