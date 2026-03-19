/// A single line of lyrics with an optional sync timestamp.
///
/// [startTime] is null for non-synced lyrics sources.
class LyricsLine {
  final String text;
  final Duration? startTime;

  const LyricsLine({required this.text, this.startTime});
}

/// Full lyrics payload for a track, optionally with per-line timestamps for sync scrolling.
class LyricsResult {
  final String fullText;
  final List<LyricsLine> lines;
  final String? source;
  final bool isSynced;

  const LyricsResult({
    required this.fullText,
    required this.lines,
    this.source,
    this.isSynced = false,
  });

  static const empty = LyricsResult(fullText: '', lines: [], source: null);
  bool get isEmpty => lines.isEmpty && fullText.isEmpty;
}
