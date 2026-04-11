import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/theme/app_theme.dart';
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
      theme: AppTheme.darkTheme,
      home: const WelcomeScreen(),
    );
  }
}
