import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/ui/screens/shared/home/home_content.dart';

/// Mobile-compatible home screen placeholder.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HomeContent(
      onPlay: (song) => ref.read(playerProvider.notifier).playSong(song),
    );
  }
}
