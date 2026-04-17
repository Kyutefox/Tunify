import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';

/// High-contrast Spotify-style mood card palette.
///
/// These are intentionally vivid + text-friendly for white labels.
const List<Color> searchMoodTilePalette = <Color>[
  AppColors.moodTilePink, // Music pink
  AppColors.moodTileGreenTeal, // Podcasts green-teal
  AppColors.moodTilePurple, // Live events purple
  AppColors.moodTileDeepBlue, // Deep blue
  AppColors.moodTileOlive, // Olive green
  AppColors.moodTileSummerTeal, // Summer teal
  AppColors.moodTilePlum, // Plum
  AppColors.moodTileSteelBlue, // Steel blue
  AppColors.moodTileMidBlue, // Mid blue
  AppColors.moodTileChartsBlue, // Podcast charts blue
  AppColors.moodTileLilac, // Lilac
  AppColors.moodTileVideoGreen, // Video podcasts green
  AppColors.moodTileLatinPink, // Latin/Festival pink
  AppColors.moodTileDanceBlue, // Dance blue
  AppColors.moodTileRockGreen, // Rock green
  AppColors.moodTileIndieRed, // Indie red
  AppColors.moodTileMagenta, // Mood magenta
  AppColors.moodTilePartyPurple, // Party purple
  AppColors.moodTileGamingPink, // Gaming pink
  AppColors.moodTileChillOrange, // Chill orange
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
