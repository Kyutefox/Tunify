import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/v1/data/repositories/database_repository.dart';

const String kAvatarSeedKey = 'avatar_seed';

/// Provides the avatar seed used for generating the user's Bottts avatar.
/// The seed is persisted so the same avatar is shown consistently.
final avatarSeedProvider =
    AsyncNotifierProvider<AvatarSeedNotifier, String?>(AvatarSeedNotifier.new);

class AvatarSeedNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    return ref.read(databaseBridgeProvider).getSetting(kAvatarSeedKey);
  }

  Future<void> setAvatarSeed(String seed) async {
    await ref
        .read(databaseBridgeProvider)
        .setSetting(kAvatarSeedKey, seed.trim());
    state = AsyncData(seed.trim());
  }

  Future<void> clearAvatarSeed() async {
    await ref.read(databaseBridgeProvider).setSetting(kAvatarSeedKey, '');
    state = const AsyncData(null);
  }
}

/// Generates a Bottts avatar URL from a seed.
/// Uses DiceBear API with the bottts style for robot-like avatars.
String generateBotttsAvatarUrl(String seed, {int size = 72}) {
  return 'https://api.dicebear.com/9.x/bottts/png?seed=${Uri.encodeComponent(seed)}&size=$size';
}
