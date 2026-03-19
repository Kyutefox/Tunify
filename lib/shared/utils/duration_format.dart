/// Shared duration formatting for display (e.g. "03:45" or "1:02:30").
extension DurationFormat on Duration {
  /// Returns duration as "MM:SS" or "H:MM:SS" when >= 1 hour.
  String get formattedMmSS {
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    if (inHours > 0) {
      return '$inHours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
