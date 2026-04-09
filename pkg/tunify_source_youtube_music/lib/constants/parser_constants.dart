/// Defaults and limits used by parsers and formatters.
class ParserConstants {
  ParserConstants._();

  /// Fallback duration to use when a track does not expose an explicit
  /// duration value in the source payload.
  static const Duration defaultTrackDuration = Duration.zero;
}
