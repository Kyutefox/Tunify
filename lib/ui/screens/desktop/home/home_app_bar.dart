import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/ui/widgets/auth/user_avatar_button.dart';
import 'package:tunify/features/auth/auth_provider.dart';
import 'package:tunify/features/settings/guest_profile_provider.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

class HomeAppBar extends ConsumerWidget {
  const HomeAppBar({super.key, required this.greeting, this.asSliver = true});
  final String greeting;

  /// When true (default), returns [SliverAppBar]. When false, returns a fixed header widget.
  final bool asSliver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isGuest = ref.watch(guestModeProvider);
    final guestUsername =
        isGuest ? ref.watch(guestUsernameProvider).value : null;
    final username = (user?.userMetadata?['username'] as String?) ??
        (user?.email?.split('@').first) ??
        (isGuest ? (guestUsername ?? 'Guest') : 'V');

    final titleRow = Row(
      children: [
        Expanded(
          child: ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: Text(
              '$greeting, $username',
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppFontSize.base,
                fontWeight: FontWeight.w600,
                letterSpacing: AppLetterSpacing.normal,
              ),
            ),
          ),
        ),
        const UserAvatarButton(),
      ],
    );

    if (asSliver) {
      return SliverAppBar(
        floating: true,
        snap: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 52,
        title: titleRow,
      );
    }

    return Container(
      width: double.infinity,
      color: AppColorsScheme.of(context).background,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 52,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: titleRow,
            ),
          ),
        ),
      ),
    );
  }
}
