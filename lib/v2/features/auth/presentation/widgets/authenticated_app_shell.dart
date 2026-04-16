import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/widgets/navigation/tunify_bottom_nav_bar.dart';
import 'package:tunify/v2/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:tunify/v2/features/home/presentation/screens/home_screen.dart';
import 'package:tunify/v2/features/home/presentation/providers/home_providers.dart';
import 'package:tunify/v2/features/library/presentation/screens/library_screen.dart';
import 'package:tunify/v2/features/loading/presentation/screens/loading_screen.dart';
import 'package:tunify/v2/features/search/presentation/screens/search_screen.dart';

/// Root shell when a session exists (token + profile).
class AuthenticatedAppShell extends ConsumerStatefulWidget {
  const AuthenticatedAppShell({super.key});

  static const _pages = <Widget>[
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
  ];

  @override
  ConsumerState<AuthenticatedAppShell> createState() =>
      _AuthenticatedAppShellState();
}

class _AuthenticatedAppShellState extends ConsumerState<AuthenticatedAppShell> {
  @override
  Widget build(BuildContext context) {
    ref.listen(homeFeedProvider, (previous, next) {
      final isBootstrap = ref.read(postLoginBootstrapProvider);
      if (!isBootstrap) {
        return;
      }
      if (next.hasValue || next.hasError) {
        ref.read(postLoginBootstrapProvider.notifier).disable();
      }
    });

    final isPostLoginBootstrap = ref.watch(postLoginBootstrapProvider);
    if (isPostLoginBootstrap) {
      final homeFeed = ref.watch(homeFeedProvider);
      if (homeFeed.isLoading) {
        return const LoadingScreen();
      }
    }

    final currentIndex = ref.watch(_shellTabIndexProvider);
    return Scaffold(
      backgroundColor: AppColors.nearBlack,
      body: IndexedStack(
        index: currentIndex,
        children: AuthenticatedAppShell._pages,
      ),
      bottomNavigationBar: TunifyBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) =>
            ref.read(_shellTabIndexProvider.notifier).setIndex(index),
      ),
    );
  }
}

final _shellTabIndexProvider =
    NotifierProvider<_ShellTabIndexNotifier, int>(_ShellTabIndexNotifier.new);

class _ShellTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}
