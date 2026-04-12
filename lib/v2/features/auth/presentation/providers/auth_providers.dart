import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tunify/v2/core/network/api_config.dart';
import 'package:tunify/v2/core/network/tunify_api_client.dart';
import 'package:tunify/v2/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tunify/v2/features/auth/domain/repositories/auth_repository.dart';
import 'package:tunify/v2/features/user/data/user_repository_impl.dart';
import 'package:tunify/v2/features/user/domain/repositories/user_repository.dart';

/// Must be overridden in `main()` after `SharedPreferences.getInstance()`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError(
      'sharedPreferencesProvider was not overridden in ProviderScope'),
);

final apiConfigProvider =
    Provider<ApiConfig>((ref) => ApiConfig.fromEnvironment());

final tunifyApiClientProvider = Provider<TunifyApiClient>((ref) {
  final client = TunifyApiClient(
    config: ref.watch(apiConfigProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
  ref.onDispose(client.close);
  return client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    api: ref.watch(tunifyApiClientProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(api: ref.watch(tunifyApiClientProvider));
});
