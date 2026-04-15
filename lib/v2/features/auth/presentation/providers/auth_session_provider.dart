import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/network/tunify_auth_prefs.dart';
import 'package:tunify/v2/features/auth/domain/entities/user_entity.dart';
import 'package:tunify/v2/features/auth/presentation/providers/auth_providers.dart';
import 'package:tunify/v2/features/auth/presentation/providers/form_validation_provider.dart';
import 'package:tunify/v2/features/home/presentation/providers/home_providers.dart';
import 'package:tunify/v2/features/user/presentation/providers/user_providers.dart';

/// Restores the signed-in user from [SharedPreferences] + `GET /v1/users/me` on app start,
/// and drives [MaterialApp] home (welcome vs authenticated shell) per RULES session flow.
final authSessionProvider =
    AsyncNotifierProvider<AuthSessionNotifier, UserEntity?>(
  AuthSessionNotifier.new,
);

class AuthSessionNotifier extends AsyncNotifier<UserEntity?> {
  @override
  Future<UserEntity?> build() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final token = prefs.getString(TunifyAuthPrefsKeys.accessToken);
    if (token == null || token.isEmpty) {
      return null;
    }
    final auth = ref.read(authRepositoryProvider);
    final result = await auth.getCurrentUser();
    return result.fold(
      (user) => user,
      (_) => null,
    );
  }

  /// Called after a successful sign-in / sign-up when [UserEntity] is already available.
  void applySignedInUser(UserEntity user) {
    state = AsyncData(user);
  }

  Future<void> signOut() async {
    final auth = ref.read(authRepositoryProvider);
    final result = await auth.signOut();
    result.fold((_) {}, (_) {});
    state = const AsyncData(null);
    ref.invalidate(homeFeedProvider);
    ref.invalidate(currentUserProvider);
    ref.invalidate(formValidationProvider);
  }
}
