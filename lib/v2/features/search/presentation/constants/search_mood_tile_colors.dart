import 'dart:math';
import 'package:flutter/material.dart';

/// High-contrast Spotify-style mood card palette.
///
/// These are intentionally vivid + text-friendly for white labels.
const List<Color> searchMoodTilePalette = <Color>[
  Color(0xFFD82A95), // Music pink
  Color(0xFF056952), // Podcasts green-teal
  Color(0xFF8400E7), // Live events purple
  Color(0xFF233E8B), // Deep blue
  Color(0xFF5B8208), // Olive green
  Color(0xFF2D8E75), // Summer teal
  Color(0xFF5D2257), // Plum
  Color(0xFF4D87A6), // Steel blue
  Color(0xFF347FB4), // Mid blue
  Color(0xFF1E72D8), // Podcast charts blue
  Color(0xFF9E7CCC), // Lilac
  Color(0xFF688F08), // Video podcasts green
  Color(0xFFE12A9C), // Latin/Festival pink
  Color(0xFF5185A4), // Dance blue
  Color(0xFF007C68), // Rock green
  Color(0xFFEA1020), // Indie red
  Color(0xFFB0468F), // Mood magenta
  Color(0xFF5B216B), // Party purple
  Color(0xFFD91A9B), // Gaming pink
  Color(0xFFC17848), // Chill orange
];

/// Returns [count] card colors in randomized order with minimal visual repeats:
/// - No repeats within a palette-sized block.
/// - Avoids immediate color repetition across block boundaries.
List<Color> buildRandomizedMoodTileColors(int count, {required int seed}) {
  if (count <= 0) {
    return const <Color>[];
  }

  final colors = <Color>[];
  final blockSize = searchMoodTilePalette.length;
  final random = Random(seed);

  while (colors.length < count) {
    final block = List<Color>.from(searchMoodTilePalette);
    block.shuffle(random);

    if (colors.isNotEmpty && block.isNotEmpty && colors.last == block.first) {
      final swapIndex = block.length > 1 ? 1 : 0;
      final tmp = block.first;
      block[0] = block[swapIndex];
      block[swapIndex] = tmp;
    }

    final remaining = count - colors.length;
    colors.addAll(block.take(remaining < blockSize ? remaining : blockSize));
  }

  return colors;
}
