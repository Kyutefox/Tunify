import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/features/auth/domain/entities/user_entity.dart';

/// Removes `<metadata>` blocks [flutter_svg] does not handle (avoids log spam).
String stripSvgMetadataForLoader(String svg) {
  return svg
      .replaceAll(
        RegExp(r'<metadata\b[^>]*>[\s\S]*?</metadata>', caseSensitive: false),
        '',
      )
      .replaceAll(
        RegExp(r'<metadata\b[^>]*/>', caseSensitive: false),
        '',
      );
}

/// Shared avatar image widget — loads SVG or raster from URL with fallback icon.
class NetworkAvatarImage extends StatefulWidget {
  const NetworkAvatarImage({
    super.key,
    required this.url,
    this.fallbackIconSize = 20,
  });

  final String url;
  final double fallbackIconSize;

  @override
  State<NetworkAvatarImage> createState() => _NetworkAvatarImageState();
}

class _NetworkAvatarImageState extends State<NetworkAvatarImage> {
  late Future<String> _svgMarkupFuture;

  @override
  void initState() {
    super.initState();
    _svgMarkupFuture = _loadSanitizedSvg(widget.url);
  }

  @override
  void didUpdateWidget(covariant NetworkAvatarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _svgMarkupFuture = _loadSanitizedSvg(widget.url);
    }
  }

  static Future<String> _loadSanitizedSvg(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw StateError('HTTP ${response.statusCode}');
    }
    final raw = utf8.decode(response.bodyBytes);
    return stripSvgMetadataForLoader(raw);
  }

  @override
  Widget build(BuildContext context) {
    if (!isSvgUrl(widget.url)) {
      return Image.network(
        widget.url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            AvatarFallbackIcon(size: widget.fallbackIconSize),
      );
    }

    return FutureBuilder<String>(
      future: _svgMarkupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AvatarFallbackIcon(size: widget.fallbackIconSize);
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return AvatarFallbackIcon(size: widget.fallbackIconSize);
        }
        return SvgPicture.string(
          snapshot.data!,
          fit: BoxFit.cover,
          allowDrawingOutsideViewBox: true,
        );
      },
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
      child: AppIcon(
        icon: AppIcons.person,
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
