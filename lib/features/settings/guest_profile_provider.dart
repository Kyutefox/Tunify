import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/data/repositories/database_repository.dart';

const String kGuestUsernameKey = 'guest_username';

final guestUsernameProvider =
    AsyncNotifierProvider<GuestUsernameNotifier, String?>(
        GuestUsernameNotifier.new);

class GuestUsernameNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    return ref.read(databaseBridgeProvider).getSetting(kGuestUsernameKey);
  }

  Future<void> setUsername(String username) async {
    await ref
        .read(databaseBridgeProvider)
        .setSetting(kGuestUsernameKey, username.trim());
    state = AsyncData(username.trim());
  }

  Future<void> clearGuestData() async {
    await ref.read(databaseBridgeProvider).setSetting(kGuestUsernameKey, '');
    state = const AsyncData(null);
  }
}
