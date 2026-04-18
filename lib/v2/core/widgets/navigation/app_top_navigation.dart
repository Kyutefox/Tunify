import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/widgets/avatar/network_avatar_image.dart';
import 'package:tunify/v2/features/auth/presentation/providers/auth_session_provider.dart';

/// Shared top navigation row for v2 pages:
/// left session avatar + flexible middle content + optional trailing action.
class AppTopNavigation extends StatelessWidget {
  const AppTopNavigation({
    super.key,
    required this.middle,
    this.trailing,
    this.leadingOnTap,
    this.useBackButton = false,
  });

  final Widget middle;
  final Widget? trailing;
  final VoidCallback? leadingOnTap;

  /// When true, shows a back chevron instead of the session avatar (e.g. folder drill-in).
  final bool useBackButton;

  /// Gap between system status bar and nav content (Spotify-matched).
  static const double statusBarGap = AppSpacing.md + AppSpacing.sm;

  /// Height of the nav row content (gap + avatar + bottom pad), excluding
  /// the system status bar inset. Use with `mq.padding.top` to get total.
  static const double contentHeight =
      statusBarGap + AppSpacing.navAvatarSize + AppSpacing.md;

  static EdgeInsets paddingFor(EdgeInsets safeArea) {
    return EdgeInsets.fromLTRB(
      AppSpacing.lg,
      safeArea.top + statusBarGap,
      AppSpacing.lg,
      AppSpacing.md,
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeArea = MediaQuery.paddingOf(context);
    return Material(
      color: AppColors.nearBlack,
      child: Padding(
        padding: paddingFor(safeArea),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (useBackButton)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: AppSpacing.navAvatarSize,
                  minHeight: AppSpacing.navAvatarSize,
                ),
                icon: const Icon(Icons.arrow_back, color: AppColors.white, size: 22),
                onPressed: leadingOnTap,
              )
            else
              SessionAvatarButton(onTap: leadingOnTap),
            const SizedBox(width: AppSpacing.lg - AppSpacing.sm),
            Expanded(child: middle),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.md),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class SessionAvatarButton extends ConsumerWidget {
  const SessionAvatarButton({
    super.key,
    this.onTap,
    this.size = AppSpacing.navAvatarSize,
    this.iconSize = AppSpacing.navAvatarIconSize,
  });

  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionProvider).whenOrNull(data: (value) => value);
    final avatarUrl = avatarUrlFromUser(user);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppColors.midDark,
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: avatarUrl == null
              ? AvatarFallbackIcon(size: iconSize)
              : NetworkAvatarImage(url: avatarUrl, fallbackIconSize: iconSize),
        ),
      ),
    );
  }
}

