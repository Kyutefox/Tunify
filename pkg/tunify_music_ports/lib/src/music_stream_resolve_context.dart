/// Per-request hints for YouTube Music stream resolution (session, platform prefs).
class MusicStreamResolveContext {
  const MusicStreamResolveContext({
    this.visitorData,
    this.preferAac = false,
  });

  /// YouTube VISITOR_DATA for personalized InnerTube requests.
  final String? visitorData;

  /// Prefer AAC when multiple formats are available (e.g. on Apple platforms).
  final bool preferAac;
}
