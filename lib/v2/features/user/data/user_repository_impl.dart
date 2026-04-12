import 'package:tunify/v2/core/errors/exceptions.dart';
import 'package:tunify/v2/core/errors/failures.dart';
import 'package:tunify/v2/core/network/tunify_api_client.dart';
import 'package:tunify/v2/core/utils/result.dart';
import 'package:tunify/v2/features/auth/data/user_entity_mapper.dart';
import 'package:tunify/v2/features/auth/domain/entities/user_entity.dart';
import 'package:tunify/v2/features/user/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({required TunifyApiClient api}) : _api = api;

  final TunifyApiClient _api;

  @override
  Future<Result<UserEntity>> fetchMe() async {
    try {
      final json = await _api.getJson('/v1/users/me');
      return Result.success(userEntityFromProfileJson(json));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
