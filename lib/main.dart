import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/theme/app_theme.dart';
import 'package:tunify/v2/features/auth/presentation/providers/auth_providers.dart';
import 'package:tunify/v2/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:tunify/v2/features/auth/presentation/widgets/authenticated_app_shell.dart';
import 'package:tunify/v2/features/loading/presentation/screens/loading_screen.dart';
import 'package:tunify/v2/features/welcome/presentation/screens/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const TunifyApp(),
    ),
  );
}

class TunifyApp extends ConsumerWidget {
  const TunifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final sessionKey = session.when(
      loading: () => 'session-loading',
      error: (_, __) => 'session-guest',
      data: (user) => user == null ? 'session-guest' : 'session-auth-${user.id}',
    );

    return MaterialApp(
      key: ValueKey<String>(sessionKey),
      title: 'Tunify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(
        // Ensure scaffold background is set to prevent glimpsing
        scaffoldBackgroundColor: AppColors.nearBlack,
      ),
      themeMode: ThemeMode.dark,
      home: session.when(
        loading: () => const LoadingScreen(),
        error: (_, __) => const WelcomeScreen(),
        data: (user) => user != null
            ? const AuthenticatedAppShell()
            : const WelcomeScreen(),
      ),
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
