import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/theme/app_theme.dart';
import 'package:tunify/v2/features/loading/presentation/screens/loading_screen.dart';
import 'package:tunify/v2/features/welcome/presentation/screens/welcome_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: TunifyApp(),
    ),
  );
}

class TunifyApp extends StatelessWidget {
  const TunifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tunify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(
        // Ensure scaffold background is set to prevent glimpsing
        scaffoldBackgroundColor: AppColors.nearBlack,
      ),
      themeMode: ThemeMode.dark,
      home: const WelcomeScreen(),
      // Custom page transitions to prevent content glimpsing
      builder: (context, child) {
        return Container(
          color: AppColors.nearBlack,
          child: child,
        );
      },
    );
  }
}
