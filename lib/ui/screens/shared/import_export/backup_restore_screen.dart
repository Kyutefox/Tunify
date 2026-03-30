import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/features/import_export/backup_service.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/widgets/common/back_title_app_bar.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _backupBusy = false;
  bool _restoreBusy = false;

  Future<void> _doBackup() async {
    setState(() => _backupBusy = true);
    final result =
        await ref.read(backupServiceProvider).createBackup();
    if (!mounted) return;
    setState(() => _backupBusy = false);
    _showSnack(result.isSuccess ? result.message! : result.error!,
        isError: !result.isSuccess);
  }

  Future<void> _doRestore() async {
    final confirmed = await _confirmDialog(
      title: 'Restore Backup?',
      body:
          'This will overwrite your current library with the data from the backup file. This cannot be undone.',
      confirmLabel: 'Restore',
    );
    if (!confirmed) return;
    setState(() => _restoreBusy = true);
    final result =
        await ref.read(backupServiceProvider).restoreBackup();
    if (!mounted) return;
    setState(() => _restoreBusy = false);
    _showSnack(result.isSuccess ? result.message! : result.error!,
        isError: !result.isSuccess);
  }

  Future<bool> _confirmDialog({
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColorsScheme.of(context).surfaceLight,
        title: Text(
          title,
          style: TextStyle(
            color: AppColorsScheme.of(context).textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          body,
          style: TextStyle(color: AppColorsScheme.of(context).textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(
                    color: AppColorsScheme.of(context).textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel,
                style: const TextStyle(color: AppColors.accentRed)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? AppColors.accentRed.withValues(alpha: 0.85) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsScheme.of(context).background,
      appBar: const BackTitleAppBar(title: 'Backup & Restore'),
      body: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base, vertical: AppSpacing.lg),
        children: [
          _SectionHeader(
            icon: AppIcons.fileExport,
            iconColor: AppColors.primary,
            title: 'Backup',
            description:
                'Export your entire library — playlists, liked songs, followed artists, albums, listening history and settings — to a single JSON file you can save anywhere.',
          ),
          const SizedBox(height: AppSpacing.md),
          _ActionTile(
            icon: AppIcons.fileExport,
            iconColor: AppColors.primary,
            title: 'Create Backup',
            subtitle: 'Save a full snapshot of your library',
            busy: _backupBusy,
            onTap: _doBackup,
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader(
            icon: AppIcons.refresh,
            iconColor: AppColors.accentOrange,
            title: 'Restore',
            description:
                'Load a previously exported backup file. Your current library data will be replaced with the backup contents.',
          ),
          const SizedBox(height: AppSpacing.md),
          _ActionTile(
            icon: AppIcons.refresh,
            iconColor: AppColors.accentOrange,
            title: 'Restore from Backup',
            subtitle: 'Pick a .json backup file to restore',
            busy: _restoreBusy,
            onTap: _doRestore,
          ),
          const SizedBox(height: AppSpacing.xl),
          _InfoBox(
            children: [
              _infoLine(context, 'Backup includes playlists, liked songs, followed artists & albums, listening history and recent searches.'),
              _infoLine(context, 'Downloads and stream cache are not included in the backup.'),
              _infoLine(context, 'After restoring, restart the app to see all changes reflected.'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoLine(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ',
                style: TextStyle(
                    color: AppColorsScheme.of(context).textMuted,
                    fontSize: AppFontSize.md)),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                    color: AppColorsScheme.of(context).textMuted,
                    fontSize: AppFontSize.md,
                    height: 1.5),
              ),
            ),
          ],
        ),
      );
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final List<List<dynamic>> icon;
  final Color iconColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Center(
            child: AppIcon(icon: icon, color: iconColor, size: 20),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColorsScheme.of(context).textPrimary,
                  fontSize: AppFontSize.xl,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: AppColorsScheme.of(context).textSecondary,
                  fontSize: AppFontSize.md,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.busy,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: AppColorsScheme.of(context).surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
                color: AppColorsScheme.of(context).surfaceHighlight, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: busy
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(iconColor),
                          ),
                        )
                      : AppIcon(icon: icon, color: iconColor, size: 22),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textPrimary,
                        fontSize: AppFontSize.lg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      busy ? 'Working…' : subtitle,
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textMuted,
                        fontSize: AppFontSize.sm,
                      ),
                    ),
                  ],
                ),
              ),
              if (!busy)
                AppIcon(
                  icon: AppIcons.chevronRight,
                  color: AppColorsScheme.of(context).textMuted,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColorsScheme.of(context).surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: AppColorsScheme.of(context).surfaceHighlight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s included',
            style: TextStyle(
              color: AppColorsScheme.of(context).textPrimary,
              fontSize: AppFontSize.md,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}
