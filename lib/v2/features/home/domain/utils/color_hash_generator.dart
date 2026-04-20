/// Generates deterministic ARGB colors from a string hash.
///
/// Used for fallback colors when palette extraction is unavailable.
abstract final class ColorHashGenerator {
  ColorHashGenerator._();

  /// Generates two ARGB integer colors from a string input using a simple hash.
  ///
  /// The hash is deterministic - the same input always produces the same colors.
  static List<int> hashToTwoColors(String input) {
    var h = 0;
    for (final unit in input.codeUnits) {
      h = (h * 31 + unit) & 0x7fffffff;
    }
    final a = 0xFF000000 | (h & 0xffffff);
    final b = 0xFF000000 | ((h ^ (h >> 12) ^ (h >> 24)) & 0xffffff);
    return [a, b];
  }
}
