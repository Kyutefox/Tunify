/// Centralized animation and timing constants for the app.
///
/// All duration values should be defined here to avoid hardcoded magic values
/// and ensure consistent timing across the application.
abstract final class AppDurations {
  AppDurations._();

  /// Standard animation duration for UI transitions (e.g., search mode, filter pills).
  static const Duration standardAnimation = Duration(milliseconds: 280);

  /// Debounce duration for search typing to avoid excessive API calls.
  static const Duration typingDebounce = Duration(milliseconds: 400);

  /// Rotation animation duration for animated borders.
  static const Duration rotationAnimation = Duration(milliseconds: 1200);

  /// Merge/fade animation duration for hero transitions.
  static const Duration mergeAnimation = Duration(milliseconds: 300);

  /// Fade-in animation duration for content appearing.
  static const Duration fadeIn = Duration(milliseconds: 150);
}
