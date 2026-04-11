/// Returns a copy of [list] with duplicate items removed, preserving first-occurrence order.
///
/// Identity is determined by the [id] function, which must return a stable string
/// key for each element. The first occurrence of each key is retained.
List<T> uniqueById<T>(List<T> list, String Function(T) id) {
  final seen = <String>{};
  final unique = <T>[];
  for (final item in list) {
    if (seen.add(id(item))) unique.add(item);
  }
  return unique;
}
