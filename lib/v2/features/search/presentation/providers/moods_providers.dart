import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/features/auth/presentation/providers/auth_providers.dart';
import 'package:tunify/v2/features/search/data/repositories/moods_repository_impl.dart';
import 'package:tunify/v2/features/search/domain/entities/moods_models.dart';
import 'package:tunify/v2/features/search/domain/repositories/moods_repository.dart';

final moodsRepositoryProvider = Provider<MoodsRepository>((ref) {
  return MoodsRepositoryImpl(api: ref.watch(tunifyApiClientProvider));
});

final moodsAndGenresProvider = FutureProvider.autoDispose<List<SearchMoodTile>>(
  (ref) async {
    final repo = ref.watch(moodsRepositoryProvider);
    final result = await repo.fetchMoodsAndGenres();

    return result.fold(
      (data) => data,
      (failure) => throw Exception(failure.message),
    );
  },
);
