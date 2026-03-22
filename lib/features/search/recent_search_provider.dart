import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:tunify/data/repositories/database_repository.dart';

/// Manages the capped list of recent search queries, persisted to [DatabaseRepository].
///
/// The list is capped at [_maxRecent] entries; adding a duplicate query moves it to the front.
class RecentSearchNotifier extends StateNotifier<List<String>> {
  RecentSearchNotifier(this._ref) : super([]) {
    load();
  }

  final Ref _ref;

  static const int _maxRecent = 20;

  Future<void> load() async {
    state = await _ref.read(databaseRepositoryProvider).loadRecentSearches();
  }

  Future<void> save() async {
    await _ref.read(databaseRepositoryProvider).saveRecentSearches(state);
  }

  Future<void> addQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final next = [trimmed, ...state.where((q) => q != trimmed)].take(_maxRecent).toList();
    state = next;
    await save();
  }

  Future<void> clearAll() async {
    state = [];
    await save();
  }

  Future<void> onAuthChanged() async => load();
}

final recentSearchProvider =
    StateNotifierProvider<RecentSearchNotifier, List<String>>((ref) {
  return RecentSearchNotifier(ref);
});
