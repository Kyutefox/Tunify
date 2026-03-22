import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/core/constants/app_strings.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';

class DynamicHeader extends StatefulWidget {
  final String greeting;
  final String? userName;
  final String? featuredArtworkUrl;
  final Color? dominantColor;
  final VoidCallback? onSearchTap;
  final VoidCallback? onProfileTap;

  const DynamicHeader({
    super.key,
    required this.greeting,
    this.userName,
    this.featuredArtworkUrl,
    this.dominantColor,
    this.onSearchTap,
    this.onProfileTap,
  });

  @override
  State<DynamicHeader> createState() => _DynamicHeaderState();
}

class _DynamicHeaderState extends State<DynamicHeader>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _glowController;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 4 + 1,
        speed: _random.nextDouble() * 0.3 + 0.1,
        opacity: _random.nextDouble() * 0.5 + 0.2,
      ));
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.dominantColor ?? AppColors.primary;

    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          _buildBackground(accentColor),
          _buildParticles(accentColor),
          _buildGlowEffect(accentColor),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildBackground(Color accentColor) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withValues(alpha: 0.3),
                  AppColors.background,
                  AppColors.background,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
          if (widget.featuredArtworkUrl != null)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: widget.featuredArtworkUrl!,
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.6),
                colorBlendMode: BlendMode.darken,
                imageBuilder: (context, imageProvider) {
                  return Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.background.withValues(alpha: 0.8),
                              AppColors.background,
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                placeholder: (context, url) => const SizedBox(),
                errorWidget: (context, url, error) => const SizedBox(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildParticles(Color accentColor) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(
            particles: _particles,
            progress: _particleController.value,
            color: accentColor,
          ),
        );
      },
    );
  }

  Widget _buildGlowEffect(Color accentColor) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Positioned(
          top: -100 + (_glowController.value * 30),
          left: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accentColor.withValues(
                      alpha: 0.15 + (_glowController.value * 0.1)),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: SvgPicture.asset(
                      AppStrings.logoAsset,
                      width: 44,
                      height: 44,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(begin: const Offset(0.8, 0.8)),
                const Spacer(),
                _buildIconButton(
                  icon: AppIcons.search,
                  onTap: widget.onSearchTap,
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 100.ms)
                    .slideX(begin: 0.2),
                const SizedBox(width: 12),
                _buildProfileButton()
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 200.ms)
                    .slideX(begin: 0.2),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.greeting,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppFontSize.xl,
                fontWeight: FontWeight.w500,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 300.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: 4),
            Text(
              widget.userName ?? 'Music Lover',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppFontSize.display3,
                fontWeight: FontWeight.w700,
                letterSpacing: AppLetterSpacing.display,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 400.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.glassWhite,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.accentGreen.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Online',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: AppFontSize.sm,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 500.ms)
                .slideX(begin: -0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required List<List<dynamic>> icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.glassWhite,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: AppIcon(
          icon: icon,
          color: AppColors.textPrimary,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildProfileButton() {
    return GestureDetector(
      onTap: widget.onProfileTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: AppIcon(
            icon: AppIcons.person,
            color: AppColors.textPrimary,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final adjustedY = (particle.y + progress * particle.speed) % 1.0;

      final paint = Paint()
        ..color = color.withValues(alpha: particle.opacity * 0.5)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width, adjustedY * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
