import 'package:tunify/v2/core/network/tunify_api_client.dart';
import 'package:tunify/v2/core/utils/logger.dart';
import 'package:tunify/v2/features/home/data/home_api_mapper.dart';
import 'package:tunify/v2/features/home/domain/entities/home_feed.dart';
import 'package:tunify/v2/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({required TunifyApiClient api}) : _api = api;

  final TunifyApiClient _api;

  @override
  Future<HomeFeed> loadHomeFeed() async {
    try {
      final json = await _api.getJson('/v1/browse/home');
      return HomeApiMapper.fromHomePageJson(json);
    } catch (e, st) {
      Logger.error(
        'HomeRepository.loadHomeFeed failed: $e',
        tag: 'HomeRepository',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
