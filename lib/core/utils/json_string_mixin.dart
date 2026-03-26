import 'dart:convert';

/// Parses a JSON string into [T], returning null when [s] is null, empty,
/// or malformed. Centralises the null/empty guard and try-catch that every
/// model's `fromJsonString` factory needs.
T? parseJsonString<T>(String? s, T Function(Map<String, dynamic>) fromJson) {
  if (s == null || s.isEmpty) return null;
  try {
    return fromJson(jsonDecode(s) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}
