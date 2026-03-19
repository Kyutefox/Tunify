import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/song.dart';
import '../../../shared/providers/home_state_provider.dart';
import '../../../shared/providers/player_state_provider.dart';
import '../../theme/app_colors.dart';
import 'home_app_bar.dart';
import 'home_content.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeProvider.notifier).loadContent();
    });
  }

  void _play(Song song) {
    ref.read(playerProvider.notifier).playSong(song);
  }

  @override
  Widget build(BuildContext context) {
    final greeting = ref.watch(greetingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeAppBar(greeting: greeting, asSliver: false),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(homeProvider.notifier).refresh();
              },
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              strokeWidth: 2.5,
              displacement: 80,
              child: CustomScrollView(
                cacheExtent: 500,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  HomeContent(onPlay: _play),
                  SliverToBoxAdapter(
                    child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
