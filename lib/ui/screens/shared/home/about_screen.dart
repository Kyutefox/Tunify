import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

const _kAppName = 'Tunify';
const _kAppTagline = 'Music for every moment';
const _kAppDescription =
    'A beautifully crafted music streaming app built for people who care about how '
    'music feels. Stream, discover, and organise your library — all in one place.';
const _kReleaseYear = '2025';

const _kDeveloperName = 'MrJukeman';
const _kDeveloperRole = 'Lead Developer';
const _kDeveloperAvatarUrl =
    'https://avatars.githubusercontent.com/u/52706390?v=4';
const _kDevGithubUrl = 'https://github.com/mrjukeman';
const _kDevGithubLabel = 'github.com/mrjukeman';
const _kDevWebUrl = 'https://rajuchoudhary.com.np';
const _kDevWebLabel = 'rajuchoudhary.com.np';

const _kOrgName = 'Kyutefox';
const _kOrgRole = 'Organization';
const _kOrgLogoUrl = 'https://cdn.kyutefox.com/Kyutefox/svg/Fox.svg';
const _kOrgGithubUrl = 'https://github.com/kyutefox';
const _kOrgGithubLabel = 'github.com/kyutefox';
const _kOrgWebUrl = 'https://kyutefox.com';
const _kOrgWebLabel = 'kyutefox.com';
// ──────────────────────────────────────────────────────────────────────────────

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';
  String _build = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() {
          _version = info.version;
          _build = info.buildNumber;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColorsScheme.of(context).background,
      body: CustomScrollView(
        cacheExtent: 1000,
        slivers: [
          SliverToBoxAdapter(
            child: _HeroHeader(
              topPadding: topPadding,
              version: _version,
              buildNumber: _build,
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.base,
              AppSpacing.xl,
              AppSpacing.base,
              bottomPadding + AppSpacing.xxl,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _AppInfoCard(),
                const SizedBox(height: AppSpacing.md),
                _PersonCard(
                  sectionTitle: 'Developer',
                  name: _kDeveloperName,
                  role: _kDeveloperRole,
                  avatarUrl: _kDeveloperAvatarUrl,
                  avatarIsCircle: true,
                  avatarFallbackGradient: AppColors.primaryGradient,
                  githubUrl: _kDevGithubUrl,
                  githubLabel: _kDevGithubLabel,
                  webUrl: _kDevWebUrl,
                  webLabel: _kDevWebLabel,
                ),
                const SizedBox(height: AppSpacing.md),
                _PersonCard(
                  sectionTitle: 'Organization',
                  name: _kOrgName,
                  role: _kOrgRole,
                  avatarUrl: _kOrgLogoUrl,
                  avatarIsCircle: false,
                  avatarFallbackGradient: const LinearGradient(
                    colors: [AppColors.accentOrange, Color(0xFFFF2D78)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  githubUrl: _kOrgGithubUrl,
                  githubLabel: _kOrgGithubLabel,
                  webUrl: _kOrgWebUrl,
                  webLabel: _kOrgWebLabel,
                ),
                const SizedBox(height: AppSpacing.md),
                _TechStackCard(),
                const SizedBox(height: AppSpacing.xl),
                _FooterText(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.topPadding,
    required this.version,
    required this.buildNumber,
  });
  final double topPadding;
  final String version;
  final String buildNumber;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 280 + topPadding,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A3A2A), Color(0xFF0D2018), Color(0xFF121212)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.65, 1.0],
            ),
          ),
        ),
        Positioned(
          top: topPadding - 20,
          left: -40,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: UIOpacity.subtle),
            ),
          ),
        ),
        Positioned(
          top: topPadding + 40,
          right: -30,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: UIOpacity.subtle),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: AppIcon(
                    icon: AppIcons.back,
                    color: AppColorsScheme.of(context).textPrimary,
                    size: 24,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: const EdgeInsets.all(AppSpacing.base),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: UISize.appLogoLg,
                height: UISize.appLogoLg,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: SvgPicture.asset(
                    'assets/app-icon.svg',
                    width: UISize.appLogoLg,
                    height: UISize.appLogoLg,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                _kAppName,
                style: TextStyle(
                  color: AppColorsScheme.of(context).textPrimary,
                  fontSize: AppFontSize.display3,
                  fontWeight: FontWeight.w800,
                  letterSpacing: AppLetterSpacing.display,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _kAppTagline,
                style: TextStyle(
                  color: AppColorsScheme.of(context).textSecondary,
                  fontSize: AppFontSize.base,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.glassWhite,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                      color: AppColors.glassBorder, width: UIStroke.thin),
                ),
                child: Text(
                  version.isEmpty ? '' : 'v$version (build $buildNumber)',
                  style: TextStyle(
                    color: AppColorsScheme.of(context).textSecondary,
                    fontSize: AppFontSize.sm,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Section card base ────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColorsScheme.of(context).surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.glassBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: AppFontSize.xs,
              fontWeight: FontWeight.w700,
              letterSpacing: AppLetterSpacing.label,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

// ─── App Info ─────────────────────────────────────────────────────────────────

class _AppInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'About the App',
      child: Text(
        _kAppDescription,
        style: TextStyle(
          color: AppColorsScheme.of(context).textSecondary,
          fontSize: AppFontSize.base,
          height: AppLineHeight.relaxed,
        ),
      ),
    );
  }
}

// ─── Person / Org Card ────────────────────────────────────────────────────────

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.sectionTitle,
    required this.name,
    required this.role,
    required this.avatarUrl,
    required this.avatarIsCircle,
    required this.avatarFallbackGradient,
    required this.githubUrl,
    required this.githubLabel,
    required this.webUrl,
    required this.webLabel,
  });

  final String sectionTitle;
  final String name;
  final String role;
  final String avatarUrl;
  final bool avatarIsCircle;
  final LinearGradient avatarFallbackGradient;
  final String githubUrl;
  final String githubLabel;
  final String webUrl;
  final String webLabel;

  @override
  Widget build(BuildContext context) {
    final radius = avatarIsCircle
        ? BorderRadius.circular(AppRadius.full)
        : BorderRadius.circular(AppRadius.md);

    return _SectionCard(
      title: sectionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              ClipRRect(
                borderRadius: radius,
                child: _buildAvatar(avatarUrl, avatarIsCircle, name),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textPrimary,
                        fontSize: AppFontSize.xl,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs / 2),
                    Text(
                      role,
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textSecondary,
                        fontSize: AppFontSize.md,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _IconLink(
                label: 'GitHub',
                sublabel: githubLabel,
                icon: AppIcons.github,
                color: AppColors.primary,
                url: githubUrl,
              ),
              const SizedBox(width: AppSpacing.md),
              _IconLink(
                label: 'Website',
                sublabel: webLabel,
                icon: AppIcons.devices,
                color: AppColors.accentCyan,
                url: webUrl,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String url, bool isCircle, String name) {
    if (url.endsWith('.svg')) {
      return Container(
        width: UISize.avatar,
        height: UISize.avatar,
        color: Colors.transparent,
        child: SvgPicture.network(
          url,
          width: UISize.avatar,
          height: UISize.avatar,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => _GradientFallback(
            name: name,
            gradient: avatarFallbackGradient,
            isCircle: isCircle,
          ),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: UISize.avatar,
      height: UISize.avatar,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => _GradientFallback(
        name: name,
        gradient: avatarFallbackGradient,
        isCircle: isCircle,
      ),
    );
  }
}

class _GradientFallback extends StatelessWidget {
  const _GradientFallback({
    required this.name,
    required this.gradient,
    required this.isCircle,
  });
  final String name;
  final LinearGradient gradient;
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: isCircle
            ? BorderRadius.circular(AppRadius.full)
            : BorderRadius.circular(AppRadius.md),
      ),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: AppFontSize.h2,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _IconLink extends StatelessWidget {
  const _IconLink({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.url,
  });

  final String label;
  final String sublabel;
  final List<List<dynamic>> icon;
  final Color color;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: color.withValues(alpha: UIOpacity.faint),
                width: UIStroke.thin,
              ),
            ),
            child: Row(
              children: [
                AppIcon(icon: icon, color: color, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: AppFontSize.sm,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        sublabel,
                        style: TextStyle(
                          color: AppColorsScheme.of(context).textMuted,
                          fontSize: AppFontSize.micro,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Tech Stack ───────────────────────────────────────────────────────────────

class _TechStackCard extends StatelessWidget {
  static const _stack = [
    ('Flutter', Color(0xFF54C5F8)),
    ('Dart', Color(0xFF00BCD4)),
    ('Riverpod', Color(0xFF1DB954)),
    ('just_audio', Color(0xFFFF6B35)),
    ('SQLite', Color(0xFF00D2FF)),
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Built With',
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: _stack
            .map((item) => _TechChip(label: item.$1, color: item.$2))
            .toList(),
      ),
    );
  }
}

class _TechChip extends StatelessWidget {
  const _TechChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AppFontSize.sm,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── About Screen Body (desktop-embeddable, no Scaffold) ──────────────────────

/// Scroll-only version of [AboutScreen] without a [Scaffold] or back button.
/// Used in the desktop 2-pane settings screen.
class AboutScreenBody extends StatefulWidget {
  const AboutScreenBody({super.key});

  @override
  State<AboutScreenBody> createState() => _AboutScreenBodyState();
}

class _AboutScreenBodyState extends State<AboutScreenBody> {
  String _version = '';
  String _build = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() {
          _version = info.version;
          _build = info.buildNumber;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.xl,
        AppSpacing.base,
        AppSpacing.xxl,
      ),
      child: Column(
        children: [
          // Compact app identity (no back button, no top padding)
          Container(
            width: UISize.appLogoMd,
            height: UISize.appLogoMd,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: SvgPicture.asset(
                'assets/app-icon.svg',
                width: UISize.appLogoMd,
                height: UISize.appLogoMd,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            _kAppName,
            style: TextStyle(
              color: AppColorsScheme.of(context).textPrimary,
              fontSize: AppFontSize.h1,
              fontWeight: FontWeight.w800,
              letterSpacing: AppLetterSpacing.display,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _kAppTagline,
            style: TextStyle(
              color: AppColorsScheme.of(context).textSecondary,
              fontSize: AppFontSize.md,
            ),
          ),
          if (_version.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.glassWhite,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: AppColors.glassBorder, width: 1),
              ),
              child: Text(
                'v$_version (build $_build)',
                style: TextStyle(
                  color: AppColorsScheme.of(context).textSecondary,
                  fontSize: AppFontSize.sm,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          _AppInfoCard(),
          const SizedBox(height: AppSpacing.md),
          _PersonCard(
            sectionTitle: 'Developer',
            name: _kDeveloperName,
            role: _kDeveloperRole,
            avatarUrl: _kDeveloperAvatarUrl,
            avatarIsCircle: true,
            avatarFallbackGradient: AppColors.primaryGradient,
            githubUrl: _kDevGithubUrl,
            githubLabel: _kDevGithubLabel,
            webUrl: _kDevWebUrl,
            webLabel: _kDevWebLabel,
          ),
          const SizedBox(height: AppSpacing.md),
          _PersonCard(
            sectionTitle: 'Organization',
            name: _kOrgName,
            role: _kOrgRole,
            avatarUrl: _kOrgLogoUrl,
            avatarIsCircle: false,
            avatarFallbackGradient: const LinearGradient(
              colors: [AppColors.accentOrange, Color(0xFFFF2D78)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            githubUrl: _kOrgGithubUrl,
            githubLabel: _kOrgGithubLabel,
            webUrl: _kOrgWebUrl,
            webLabel: _kOrgWebLabel,
          ),
          const SizedBox(height: AppSpacing.md),
          _TechStackCard(),
          const SizedBox(height: AppSpacing.xl),
          _FooterText(),
        ],
      ),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _FooterText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 2,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '© $_kReleaseYear $_kOrgName. All rights reserved.',
          style: TextStyle(
              color: AppColorsScheme.of(context).textMuted,
              fontSize: AppFontSize.sm),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              color: AppColorsScheme.of(context)
                  .textMuted
                  .withValues(alpha: UIOpacity.emphasis),
              fontSize: AppFontSize.xs,
            ),
            children: const [
              TextSpan(text: 'Made with '),
              TextSpan(
                text: '♥',
                style: TextStyle(color: Color(0xFFE91429)),
              ),
              TextSpan(text: ' using Flutter'),
            ],
          ),
        ),
      ],
    );
  }
}
