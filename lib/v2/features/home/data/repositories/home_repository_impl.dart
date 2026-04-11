import 'package:tunify/v2/core/utils/logger.dart';
import 'package:tunify/v2/features/home/data/home_feed_mock.dart';
import 'package:tunify/v2/features/home/domain/entities/home_feed.dart';
import 'package:tunify/v2/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  @override
  Future<HomeFeed> loadHomeFeed() async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      return HomeFeedMock.build();
    } catch (e) {
      Logger.warning('HomeRepository.loadHomeFeed failed: $e', tag: 'HomeRepository');
      rethrow;
    }
  }
}
