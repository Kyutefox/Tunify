import 'package:tunify/v2/core/errors/exceptions.dart';
import 'package:tunify/v2/core/errors/failures.dart';
import 'package:tunify/v2/core/network/tunify_api_client.dart';
import 'package:tunify/v2/core/utils/result.dart';
import 'package:tunify/v2/features/search/data/moods_api_mapper.dart';
import 'package:tunify/v2/features/search/domain/entities/moods_models.dart';
import 'package:tunify/v2/features/search/domain/repositories/moods_repository.dart';

class MoodsRepositoryImpl implements MoodsRepository {
  const MoodsRepositoryImpl({required TunifyApiClient api}) : _api = api;

  final TunifyApiClient _api;

  @override
  Future<Result<List<SearchMoodTile>>> fetchMoodsAndGenres() async {
    try {
      final json = await _api.getJson('/v1/browse/moods');
      final itemsJson = json['items'];
      final moods = MoodsApiMapper.fromItemsJson(itemsJson);
      return Result.success(moods);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
