import 'package:tunify/v2/features/home/domain/entities/home_feed.dart';

abstract class HomeRepository {
  Future<HomeFeed> loadHomeFeed();
}
