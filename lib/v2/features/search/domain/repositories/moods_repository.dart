import 'package:tunify/v2/core/utils/result.dart';
import 'package:tunify/v2/features/search/domain/entities/moods_models.dart';

abstract interface class MoodsRepository {
  Future<Result<List<SearchMoodTile>>> fetchMoodsAndGenres();
}

