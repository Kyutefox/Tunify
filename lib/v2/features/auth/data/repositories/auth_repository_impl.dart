import 'package:shared_preferences/shared_preferences.dart';
import 'package:tunify/v2/core/errors/exceptions.dart';
import 'package:tunify/v2/core/errors/failures.dart';
import 'package:tunify/v2/core/network/tunify_api_client.dart';
import 'package:tunify/v2/core/network/tunify_auth_prefs.dart';
import 'package:tunify/v2/core/utils/result.dart';
import 'package:tunify/v2/features/auth/data/user_entity_mapper.dart';
import 'package:tunify/v2/features/auth/domain/entities/user_entity.dart';
import 'package:tunify/v2/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required TunifyApiClient api,
    required SharedPreferences prefs,
  })  : _api = api,
        _prefs = prefs;

  final TunifyApiClient _api;
  final SharedPreferences _prefs;

  Future<void> _persistTokenResponse(Map<String, dynamic> body) async {
    final token = body['token'] as String?;
    final userId = body['user_id'] as String?;
    if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
      throw ServerException('Invalid authentication response');
    }
    await _prefs.setString(TunifyAuthPrefsKeys.accessToken, token);
    await _prefs.setString(TunifyAuthPrefsKeys.userId, userId);
  }

  @override
  Future<Result<UserEntity>> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final username = email.trim();
      final body = await _api.postJson(
        '/v1/auth/login',
        {'username': username, 'password': password},
        withAuth: false,
      );
      await _persistTokenResponse(body);
      final profile = await _api.getJson('/v1/users/me');
      return Result.success(userEntityFromProfileJson(profile));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<UserEntity>> signUp(
    String email,
    String password,
    String username,
  ) async {
    try {
      final payload = <String, dynamic>{
        'username': username.trim(),
        'password': password,
      };
      final trimmedEmail = email.trim();
      if (trimmedEmail.isNotEmpty) {
        payload['email'] = trimmedEmail;
      }
      final body =
          await _api.postJson('/v1/auth/register', payload, withAuth: false);
      await _persistTokenResponse(body);
      final profile = await _api.getJson('/v1/users/me');
      return Result.success(userEntityFromProfileJson(profile));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    return Result.failure(const NetworkFailure('Not implemented'));
  }

  @override
  Future<Result<UserEntity>> signInWithGoogle() async {
    return Result.failure(const NetworkFailure('Not implemented'));
  }

  @override
  Future<Result<UserEntity>> signInWithApple() async {
    return Result.failure(const NetworkFailure('Not implemented'));
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _prefs.remove(TunifyAuthPrefsKeys.accessToken);
      await _prefs.remove(TunifyAuthPrefsKeys.userId);
      return Result.success(null);
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<UserEntity?>> getCurrentUser() async {
    try {
      final token = _prefs.getString(TunifyAuthPrefsKeys.accessToken);
      if (token == null || token.isEmpty) {
        return Result.success(null);
      }
      final profile = await _api.getJson('/v1/users/me');
      return Result.success(userEntityFromProfileJson(profile));
    } on ServerException catch (e) {
      if (e.code == 401) {
        await signOut();
        return Result.success(null);
      }
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
