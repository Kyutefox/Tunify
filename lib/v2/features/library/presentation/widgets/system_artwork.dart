import 'package:flutter/material.dart';
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
          child: Icon(
            config.icon,
            color: Colors.white,
            size: size * 0.42,
          ),
        ),
      ),
    );
  }

  static _SystemArtConfig _configFor(SystemArtworkType type) {
    return switch (type) {
      SystemArtworkType.likedSongs => const _SystemArtConfig(
          gradientColors: [
            Color(0xFF4A17C8),
            Color(0xFF8C8CE0),
          ],
          icon: Icons.favorite,
        ),
      SystemArtworkType.yourEpisodes => const _SystemArtConfig(
          gradientColors: [
            Color(0xFF056952),
            Color(0xFF1DB954),
          ],
          icon: Icons.bookmark,
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
  final IconData icon;
}
