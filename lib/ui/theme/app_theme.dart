import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'design_tokens.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryContainer,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryLight,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        outline: AppColors.glassBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      textTheme: GoogleFonts.interTextTheme(const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 48,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
          height: 1.1,
        ),
        displayMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.0,
          height: 1.15,
        ),
        displaySmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        headlineSmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      )),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 24);
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.surfaceHighlight,
        thumbColor: AppColors.textPrimary,
        overlayColor: AppColors.glassWhite,
        trackHeight: 3.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.glassBorder,
        thickness: 0.5,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.accentRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.accentRed),
        ),
        errorStyle: const TextStyle(color: AppColors.accentRed, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
      ),
    );
  }
}
