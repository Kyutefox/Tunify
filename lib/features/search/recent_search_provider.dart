import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/data/repositories/database_repository.dart';

/// Manages the capped list of recent search queries, persisted to [DatabaseRepository].
///
/// The list is capped at [_maxRecent] entries; adding a duplicate query moves it to the front.
class RecentSearchNotifier extends Notifier<List<String>> {
  static const int _maxRecent = 20;

  @override
  List<String> build() {
    load();
    return [];
  }

  Future<void> load() async {
    state = await ref.read(databaseRepositoryProvider).loadRecentSearches();
  }

  Future<void> save() async {
    await ref.read(databaseRepositoryProvider).saveRecentSearches(state);
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
    NotifierProvider<RecentSearchNotifier, List<String>>(RecentSearchNotifier.new);
