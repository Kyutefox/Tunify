import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_icons.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/guest_profile_provider.dart';
import '../components/ui/button.dart';
import '../components/ui/input_field.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

class GuestProfileSetupScreen extends ConsumerStatefulWidget {
  const GuestProfileSetupScreen({super.key, this.isInitial = true});

  /// True when entering guest mode for the first time; false when editing.
  final bool isInitial;

  @override
  ConsumerState<GuestProfileSetupScreen> createState() =>
      _GuestProfileSetupScreenState();
}

class _GuestProfileSetupScreenState
    extends ConsumerState<GuestProfileSetupScreen> {
  late final TextEditingController _controller;
  late String _avatarSeed;
  bool _saving = false;

  static const _adjectives = [
    'Cool', 'Happy', 'Swift', 'Brave', 'Chill', 'Wild', 'Neon', 'Cosmic',
    'Lucky', 'Epic', 'Mystic', 'Solar', 'Lunar', 'Frost', 'Storm',
  ];
  static const _nouns = [
    'Wolf', 'Dragon', 'Fox', 'Bear', 'Tiger', 'Panda', 'Hawk', 'Lynx',
    'Raven', 'Phoenix', 'Comet', 'Ember', 'Blaze', 'Echo', 'Sage',
  ];

  static String _randomUsername() {
    final r = Random();
    return '${_adjectives[r.nextInt(_adjectives.length)]}'
        '${_nouns[r.nextInt(_nouns.length)]}'
        '${r.nextInt(900) + 100}';
  }

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

  String get _avatarUrl =>
      'https://api.dicebear.com/9.x/fun-emoji/png?seed=${Uri.encodeComponent(_avatarSeed)}&size=240';

  void _randomize() {
    final name = _randomUsername();
    _controller.text = name;
    _controller.selection =
        TextSelection.collapsed(offset: name.length);
    setState(() => _avatarSeed = name);
  }

  Future<void> _save() async {
    final username = _controller.text.trim();
    if (username.isEmpty) return;
    setState(() => _saving = true);
    await ref.read(guestUsernameProvider.notifier).setUsername(username);
    if (!mounted) return;
    setState(() => _saving = false);
    if (widget.isInitial) {
      ref.read(guestModeProvider.notifier).enterGuestMode();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle green radial glow
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.5),
                  radius: 1.0,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Back button (edit mode only)
                if (!widget.isInitial)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: AppSpacing.sm, top: AppSpacing.sm),
                      child: AppIconButton(
                        icon: AppIcon(
                            icon: AppIcons.back,
                            color: AppColors.textPrimary,
                            size: 22),
                        onPressed: () => Navigator.of(context).pop(),
                        style: AppIconButtonStyle.ghost,
                      ),
                    ),
                  ),

                const Spacer(),

                // Avatar with random button
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
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
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 150),
                          placeholder: (_, __) => Container(
                            width: 120,
                            height: 120,
                            decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradient,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: 120,
                            height: 120,
                            decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradient,
                            ),
                            child: AppIcon(
                              icon: AppIcons.person,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Random button — bottom right of avatar
                    Positioned(
                      bottom: 0,
                      right: -4,
                      child: GestureDetector(
                        onTap: _randomize,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceLight,
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
                              color: AppColors.textPrimary,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                Text(
                  widget.isInitial ? 'Choose your name' : 'Edit your profile',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                const Text(
                  'Your avatar updates as you type.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),

                const Spacer(),

                // Username field + button
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl),
                  child: Column(
                    children: [
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
                      if (widget.isInitial) ...[
                        const SizedBox(height: AppSpacing.md),
                        GestureDetector(
                          onTap: () =>
                              Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.sm),
                            child: Text(
                              'Back',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
