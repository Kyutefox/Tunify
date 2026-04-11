import 'package:flutter/material.dart';

/// Placeholder artwork as a gradient from ARGB ints until real assets load.
abstract final class MockArtGradient {
  MockArtGradient._();

  static LinearGradient linearCover(List<int> argbInts) {
    final colors = argbInts.map(Color.new).toList();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors.length >= 2 ? colors : [colors.first, colors.first],
    );
  }
}
