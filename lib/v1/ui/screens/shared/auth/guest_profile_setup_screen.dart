import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/v1/core/constants/app_icons.dart';
import 'package:tunify/v1/core/utils/username_generator.dart';
import 'package:tunify/v1/features/auth/auth_provider.dart';
import 'package:tunify/v1/features/settings/avatar_provider.dart';
import 'package:tunify/v1/features/settings/guest_profile_provider.dart';
import 'package:tunify/v1/ui/widgets/common/button.dart';
import 'package:tunify/v1/ui/widgets/common/input_field.dart';
import 'package:tunify/v1/ui/theme/app_colors.dart';
import 'package:tunify/v1/ui/theme/design_tokens.dart';
import 'package:tunify/v1/ui/widgets/onboarding/onboarding_layout_sizing.dart';
import 'package:tunify/v1/ui/widgets/onboarding/onboarding_spaced_scroll_body.dart';

class GuestProfileSetupScreen extends ConsumerStatefulWidget {
  const GuestProfileSetupScreen({super.key, this.isInitial = true});
  final bool isInitial;

  @override
  ConsumerState<GuestProfileSetupScreen> createState() =>
      _GuestProfileSetupScreenState();
}

class _GuestProfileSetupScreenState
    extends ConsumerState<GuestProfileSetupScreen>
    with TickerProviderStateMixin {
  late final TextEditingController _controller;
  late String _avatarSeed;
  bool _saving = false;
  late final AnimationController _avatarScaleCtrl;

  static String _randomUsername() => UsernameGenerator.generate();

  @override
  void initState() {
    super.initState();
    _avatarScaleCtrl = AnimationController(
      vsync: this,
      value: 1.0,
      lowerBound: 0.88,
      upperBound: 1.0,
      duration: AppDuration.instant,
    );

    final existing = ref.read(guestUsernameProvider).value;
    final initial = (existing != null && existing.isNotEmpty)
        ? existing
        : _randomUsername();
    _controller = TextEditingController(text: initial);
    _avatarSeed = initial;
  }

  @override
  void dispose() {
    _controller.dispose();
    _avatarScaleCtrl.dispose();
    super.dispose();
  }

  String get _avatarUrl => generateBotttsAvatarUrl(_avatarSeed, size: 240);

  Future<void> _randomize() async {
    await _avatarScaleCtrl.reverse();
    final name = _randomUsername();
    _controller.text = name;
    _controller.selection = TextSelection.collapsed(offset: name.length);
    setState(() => _avatarSeed = name);
    _avatarScaleCtrl.forward();
  }

  Future<void> _save() async {
    final username = _controller.text.trim();
    if (username.isEmpty) return;
    setState(() => _saving = true);
    await ref.read(guestUsernameProvider.notifier).setUsername(username);
    await ref.read(avatarSeedProvider.notifier).setAvatarSeed(_avatarSeed);
    if (!mounted) return;
    setState(() => _saving = false);
    if (widget.isInitial) {
      ref.read(guestModeProvider.notifier).enterGuestMode();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: Container(
              height: 480,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 0.6),
                  radius: 0.75,
                  colors: [
                    AppColors.primary.withValues(alpha: UIOpacity.faint),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              behavior: HitTestBehavior.translucent,
              child: OnboardingSpacedScrollBody(
                minContentHeight:
                    OnboardingLayoutSizing.guestProfileMinHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.base,
                          top: AppSpacing.sm,
                        ),
                        child: _GuestProfileBackButton(),
                      ),
                    ),
                    const Spacer(flex: 2),
                    Center(
                      child: Column(
                        children: [
                          _AvatarWidget(
                            avatarUrl: _avatarUrl,
                            scaleCtrl: _avatarScaleCtrl,
                            onRandomize: _randomize,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          Text(
                            widget.isInitial
                                ? 'What should we call you?'
                                : 'Edit your profile',
                            textAlign: TextAlign.center,
                            style: AppTextStyle.display3,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Your avatar updates as you type.\nTap the shuffle to get a new one.',
                            textAlign: TextAlign.center,
                            style: AppTextStyle.bodyBase.copyWith(
                              height: AppLineHeight.relaxed,
                              color: AppColors.textSecondary
                                  .withValues(alpha: UIOpacity.emphasis),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Username',
                            style: AppTextStyle.labelBase.copyWith(
                              color: AppColors.textSecondary
                                  .withValues(alpha: UIOpacity.high),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs + 2),
                          AppInputField(
                            controller: _controller,
                            hintText: 'e.g. NightOwl42',
                            style: InputFieldStyle.outlined,
                            onChanged: (v) => setState(
                              () => _avatarSeed =
                                  v.trim().isEmpty ? ' ' : v.trim(),
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _save(),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AppButton(
                            label: widget.isInitial ? 'Jump In' : 'Save',
                            onPressed: _save,
                            isLoading: _saving,
                            useGradient: true,
                            fullWidth: true,
                            height: UISize.buttonHeightLg,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 1),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestProfileBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: AppIcon(
          icon: AppIcons.back,
          size: UISize.iconLg,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _AvatarWidget extends StatelessWidget {
  const _AvatarWidget({
    required this.avatarUrl,
    required this.scaleCtrl,
    required this.onRandomize,
  });

  final String avatarUrl;
  final AnimationController scaleCtrl;
  final VoidCallback onRandomize;

  static const double _outerSize = 128;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _outerSize,
      height: _outerSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: scaleCtrl,
              builder: (_, __) => Transform.scale(
                scale: scaleCtrl.value,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.primary.withValues(alpha: UIOpacity.medium),
                        blurRadius: 28,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: _outerSize,
            height: _outerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: UIOpacity.emphasis),
                width: UIStroke.thin,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: scaleCtrl,
            builder: (_, child) => Transform.scale(
              scale: scaleCtrl.value,
              child: child,
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl,
                width: _outerSize,
                height: _outerSize,
                fit: BoxFit.cover,
                fadeInDuration: AppDuration.instant,
                placeholder: (_, __) => Container(
                  width: _outerSize,
                  height: _outerSize,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: _outerSize,
                  height: _outerSize,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Center(
                    child: AppIcon(
                      icon: AppIcons.person,
                      size: UISize.avatar,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRandomize,
              child: Container(
                width: UISize.iconXxl,
                height: UISize.iconXxl,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary
                          .withValues(alpha: UIOpacity.emphasis),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: AppIcon(
                    icon: AppIcons.shuffle,
                    size: UISize.iconSm,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
