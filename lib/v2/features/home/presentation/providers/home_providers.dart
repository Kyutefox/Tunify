import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/features/home/data/repositories/home_repository_impl.dart';
import 'package:tunify/v2/features/home/domain/entities/home_feed.dart';
import 'package:tunify/v2/features/home/domain/repositories/home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl();
});

final homeFeedProvider = FutureProvider<HomeFeed>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.loadHomeFeed();
});

/// Home filter chips (presentation-only UI state; Riverpod per RULES.md).
enum HomeChipFilter { all, music, podcasts }

class HomeChipFilterNotifier extends Notifier<HomeChipFilter> {
  @override
  HomeChipFilter build() => HomeChipFilter.all;

  void select(HomeChipFilter value) => state = value;
}

final homeChipFilterProvider =
    NotifierProvider<HomeChipFilterNotifier, HomeChipFilter>(
  HomeChipFilterNotifier.new,
);
