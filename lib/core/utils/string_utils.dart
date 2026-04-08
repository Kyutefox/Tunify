/// Capitalizes the first character of a string, leaving the rest unchanged.
extension StringCapitalize on String {
  /// Returns this string with its first character uppercased.
  /// Returns the original string if it is empty.
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
