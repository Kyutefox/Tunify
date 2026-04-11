import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';

/// Tunify text styles per DESIGN.md
class AppTextStyles {
  AppTextStyles._();

  // Section Title: 24px/700
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    height: 1.0,
  );

  // Feature Heading: 18px/600
  static const TextStyle featureHeading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    height: 1.30,
  );

  // Body Bold: 16px/700
  static const TextStyle bodyBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    height: 1.0,
  );

  // Body: 16px/400
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.white,
    height: 1.0,
  );

  // Caption: 14px/400
  static const TextStyle caption = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.silver,
    height: 1.0,
  );

  // Button Uppercase: 14px/600-700, uppercase, letter-spacing 1.4px-2px
  static const TextStyle buttonUppercase = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    height: 1.0,
    letterSpacing: 1.4,
  );

  // Button: 14px/700
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    height: 1.0,
    letterSpacing: 0.14,
  );

  // Nav Link Bold: 14px/700
  static const TextStyle navLinkBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    height: 1.0,
  );

  // Nav Link: 14px/400
  static const TextStyle navLink = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.silver,
    height: 1.0,
  );

  // Caption Bold: 14px/700
  static const TextStyle captionBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    height: 1.54,
  );

  // Small Bold: 12px/700
  static const TextStyle smallBold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    height: 1.50,
  );

  // Small: 12px/400
  static const TextStyle small = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.silver,
    height: 1.0,
  );

  // Badge: 10.5px/600, capitalize
  static const TextStyle badge = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    height: 1.33,
  );

  // Micro: 10px/400
  static const TextStyle micro = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.silver,
    height: 1.0,
  );
}
