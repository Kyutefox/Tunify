import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/features/home/presentation/screens/home_screen.dart';

/// Root shell when a session exists (token + profile). Keeps the same scaffold contract as post-login navigation.
class AuthenticatedAppShell extends StatelessWidget {
  const AuthenticatedAppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.nearBlack,
      body: HomeScreen(),
    );
  }
}
