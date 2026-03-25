import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'design_tokens.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.white.withValues(alpha: 0.06),
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
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          textStyle: AppTextStyle.screenTitle,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      // Poppins for display/headline/title roles; Inter for body/label roles.
      textTheme: TextTheme(
        displayLarge:  GoogleFonts.poppins(textStyle: AppTextStyle.display1),
        displayMedium: GoogleFonts.poppins(textStyle: AppTextStyle.display2),
        displaySmall:  GoogleFonts.poppins(textStyle: AppTextStyle.display3),
        headlineLarge: GoogleFonts.poppins(textStyle: AppTextStyle.h1),
        headlineMedium: GoogleFonts.poppins(textStyle: AppTextStyle.h3),
        headlineSmall: GoogleFonts.poppins(textStyle: AppTextStyle.screenTitle),
        titleLarge:  GoogleFonts.poppins(textStyle: AppTextStyle.titleBase),
        titleMedium: GoogleFonts.poppins(textStyle: AppTextStyle.titleLg),
        titleSmall:  GoogleFonts.inter(textStyle: AppTextStyle.labelLg),
        bodyLarge:   GoogleFonts.inter(textStyle: AppTextStyle.bodyLg),
        bodyMedium:  GoogleFonts.inter(textStyle: AppTextStyle.bodyBase),
        bodySmall:   GoogleFonts.inter(textStyle: AppTextStyle.caption),
        labelLarge:  GoogleFonts.inter(textStyle: AppTextStyle.labelLg),
        labelMedium: GoogleFonts.inter(textStyle: AppTextStyle.labelBase),
        labelSmall:  GoogleFonts.inter(textStyle: AppTextStyle.labelSm),
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: AppFontSize.xs,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            );
          }
          return GoogleFonts.inter(
            fontSize: AppFontSize.xs,
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
        errorStyle: GoogleFonts.inter(
          color: AppColors.accentRed,
          fontSize: AppFontSize.sm,
        ),
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
