import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v1/features/auth/auth_provider.dart';
import 'package:tunify/v1/features/home/home_state_provider.dart';
import 'package:tunify/v1/features/player/player_state_provider.dart';
import 'package:tunify/v1/features/settings/guest_profile_provider.dart';
import 'package:tunify/v1/ui/screens/shared/home/home_content.dart';
import 'package:tunify/v1/ui/theme/app_colors.dart';
import 'package:tunify/v1/ui/theme/design_tokens.dart';
import 'package:tunify/v1/ui/widgets/auth/user_avatar_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure the home feed is requested when Home tab is first mounted.
    Future.microtask(() => ref.read(homeProvider.notifier).loadContent());
  }

  @override
  Widget build(BuildContext context) {
    final greeting = ref.watch(greetingProvider);
    final isGuest = ref.watch(guestModeProvider);
    final guestUsername =
        isGuest ? ref.watch(guestUsernameProvider).value : null;
    final username = isGuest ? (guestUsername ?? 'Guest') : 'Guest';

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          floating: false,
          snap: false,
          automaticallyImplyLeading: false,
          toolbarHeight: 52,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          titleSpacing: AppSpacing.base,
          title: Row(
            children: [
              Expanded(
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: Text(
                    '$greeting, $username',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppFontSize.base,
                      fontWeight: FontWeight.w600,
                      letterSpacing: AppLetterSpacing.normal,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const UserAvatarButton(),
            ],
          ),
        ),
        HomeContent(
          onPlay: (song) => ref.read(playerProvider.notifier).playSong(song),
        ),
      ],
    );
  }
}
