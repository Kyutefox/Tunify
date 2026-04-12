import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/network/tunify_auth_prefs.dart';
import 'package:tunify/v2/features/auth/domain/entities/user_entity.dart';
import 'package:tunify/v2/features/auth/presentation/providers/auth_providers.dart';

/// Loads the signed-in profile via `GET /v1/users/me` when a token exists.
final currentUserProvider = FutureProvider<UserEntity?>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  final token = prefs.getString(TunifyAuthPrefsKeys.accessToken);
  if (token == null || token.isEmpty) {
    return null;
  }
  final result = await ref.read(userRepositoryProvider).fetchMe();
  return result.data;
});
