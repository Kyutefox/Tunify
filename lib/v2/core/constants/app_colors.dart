import 'package:flutter/material.dart';

/// Tunify color palette
class AppColors {
  AppColors._();

  // Primary Brand
  static const Color brandGreen = Color(0xFF1ed760);
  static const Color nearBlack = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF181818);
  static const Color midDark = Color(0xFF1f1f1f);

  // Text
  static const Color white = Color(0xFFFFFFFF);
  static const Color silver = Color(0xFFb3b3b3);
  static const Color nearWhite = Color(0xFFcbcbcb);
  static const Color light = Color(0xFFfdfdfd);

  // Semantic
  static const Color negativeRed = Color(0xFFf3727f);
  static const Color warningOrange = Color(0xFFffa42b);
  static const Color announcementBlue = Color(0xFF539df5);

  // Surface & Border
  static const Color darkCard = Color(0xFF252525);
  static const Color midCard = Color(0xFF272727);
  static const Color borderGray = Color(0xFF4d4d4d);
  static const Color lightBorder = Color(0xFF7c7c7c);
  static const Color separator = Color(0xFFb3b3b3);
  static const Color lightSurface = Color(0xFFeeeeee);
  static const Color brandGreenBorder = Color(0xFF1db954);

  /// Library filter pills (Figma “Menu - Library” chips).
  static const Color filterPillInactive = Color(0xFF313131);
  static const Color filterPillActive = Color(0xFF1ED760);
  static const Color filterPillDoubleSecond = Color(0xFF1BBB57);
  static const Color filterPillCloseSurface = Color(0xFF292929);
  static const Color filterPillDoubleSecondFg = Color(0xFF313131);

  /// 10% white separator used in menu panels and dividers.
  static const Color separator10 = Color.fromRGBO(255, 255, 255, 0.1);
}
