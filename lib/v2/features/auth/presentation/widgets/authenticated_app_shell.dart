import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/widgets/navigation/tunify_bottom_nav_bar.dart';
import 'package:tunify/v2/features/home/presentation/screens/home_screen.dart';
import 'package:tunify/v2/features/library/presentation/screens/library_screen.dart';
import 'package:tunify/v2/features/search/presentation/screens/search_screen.dart';

/// Root shell when a session exists (token + profile).
class AuthenticatedAppShell extends ConsumerWidget {
  const AuthenticatedAppShell({super.key});

  static const _pages = <Widget>[
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(_shellTabIndexProvider);
    return Scaffold(
      backgroundColor: AppColors.nearBlack,
      body: IndexedStack(
        index: currentIndex,
        children: _pages,
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
