import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tunify/core/utils/app_log.dart';

import 'package:tunify/ui/widgets/common/sheet.dart';
import 'package:tunify/ui/widgets/common/back_title_app_bar.dart';
import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/features/library/collection_track_cache.dart';
import 'package:tunify/features/settings/content_settings_provider.dart';
import 'package:tunify/features/downloads/download_provider.dart';
import 'package:tunify/features/home/home_state_provider.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/features/search/recent_search_provider.dart';
import 'package:tunify/features/settings/music_stream_manager.dart';
import 'package:tunify/features/settings/stream_cache_service.dart';
import 'package:tunify/features/settings/theme_provider.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_routes.dart';
import 'about_screen.dart';
import 'package:tunify/ui/screens/shared/import_export/backup_restore_screen.dart';
import 'package:tunify/ui/screens/shared/import_export/import_export_screen.dart';
import 'package:tunify/ui/widgets/common/sheet_drag_handle.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

void _showDataResultSnackBar(BuildContext context,
    {String? success, Object? error}) {
  if (success != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success), behavior: SnackBarBehavior.floating),
    );
  } else if (error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Failed: $error'), behavior: SnackBarBehavior.floating),
    );
  }
}

class HomeSettingsSheet extends ConsumerWidget {
  const HomeSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isLight = themeMode == ThemeMode.light;
    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      child: Container(
        color: AppColorsScheme.of(context).surface,
        padding: EdgeInsets.only(
          left: kSheetHorizontalPadding,
          right: kSheetHorizontalPadding,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetDragHandle(),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 0),
              child: Text(
                'Settings',
                style: TextStyle(
                  color: AppColorsScheme.of(context).textPrimary,
                  fontSize: AppFontSize.h2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _ThemeToggleCard(
              isLight: isLight,
              onToggle: () => ref.read(themeProvider.notifier).toggleTheme(),
            ),
            const SizedBox(height: AppSpacing.md),
            _SettingsCard(
              icon: AppIcons.equalizer,
              iconColor: AppColors.accentOrange,
              iconBgColor: AppColors.accentOrange.withValues(alpha: 0.2),
              title: 'Playback',
              subtitle: 'Volume Normalization & Audio',
              onTap: () {
                Navigator.of(context).push(
                  appPageRoute<void>(
                    builder: (_) => const _PlaybackSettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _SettingsCard(
              icon: AppIcons.refresh,
              iconColor: AppColors.primary,
              iconBgColor: AppColors.primary.withValues(alpha: 0.2),
              title: 'Data',
              subtitle: 'Clear Cache, Clear Downloads, Reset Recommendations',
              onTap: () {
                Navigator.of(context).push(
                  appPageRoute<void>(
                    builder: (_) => const _DataSettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _SettingsCard(
              icon: AppIcons.fileExport,
              iconColor: AppColors.accentCyan,
              iconBgColor: AppColors.accentCyan.withValues(alpha: 0.15),
              title: 'Backup & Restore',
              subtitle: 'Export or restore your entire library',
              onTap: () {
                Navigator.of(context).push(
                  appPageRoute<void>(
                    builder: (_) => const BackupRestoreScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _SettingsCard(
              icon: AppIcons.playlistAdd,
              iconColor: AppColors.accentOrange,
              iconBgColor: AppColors.accentOrange.withValues(alpha: 0.2),
              title: 'Import & Export',
              subtitle: 'Import M3U / JSON playlists or export yours',
              onTap: () {
                Navigator.of(context).push(
                  appPageRoute<void>(
                    builder: (_) => const ImportExportScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _SettingsCard(
              icon: AppIcons.verified,
              iconColor: AppColors.accentCyan,
              iconBgColor: AppColors.accentCyan.withValues(alpha: 0.15),
              title: 'About',
              subtitle: 'Developer, version & legal info',
              onTap: () {
                Navigator.of(context).push(
                  appPageRoute<void>(
                    builder: (_) => const AboutScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggleCard extends StatelessWidget {
  const _ThemeToggleCard({required this.isLight, required this.onToggle});

  final bool isLight;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: AppColorsScheme.of(context).surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColorsScheme.of(context).surfaceHighlight,
              width: UIStroke.thin,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: UISize.iconHero,
                height: UISize.iconHero,
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: AppIcon(
                    icon: isLight ? AppIcons.sun : AppIcons.moon,
                    color: AppColors.accentCyan,
                    size: UISize.iconXl,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance',
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textPrimary,
                        fontSize: AppFontSize.xxl,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs / 2),
                    Text(
                      isLight ? 'Light theme' : 'Dark theme',
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textSecondary,
                        fontSize: AppFontSize.md,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isLight,
                onChanged: (_) => onToggle(),
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                inactiveThumbColor: AppColorsScheme.of(context).textMuted,
                inactiveTrackColor:
                    AppColorsScheme.of(context).surfaceHighlight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: AppColorsScheme.of(context).surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColorsScheme.of(context).surfaceHighlight,
              width: UIStroke.thin,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: UISize.iconHero,
                height: UISize.iconHero,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: AppIcon(
                      icon: icon, color: iconColor, size: UISize.iconXl),
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textPrimary,
                        fontSize: AppFontSize.xxl,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs / 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textSecondary,
                        fontSize: AppFontSize.md,
                      ),
                    ),
                  ],
                ),
              ),
              AppIcon(
                  icon: AppIcons.chevronRight,
                  color: AppColorsScheme.of(context).textMuted,
                  size: AppFontSize.h2),
            ],
          ),
        ),
      ),
    );
  }
}

class _CrossfadeTile extends StatelessWidget {
  const _CrossfadeTile({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(
                  icon: AppIcons.refresh,
                  color: AppColorsScheme.of(context).textSecondary,
                  size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crossfade',
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textPrimary,
                        fontSize: AppFontSize.lg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      value == 0 ? 'Off' : '$value seconds',
                      style: TextStyle(
                          color: AppColorsScheme.of(context).textMuted,
                          fontSize: AppFontSize.sm),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColorsScheme.of(context).surfaceLight,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.12),
              trackHeight: UIStroke.base + UIStroke.base + UIStroke.hairline,
              thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: AppSpacing.sm - UIStroke.thin),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: AppSpacing.base),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 12,
              divisions: 12,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}

class _BassBoostTile extends StatelessWidget {
  const _BassBoostTile({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  String get _label {
    if (value == 0.0) return 'Off';
    if (value <= 0.33) return 'Low';
    if (value <= 0.66) return 'Medium';
    return 'High';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(
                  icon: AppIcons.equalizer,
                  color: AppColorsScheme.of(context).textSecondary,
                  size: AppFontSize.h2),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bass Boost',
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textPrimary,
                        fontSize: AppFontSize.lg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _label,
                      style: TextStyle(
                          color: AppColorsScheme.of(context).textMuted,
                          fontSize: AppFontSize.sm),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColorsScheme.of(context).surfaceLight,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.12),
              trackHeight: UIStroke.base + UIStroke.base + UIStroke.hairline,
              thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: AppSpacing.sm - UIStroke.thin),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: AppSpacing.base),
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data Settings ─────────────────────────────────────────────────────────────

/// Body-only widget for Data settings — no Scaffold wrapper.
/// Used directly in the desktop 2-pane settings screen and wrapped in a
/// Scaffold by [_DataSettingsScreen] on mobile.
class DataSettingsBody extends ConsumerWidget {
  const DataSettingsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.sm),
      children: [
        _DataTile(
          icon: AppIcons.devices,
          label: 'Cache Size',
          subtitle: 'View stream cache usage',
          onTap: () => _dataCacheStats(context, ref),
        ),
        _DataTile(
          icon: AppIcons.clear,
          label: 'Clear Cache',
          subtitle: 'Stream and playback cache',
          onTap: () => _dataClearCache(context, ref),
        ),
        _DataTile(
          icon: AppIcons.refresh,
          label: 'Clear Old Cache',
          subtitle: 'Remove cache files older than 7 days',
          onTap: () => _dataClearOldCache(context, ref),
        ),
        _DataTile(
          icon: AppIcons.download,
          label: 'Clear Downloads',
          subtitle: 'Remove all downloaded songs from device',
          onTap: () => _dataClearDownloads(context, ref),
        ),
        _DataTile(
          icon: AppIcons.refresh,
          label: 'Reset Recommendations',
          subtitle: 'Clear personalization; home feed will refresh',
          onTap: () => _dataResetRecommendations(context, ref),
        ),
        _DataTile(
          icon: AppIcons.search,
          label: 'Clear recent search',
          subtitle: 'Remove all recent search queries',
          onTap: () => _dataClearRecentSearch(context, ref),
        ),
      ],
    );
  }
}

class _DataSettingsScreen extends StatelessWidget {
  const _DataSettingsScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColorsScheme.of(context).background,
        appBar: const BackTitleAppBar(title: 'Data'),
        body: const DataSettingsBody(),
      );
}

class _DataTile extends StatelessWidget {
  const _DataTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              AppIcon(
                  icon: icon,
                  color: AppColorsScheme.of(context).textSecondary,
                  size: AppFontSize.h2),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textPrimary,
                        fontSize: AppFontSize.lg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                          color: AppColorsScheme.of(context).textMuted,
                          fontSize: AppFontSize.sm),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _dataCacheStats(BuildContext context, WidgetRef ref) async {
  try {
    final cacheService = StreamCacheService();
    final stats = await cacheService.getCacheStats();
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColorsScheme.of(context).surfaceLight,
          title: const Text('Cache Statistics'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total size: ${stats.formattedSize}'),
              const SizedBox(height: 8),
              Text('Files: ${stats.fileCount}'),
              const SizedBox(height: 8),
              Text('Old files (>7 days): ${stats.oldFilesCount}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    logError('Failed to get cache stats: $e', tag: 'Settings');
    if (context.mounted) {
      _showDataResultSnackBar(context, error: e);
    }
  }
}

Future<void> _dataClearCache(BuildContext context, WidgetRef ref) async {
  try {
    ref.read(streamManagerProvider).clearCache();
    CollectionTrackCache.instance.clear();
    await ref.read(playerProvider.notifier).clearPersistentStreamCache();
    if (context.mounted) {
      _showDataResultSnackBar(context, success: 'Cache cleared');
    }
  } catch (e) {
    if (context.mounted) {
      _showDataResultSnackBar(context, error: e);
    }
  }
}

Future<void> _dataClearOldCache(BuildContext context, WidgetRef ref) async {
  try {
    final cacheService = StreamCacheService();
    await cacheService.clearCacheOlderThan(const Duration(days: 7));
    if (context.mounted) {
      _showDataResultSnackBar(context, success: 'Old cache files cleared');
    }
  } catch (e) {
    logError('Failed to clear old cache: $e', tag: 'Settings');
    if (context.mounted) {
      _showDataResultSnackBar(context, error: e);
    }
  }
}

Future<void> _dataClearDownloads(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(downloadServiceProvider).clearAllDownloads();
    if (context.mounted) {
      _showDataResultSnackBar(context, success: 'Downloads cleared');
    }
  } catch (e) {
    if (context.mounted) {
      _showDataResultSnackBar(context, error: e);
    }
  }
}

Future<void> _dataResetRecommendations(
    BuildContext context, WidgetRef ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kYtVisitorDataKey);
    ref.read(streamManagerProvider).setVisitorData(null);
    ref.invalidate(homeProvider);
    if (context.mounted) {
      _showDataResultSnackBar(
        context,
        success: 'Recommendations reset. Home will refresh.',
      );
    }
  } catch (e) {
    if (context.mounted) {
      _showDataResultSnackBar(context, error: e);
    }
  }
}

Future<void> _dataClearRecentSearch(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(recentSearchProvider.notifier).clearAll();
    if (context.mounted) {
      _showDataResultSnackBar(context, success: 'Recent search cleared');
    }
  } catch (e) {
    if (context.mounted) {
      _showDataResultSnackBar(context, error: e);
    }
  }
}

// ── Playback Settings ─────────────────────────────────────────────────────────

/// Body-only widget for Playback settings — no Scaffold wrapper.
/// Used directly in the desktop 2-pane settings screen and wrapped in a
/// Scaffold by [_PlaybackSettingsScreen] on mobile.
class PlaybackSettingsBody extends ConsumerWidget {
  const PlaybackSettingsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normEnabled =
        ref.watch(playerProvider.select((s) => s.isNormalizationEnabled));
    final isGaplessEnabled =
        ref.watch(playerProvider.select((s) => s.isGaplessEnabled));
    final crossfadeDuration =
        ref.watch(playerProvider.select((s) => s.crossfadeDurationSeconds));
    final bassBoost = ref.watch(playerProvider.select((s) => s.bassBoostLevel));
    final showExplicit = ref.watch(showExplicitContentProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.sm),
      children: [
        _PlaybackToggleTile(
          icon: AppIcons.equalizer,
          label: 'Volume normalization',
          subtitle: 'Set the same volume level for all songs',
          value: normEnabled,
          onChanged: (v) =>
              ref.read(playerProvider.notifier).setNormalization(v),
        ),
        _PlaybackToggleTile(
          icon: AppIcons.musicNote,
          label: 'Show Explicit Content',
          subtitle: 'Show songs tagged with "E" in lists',
          value: showExplicit,
          onChanged: (v) =>
              ref.read(showExplicitContentProvider.notifier).setShowExplicit(v),
        ),
        _PlaybackToggleTile(
          icon: AppIcons.musicNote,
          label: 'Gapless Playback',
          subtitle: 'Remove silence between tracks',
          value: isGaplessEnabled,
          onChanged: (v) =>
              ref.read(playerProvider.notifier).setGaplessPlayback(v),
        ),
        _CrossfadeTile(
          value: crossfadeDuration,
          onChanged: (v) =>
              ref.read(playerProvider.notifier).setCrossfadeDuration(v),
        ),
        _BassBoostTile(
          value: bassBoost,
          onChanged: (v) => ref.read(playerProvider.notifier).setBassBoost(v),
        ),
      ],
    );
  }
}

class _PlaybackSettingsScreen extends StatelessWidget {
  const _PlaybackSettingsScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColorsScheme.of(context).background,
        appBar: const BackTitleAppBar(title: 'Playback'),
        body: const PlaybackSettingsBody(),
      );
}

class _PlaybackToggleTile extends StatelessWidget {
  const _PlaybackToggleTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          AppIcon(
              icon: icon,
              color: AppColorsScheme.of(context).textSecondary,
              size: AppFontSize.h2),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColorsScheme.of(context).textPrimary,
                    fontSize: AppFontSize.lg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                      color: AppColorsScheme.of(context).textMuted,
                      fontSize: AppFontSize.sm),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
