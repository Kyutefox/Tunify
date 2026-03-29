import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/core/utils/username_generator.dart';
import 'package:tunify/features/auth/auth_provider.dart';
import 'package:tunify/features/settings/avatar_provider.dart';
import 'package:tunify/features/settings/guest_profile_provider.dart';
import 'package:tunify/ui/widgets/common/button.dart';
import 'package:tunify/ui/widgets/common/input_field.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

class GuestProfileSetupForm extends ConsumerStatefulWidget {
  const GuestProfileSetupForm({
    super.key,
    this.isInitial = true,
    this.onBack,
    this.onContinue,
  });

  final bool isInitial;
  final VoidCallback? onBack;
  final VoidCallback? onContinue;

  @override
  ConsumerState<GuestProfileSetupForm> createState() =>
      _GuestProfileSetupFormState();
}

class _GuestProfileSetupFormState extends ConsumerState<GuestProfileSetupForm> {
  late final TextEditingController _controller;
  late String _avatarSeed;
  bool _saving = false;

  static String _randomUsername() => UsernameGenerator.generate();

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  String get _avatarUrl => generateBotttsAvatarUrl(_avatarSeed, size: 240);

  void _randomize() {
    final name = _randomUsername();
    _controller.text = name;
    _controller.selection = TextSelection.collapsed(offset: name.length);
    setState(() => _avatarSeed = name);
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
    } else {
      widget.onContinue?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: _avatarUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 150),
                  placeholder: (_, __) => Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: AppIcon(
                      icon: AppIcons.person,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: -4,
              child: GestureDetector(
                onTap: _randomize,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColorsScheme.of(context).surfaceLight,
                    border: Border.all(
                      color: AppColors.glassBorder,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: AppIcon(
                      icon: AppIcons.shuffle,
                      color: AppColorsScheme.of(context).textPrimary,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          widget.isInitial ? 'Choose your name' : 'Edit your profile',
          style: TextStyle(
            color: AppColorsScheme.of(context).textPrimary,
            fontSize: AppFontSize.h2,
            fontWeight: FontWeight.w700,
            letterSpacing: AppLetterSpacing.heading,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Your avatar updates as you type.',
          style: TextStyle(
            color: AppColorsScheme.of(context).textMuted,
            fontSize: AppFontSize.md,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppInputField(
          controller: _controller,
          labelText: 'Username',
          hintText: 'e.g. CoolWolf123',
          style: InputFieldStyle.outlined,
          onChanged: (v) =>
              setState(() => _avatarSeed = v.trim().isEmpty ? ' ' : v.trim()),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: widget.isInitial ? 'Continue' : 'Save',
          onPressed: _save,
          isLoading: _saving,
          useGradient: true,
          fullWidth: true,
        ),
        if (widget.isInitial && widget.onBack != null) ...[
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: widget.onBack,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'Back',
                style: TextStyle(
                  color: AppColorsScheme.of(context).textMuted,
                  fontSize: AppFontSize.base,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
