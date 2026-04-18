import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';

/// Fixed gradient + icon artwork for system library items
/// (Liked Songs, Your Episodes).
///
/// Liked Songs: purple-blue gradient with a white filled heart.
/// Your Episodes: green gradient with a white bookmark icon.
class SystemArtwork extends StatelessWidget {
  const SystemArtwork({
    super.key,
    required this.type,
    required this.size,
    this.borderRadius = 4,
  });

  final SystemArtworkType type;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final config = _configFor(type);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: config.gradientColors,
          ),
        ),
        child: Center(
          child: AppIcon(
            icon: config.icon,
            color: AppColors.white,
            size: size * 0.42,
          ),
        ),
      ),
    );
  }

  static _SystemArtConfig _configFor(SystemArtworkType type) {
    return switch (type) {
      SystemArtworkType.likedSongs => _SystemArtConfig(
          gradientColors: const [
            AppColors.likedSongsGradientStart,
            AppColors.likedSongsGradientEnd,
          ],
          icon: AppIcons.favorite,
        ),
      SystemArtworkType.yourEpisodes => _SystemArtConfig(
          gradientColors: const [
            AppColors.yourEpisodesGradientStart,
            AppColors.yourEpisodesGradientEnd,
          ],
          icon: AppIcons.bookmark,
        ),
    };
  }
}

/// Internal config holder for system artwork gradient + icon.
class _SystemArtConfig {
  const _SystemArtConfig({
    required this.gradientColors,
    required this.icon,
  });

  final List<Color> gradientColors;
  final List<List<dynamic>> icon;
}
