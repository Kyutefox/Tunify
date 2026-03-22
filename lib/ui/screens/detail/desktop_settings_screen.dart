import 'package:flutter/material.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/screens/home/about_screen.dart';
import 'package:tunify/ui/screens/home/home_settings_sheet.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';

// ── Section enum ──────────────────────────────────────────────────────────────

enum _SettingsSection { playback, data, supabase, about }

extension _SettingsSectionX on _SettingsSection {
  String get label {
    switch (this) {
      case _SettingsSection.playback:
        return 'Playback';
      case _SettingsSection.data:
        return 'Data';
      case _SettingsSection.supabase:
        return 'Supabase';
      case _SettingsSection.about:
        return 'About';
    }
  }

  String get subtitle {
    switch (this) {
      case _SettingsSection.playback:
        return 'Volume normalization & audio';
      case _SettingsSection.data:
        return 'Cache, downloads & recommendations';
      case _SettingsSection.supabase:
        return 'Use your own project or leave default';
      case _SettingsSection.about:
        return 'Developer, version & legal info';
    }
  }

  List<List<dynamic>> get icon {
    switch (this) {
      case _SettingsSection.playback:
        return AppIcons.equalizer;
      case _SettingsSection.data:
        return AppIcons.refresh;
      case _SettingsSection.supabase:
        return AppIcons.lock;
      case _SettingsSection.about:
        return AppIcons.verified;
    }
  }

  Color get iconColor {
    switch (this) {
      case _SettingsSection.playback:
        return AppColors.accentOrange;
      case _SettingsSection.data:
        return AppColors.primary;
      case _SettingsSection.supabase:
        return AppColors.primary;
      case _SettingsSection.about:
        return AppColors.accentCyan;
    }
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

/// Desktop 2-pane settings screen pushed into the content navigator.
///
/// Left panel (220 px): settings category nav — Playback, Data, Supabase, About.
/// Right panel (Expanded): selected section body, animated on switch.
class DesktopSettingsScreen extends StatefulWidget {
  const DesktopSettingsScreen({super.key});

  @override
  State<DesktopSettingsScreen> createState() => _DesktopSettingsScreenState();
}

class _DesktopSettingsScreenState extends State<DesktopSettingsScreen> {
  _SettingsSection _selected = _SettingsSection.playback;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.base),
          child: Text(
            'Settings',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppFontSize.h2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(height: 1, color: AppColors.glassBorder),

        // ── 2-pane body ─────────────────────────────────────────────────────
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left nav
              SizedBox(
                width: 220,
                child: _SettingsNav(
                  selected: _selected,
                  onSelect: (s) => setState(() => _selected = s),
                ),
              ),
              Container(width: 1, color: AppColors.glassBorder),

              // Right content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: _buildBody(_selected),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(_SettingsSection section) {
    switch (section) {
      case _SettingsSection.playback:
        return const PlaybackSettingsBody(key: ValueKey('playback'));
      case _SettingsSection.data:
        return const DataSettingsBody(key: ValueKey('data'));
      case _SettingsSection.supabase:
        return const SupabaseSettingsBody(key: ValueKey('supabase'));
      case _SettingsSection.about:
        return const AboutScreenBody(key: ValueKey('about'));
    }
  }
}

// ── Left nav panel ────────────────────────────────────────────────────────────

class _SettingsNav extends StatelessWidget {
  const _SettingsNav({required this.selected, required this.onSelect});

  final _SettingsSection selected;
  final ValueChanged<_SettingsSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      children: _SettingsSection.values
          .map((s) => _NavItem(
                section: s,
                isActive: s == selected,
                onTap: () => onSelect(s),
              ))
          .toList(),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.section,
    required this.isActive,
    required this.onTap,
  });

  final _SettingsSection section;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelColor =
        isActive ? AppColors.primary : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                AppIcon(
                  icon: section.icon,
                  size: 18,
                  color: isActive ? section.iconColor : AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.label,
                        style: TextStyle(
                          color: labelColor,
                          fontSize: AppFontSize.base,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                      Text(
                        section.subtitle,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: AppFontSize.xs,
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
