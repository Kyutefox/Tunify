import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tunify_logger/tunify_logger.dart';

import 'package:tunify/ui/widgets/button.dart';
import 'package:tunify/ui/widgets/sheet.dart';
import 'package:tunify/ui/widgets/back_title_app_bar.dart';
import 'package:tunify/ui/widgets/input_field.dart';
import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/databases/supabase/supabase_prefs.dart';
import 'package:tunify/features/auth/auth_provider.dart';
import 'package:tunify/features/settings/content_settings_provider.dart';
import 'package:tunify/features/downloads/download_provider.dart';
import 'package:tunify/features/home/home_state_provider.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/features/search/recent_search_provider.dart';
import 'package:tunify/features/settings/music_stream_manager.dart';
import 'package:tunify/features/settings/stream_cache_service.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_routes.dart';
import 'about_screen.dart';
import 'package:tunify/ui/widgets/sheet_drag_handle.dart';

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
    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      child: Container(
        color: AppColors.surface,
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 0),
              child: Text(
                'Settings',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppFontSize.h2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
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
              icon: AppIcons.lock,
              iconColor: AppColors.primary,
              iconBgColor: AppColors.primary.withValues(alpha: 0.2),
              title: 'Supabase',
              subtitle: 'Use your own project or leave default',
              onTap: () {
                Navigator.of(context).push(
                  appPageRoute<void>(
                    builder: (_) => const _SupabaseSettingsScreen(),
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
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: AppIcon(icon: icon, color: iconColor, size: 26),
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: AppFontSize.xxl,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppFontSize.md,
                      ),
                    ),
                  ],
                ),
              ),
              AppIcon(
                  icon: AppIcons.chevronRight,
                  color: AppColors.textMuted,
                  size: 22),
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
                  color: AppColors.textSecondary,
                  size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Crossfade',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: AppFontSize.lg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      value == 0 ? 'Off' : '$value seconds',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: AppFontSize.sm),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.12),
              trackHeight: 3,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 16),
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
        backgroundColor: AppColors.background,
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
              AppIcon(icon: icon, color: AppColors.textSecondary, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: AppFontSize.lg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: AppFontSize.sm),
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
          backgroundColor: AppColors.surfaceLight,
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

Future<void> _dataClearRecentSearch(
    BuildContext context, WidgetRef ref) async {
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
    final playerState = ref.watch(playerProvider);
    final normEnabled = playerState.isNormalizationEnabled;
    final showExplicit = ref.watch(showExplicitContentProvider);
    final smartRecShuffle = ref.watch(smartRecommendationShuffleProvider);

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
          onChanged: (v) => ref
              .read(showExplicitContentProvider.notifier)
              .setShowExplicit(v),
        ),
        _PlaybackToggleTile(
          icon: AppIcons.shuffle,
          label: 'Smart Recommendation Shuffle',
          subtitle:
              'When queue has one song from a playlist or library, fill with recommendations only if shuffle is on',
          value: smartRecShuffle,
          onChanged: (v) => ref
              .read(smartRecommendationShuffleProvider.notifier)
              .setSmartRecommendationShuffle(v),
        ),
        _PlaybackToggleTile(
          icon: AppIcons.musicNote,
          label: 'Gapless Playback',
          subtitle: 'Remove silence between tracks',
          value: playerState.isGaplessEnabled,
          onChanged: (v) =>
              ref.read(playerProvider.notifier).setGaplessPlayback(v),
        ),
        _CrossfadeTile(
          value: playerState.crossfadeDurationSeconds,
          onChanged: (v) =>
              ref.read(playerProvider.notifier).setCrossfadeDuration(v),
        ),
      ],
    );
  }
}

class _PlaybackSettingsScreen extends StatelessWidget {
  const _PlaybackSettingsScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
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
          AppIcon(icon: icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppFontSize.lg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: AppFontSize.sm),
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

// ── Supabase Settings ─────────────────────────────────────────────────────────

/// Body-only widget for Supabase settings — no Scaffold wrapper.
/// Used directly in the desktop 2-pane settings screen and wrapped in a
/// Scaffold by [_SupabaseSettingsScreen] on mobile.
class SupabaseSettingsBody extends ConsumerStatefulWidget {
  const SupabaseSettingsBody({super.key});

  @override
  ConsumerState<SupabaseSettingsBody> createState() =>
      _SupabaseSettingsBodyState();
}

class _SupabaseSettingsBodyState extends ConsumerState<SupabaseSettingsBody> {
  final _urlController = TextEditingController();
  final _anonKeyController = TextEditingController();
  bool _testing = false;
  bool _saving = false;
  bool _usingCustomConfig = false;

  @override
  void initState() {
    super.initState();
    _loadUsingCustom();
  }

  Future<void> _loadUsingCustom() async {
    final custom = await hasCustomSupabaseConfig();
    if (!mounted) return;
    setState(() => _usingCustomConfig = custom);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _anonKeyController.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    final url = _urlController.text.trim();
    final key = _anonKeyController.text.trim();
    if (url.isEmpty || key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter URL and anon key to test'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _testing = true);
    final ok = await testSupabaseConnection(url, key);
    if (!mounted) return;
    setState(() => _testing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Connection successful' : 'Connection failed'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? null : AppColors.accentRed.withValues(alpha: 0.8),
      ),
    );
  }

  Future<void> _save() async {
    final url = _urlController.text.trim();
    final key = _anonKeyController.text.trim();

    if (url.isEmpty && key.isEmpty) {
      await clearSupabaseConfig();
      setState(() => _usingCustomConfig = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Using default config. Restart app to apply.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (url.isEmpty || key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Enter both URL and anon key, or clear both for default.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final ok = await testSupabaseConnection(url, key);
    if (!mounted) return;
    if (!ok) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection failed. Fix credentials and try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }
    await saveSupabaseConfig(url, key);
    await _fullReset();
  }

  Future<void> _fullReset() async {
    // Sign out Supabase session
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}

    // Exit guest mode
    try {
      await ref.read(guestModeProvider.notifier).exitGuestMode();
    } catch (_) {}

    // Clear in-memory stream cache and YT visitor data
    try {
      ref.read(streamManagerProvider).clearCache();
      ref.read(streamManagerProvider).setVisitorData(null);
    } catch (_) {}

    // Clear player persistent stream cache
    try {
      await ref.read(playerProvider.notifier).clearPersistentStreamCache();
    } catch (_) {}

    // Delete stream cache files
    try {
      await StreamCacheService().clearAllCache();
    } catch (_) {}

    // Delete downloaded audio files and clear downloads DB
    try {
      await ref.read(downloadServiceProvider).clearAllDownloads();
    } catch (_) {}

    // Delete SQLite databases (deleteDatabase closes connections before deleting)
    try {
      final dir = await getApplicationDocumentsDirectory();
      await deleteDatabase(p.join(dir.path, 'tunify_primary.db'));
      await deleteDatabase(p.join(dir.path, 'downloads.db'));
    } catch (e) {
      logWarning('Factory reset: failed to delete databases: $e', tag: 'Settings');
    }

    // Clear all SharedPreferences except Supabase credentials
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('supabase_custom_url');
      final savedKey = prefs.getString('supabase_custom_anon_key');
      await prefs.clear();
      if (savedUrl != null) await prefs.setString('supabase_custom_url', savedUrl);
      if (savedKey != null) await prefs.setString('supabase_custom_anon_key', savedKey);
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data cleared. Closing app…'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
    }

    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: kSheetHorizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _usingCustomConfig
                ? 'Currently using your Supabase config'
                : 'Currently using default config',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: AppFontSize.md,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Leave URL and anon key empty to use the default config. Enter both to use your own project.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppFontSize.md,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppInputField(
            controller: _urlController,
            labelText: 'URL',
            hintText: 'Empty = use default',
            style: InputFieldStyle.outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          AppInputField(
            controller: _anonKeyController,
            labelText: 'Anon key',
            hintText: 'Empty = use default',
            style: InputFieldStyle.outlined,
            obscureText: true,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: _testing ? 'Testing…' : 'Test',
                  icon: AppIcon(
                    icon: AppIcons.check,
                    size: 18,
                    color: Colors.white,
                  ),
                  onPressed: _test,
                  isLoading: _testing,
                  fullWidth: true,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: 'Save',
                  icon: AppIcon(
                    icon: AppIcons.check,
                    size: 18,
                    color: Colors.white,
                  ),
                  onPressed: _save,
                  isLoading: _saving,
                  fullWidth: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SupabaseSettingsScreen extends StatelessWidget {
  const _SupabaseSettingsScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: const BackTitleAppBar(title: 'Supabase'),
        body: const SupabaseSettingsBody(),
      );
}
