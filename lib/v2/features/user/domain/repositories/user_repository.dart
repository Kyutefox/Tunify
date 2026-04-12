import 'package:tunify/v2/core/utils/result.dart';
import 'package:tunify/v2/features/auth/domain/entities/user_entity.dart';

/// Authenticated user profile from the API.
abstract class UserRepository {
  /// `GET /v1/users/me` — requires a stored access token.
  Future<Result<UserEntity>> fetchMe();
}
