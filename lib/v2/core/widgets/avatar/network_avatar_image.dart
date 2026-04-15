import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/features/auth/domain/entities/user_entity.dart';

/// Shared avatar image widget — loads SVG or raster from URL with fallback icon.
class NetworkAvatarImage extends StatelessWidget {
  const NetworkAvatarImage({
    super.key,
    required this.url,
    this.fallbackIconSize = 20,
  });

  final String url;
  final double fallbackIconSize;

  @override
  Widget build(BuildContext context) {
    if (isSvgUrl(url)) {
      return SvgPicture.network(
        url,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => AvatarFallbackIcon(size: fallbackIconSize),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => AvatarFallbackIcon(size: fallbackIconSize),
    );
  }
}

/// Fallback person icon for avatars.
class AvatarFallbackIcon extends StatelessWidget {
  const AvatarFallbackIcon({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.person_rounded,
        size: size,
        color: AppColors.white,
      ),
    );
  }
}

/// Extracts a trimmed, non-empty avatar URL from a [UserEntity], or null.
String? avatarUrlFromUser(UserEntity? user) {
  final raw = user?.photoUrl?.trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return raw;
}

/// Returns true if [url] points to an SVG resource.
bool isSvgUrl(String url) {
  final lower = url.toLowerCase();
  if (lower.contains('.svg')) {
    return true;
  }
  final uri = Uri.tryParse(lower);
  if (uri == null) {
    return lower.contains('/svg');
  }
  return uri.path.endsWith('/svg') || uri.path.endsWith('.svg');
}
