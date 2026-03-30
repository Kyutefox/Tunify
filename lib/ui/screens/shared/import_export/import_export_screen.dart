import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/library_playlist.dart';
import 'package:tunify/features/import_export/playlist_io_service.dart';
import 'package:tunify/features/library/library_provider.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/widgets/common/back_title_app_bar.dart';
import 'package:tunify/ui/widgets/common/sheet.dart' show kSheetHorizontalPadding, AppSheet;

class ImportExportScreen extends ConsumerStatefulWidget {
  const ImportExportScreen({super.key});

  @override
  ConsumerState<ImportExportScreen> createState() =>
      _ImportExportScreenState();
}

class _ImportExportScreenState extends ConsumerState<ImportExportScreen> {
  bool _importBusy = false;
  bool _exportAllBusy = false;
  bool _exportSelectiveBusy = false;

  // ── Import ───────────────────────────────────────────────────────────────────

  Future<void> _doImport() async {
    setState(() => _importBusy = true);
    final service = ref.read(playlistIOServiceProvider);
    final (:result, :playlists) = await service.pickAndParse();

    if (!mounted) return;

    if (!result.isSuccess || playlists.isEmpty) {
      setState(() => _importBusy = false);
      _showSnack(result.error ?? 'No playlists found in file', isError: true);
      return;
    }

    // Show preview sheet before saving.
    final confirmed = await _showImportPreview(playlists);
    if (!mounted) return;

    if (!confirmed) {
      setState(() => _importBusy = false);
      return;
    }

    final saveResult = await service.saveImportedPlaylists(
      playlists,
      ref.read(libraryProvider.notifier),
    );
    if (!mounted) return;
    setState(() => _importBusy = false);
    _showSnack(
      saveResult.isSuccess ? saveResult.message! : saveResult.error!,
      isError: !saveResult.isSuccess,
    );
  }

  Future<bool> _showImportPreview(List<ParsedPlaylist> playlists) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => AppSheet(
        child: _ImportPreviewSheet(playlists: playlists),
      ),
    );
    return result ?? false;
  }

  // ── Export ───────────────────────────────────────────────────────────────────

  Future<void> _doExportAll(PlaylistExportFormat format) async {
    setState(() => _exportAllBusy = true);
    final allPlaylists = ref
        .read(libraryProvider)
        .playlists
        .where((p) => p.id != 'liked' && !p.isImported)
        .toList();

    if (allPlaylists.isEmpty) {
      setState(() => _exportAllBusy = false);
      _showSnack('No local playlists to export', isError: true);
      return;
    }

    final result = await ref
        .read(playlistIOServiceProvider)
        .exportPlaylists(allPlaylists, format);
    if (!mounted) return;
    setState(() => _exportAllBusy = false);
    _showSnack(result.isSuccess ? result.message! : result.error!,
        isError: !result.isSuccess);
  }

  Future<void> _doExportSelective() async {
    final allPlaylists = ref
        .read(libraryProvider)
        .playlists
        .where((p) => p.id != 'liked' && !p.isImported)
        .toList();

    if (allPlaylists.isEmpty) {
      _showSnack('No local playlists to export', isError: true);
      return;
    }

    final selected = await _showPlaylistPicker(allPlaylists);
    if (!mounted || selected == null || selected.isEmpty) return;

    final format = await _showFormatPicker();
    if (!mounted || format == null) return;

    setState(() => _exportSelectiveBusy = true);
    final result = await ref
        .read(playlistIOServiceProvider)
        .exportPlaylists(selected, format);
    if (!mounted) return;
    setState(() => _exportSelectiveBusy = false);
    _showSnack(result.isSuccess ? result.message! : result.error!,
        isError: !result.isSuccess);
  }

  Future<List<LibraryPlaylist>?> _showPlaylistPicker(
      List<LibraryPlaylist> playlists) async {
    return showModalBottomSheet<List<LibraryPlaylist>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => AppSheet(
        child: _PlaylistPickerSheet(playlists: playlists),
      ),
    );
  }

  Future<PlaylistExportFormat?> _showFormatPicker() async {
    return showModalBottomSheet<PlaylistExportFormat>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => const AppSheet(
        child: _FormatPickerSheet(),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

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

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsScheme.of(context).background,
      appBar: const BackTitleAppBar(title: 'Import & Export'),
      body: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base, vertical: AppSpacing.lg),
        children: [
          // ── Import section ──────────────────────────────────────────────────
          _SectionTitle(
            icon: AppIcons.download,
            iconColor: AppColors.accentCyan,
            label: 'Import',
          ),
          const SizedBox(height: AppSpacing.md),
          _ActionTile(
            icon: AppIcons.musicNote,
            iconColor: AppColors.accentCyan,
            title: 'Import Playlist',
            subtitle: 'From M3U / M3U8 or Tunify JSON file',
            busy: _importBusy,
            onTap: _doImport,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FormatChips(
            labels: const ['M3U / M3U8', 'Tunify JSON'],
            colors: [AppColors.accentCyan, AppColors.primary],
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Export section ──────────────────────────────────────────────────
          _SectionTitle(
            icon: AppIcons.download,
            iconColor: AppColors.accentOrange,
            label: 'Export',
          ),
          const SizedBox(height: AppSpacing.md),
          _ActionTile(
            icon: AppIcons.download,
            iconColor: AppColors.accentOrange,
            title: 'Export All Playlists',
            subtitle: 'Export every local playlist at once',
            busy: _exportAllBusy,
            onTap: () async {
              final format = await _showFormatPicker();
              if (format != null) _doExportAll(format);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _ActionTile(
            icon: AppIcons.playlistAdd,
            iconColor: AppColors.primary,
            title: 'Export Selected Playlists',
            subtitle: 'Choose which playlists to export',
            busy: _exportSelectiveBusy,
            onTap: _doExportSelective,
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Info box ────────────────────────────────────────────────────────
          _InfoBox(children: [
            _infoLine(context,
                'M3U format is compatible with VLC, Winamp, and most music players.'),
            _infoLine(context,
                'JSON format preserves all Tunify metadata including YouTube track IDs.'),
            _infoLine(context,
                'Imported playlists with YouTube track IDs can be played directly. Others show track info only.'),
            _infoLine(context,
                'Imported playlists from remote sources (e.g. YouTube Music) are not included in export.'),
          ]),
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
              child: Text(text,
                  style: TextStyle(
                      color: AppColorsScheme.of(context).textMuted,
                      fontSize: AppFontSize.md,
                      height: 1.5)),
            ),
          ],
        ),
      );
}

// ── Import Preview Sheet ───────────────────────────────────────────────────────

class _ImportPreviewSheet extends StatelessWidget {
  const _ImportPreviewSheet({required this.playlists});

  final List<ParsedPlaylist> playlists;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: kSheetHorizontalPadding, vertical: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Import ${playlists.length} Playlist${playlists.length == 1 ? '' : 's'}',
            style: TextStyle(
              color: AppColorsScheme.of(context).textPrimary,
              fontSize: AppFontSize.h3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The following playlists will be added to your library:',
            style: TextStyle(
              color: AppColorsScheme.of(context).textSecondary,
              fontSize: AppFontSize.md,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.35,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: playlists.length,
              itemBuilder: (_, i) {
                final pl = playlists[i];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Center(
                          child: AppIcon(
                              icon: AppIcons.musicNote,
                              color: AppColors.primary,
                              size: 18),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pl.name,
                              style: TextStyle(
                                color:
                                    AppColorsScheme.of(context).textPrimary,
                                fontSize: AppFontSize.md,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${pl.tracks.length} track${pl.tracks.length == 1 ? '' : 's'}',
                              style: TextStyle(
                                color:
                                    AppColorsScheme.of(context).textMuted,
                                fontSize: AppFontSize.sm,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _SheetButton(
                  label: 'Cancel',
                  onTap: () => Navigator.of(context).pop(false),
                  isPrimary: false,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _SheetButton(
                  label: 'Import',
                  onTap: () => Navigator.of(context).pop(true),
                  isPrimary: true,
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.md),
        ],
      ),
    );
  }
}

// ── Playlist Picker Sheet ─────────────────────────────────────────────────────

class _PlaylistPickerSheet extends StatefulWidget {
  const _PlaylistPickerSheet({required this.playlists});

  final List<LibraryPlaylist> playlists;

  @override
  State<_PlaylistPickerSheet> createState() => _PlaylistPickerSheetState();
}

class _PlaylistPickerSheetState extends State<_PlaylistPickerSheet> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: kSheetHorizontalPadding, vertical: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Playlists',
            style: TextStyle(
              color: AppColorsScheme.of(context).textPrimary,
              fontSize: AppFontSize.h3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${_selected.length} selected',
            style: TextStyle(
              color: AppColorsScheme.of(context).textMuted,
              fontSize: AppFontSize.md,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.playlists.length,
              itemBuilder: (_, i) {
                final pl = widget.playlists[i];
                final isSelected = _selected.contains(pl.id);
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() {
                      if (isSelected) {
                        _selected.remove(pl.id);
                      } else {
                        _selected.add(pl.id);
                      }
                    }),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColorsScheme.of(context)
                                        .surfaceHighlight,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Center(
                                    child: Icon(Icons.check,
                                        color: Colors.white, size: 13))
                                : null,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pl.name,
                                  style: TextStyle(
                                    color: AppColorsScheme.of(context)
                                        .textPrimary,
                                    fontSize: AppFontSize.md,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  pl.trackCountLabel,
                                  style: TextStyle(
                                    color: AppColorsScheme.of(context)
                                        .textMuted,
                                    fontSize: AppFontSize.sm,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _SheetButton(
                  label: 'Cancel',
                  onTap: () => Navigator.of(context).pop(null),
                  isPrimary: false,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _SheetButton(
                  label: 'Export${_selected.isNotEmpty ? ' (${_selected.length})' : ''}',
                  onTap: _selected.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(
                            widget.playlists
                                .where((p) => _selected.contains(p.id))
                                .toList(),
                          ),
                  isPrimary: true,
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.md),
        ],
      ),
    );
  }
}

// ── Format Picker Sheet ───────────────────────────────────────────────────────

class _FormatPickerSheet extends StatelessWidget {
  const _FormatPickerSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: kSheetHorizontalPadding, vertical: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Format',
            style: TextStyle(
              color: AppColorsScheme.of(context).textPrimary,
              fontSize: AppFontSize.h3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _FormatOption(
            format: PlaylistExportFormat.json,
            title: 'Tunify JSON',
            description:
                'Full export with YouTube IDs, artwork URLs and all metadata. Best for re-importing into Tunify.',
            iconColor: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          _FormatOption(
            format: PlaylistExportFormat.m3u,
            title: 'M3U Playlist',
            description:
                'Universal format compatible with VLC, Winamp, and most media players.',
            iconColor: AppColors.accentCyan,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.lg),
        ],
      ),
    );
  }
}

class _FormatOption extends StatelessWidget {
  const _FormatOption({
    required this.format,
    required this.title,
    required this.description,
    required this.iconColor,
  });

  final PlaylistExportFormat format;
  final String title;
  final String description;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(format),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: Text(
                    format.extension.toUpperCase(),
                    style: TextStyle(
                      color: iconColor,
                      fontSize: AppFontSize.sm,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          color: AppColorsScheme.of(context).textPrimary,
                          fontSize: AppFontSize.lg,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 2),
                    Text(description,
                        style: TextStyle(
                          color: AppColorsScheme.of(context).textMuted,
                          fontSize: AppFontSize.sm,
                          height: 1.4,
                        )),
                  ],
                ),
              ),
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

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final List<List<dynamic>> icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIcon(icon: icon, color: iconColor, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: TextStyle(
            color: iconColor,
            fontSize: AppFontSize.lg,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
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
                    Text(title,
                        style: TextStyle(
                          color: AppColorsScheme.of(context).textPrimary,
                          fontSize: AppFontSize.lg,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 2),
                    Text(busy ? 'Working…' : subtitle,
                        style: TextStyle(
                          color: AppColorsScheme.of(context).textMuted,
                          fontSize: AppFontSize.sm,
                        )),
                  ],
                ),
              ),
              if (!busy)
                AppIcon(
                    icon: AppIcons.chevronRight,
                    color: AppColorsScheme.of(context).textMuted,
                    size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatChips extends StatelessWidget {
  const _FormatChips({required this.labels, required this.colors});

  final List<String> labels;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: List.generate(labels.length, (i) {
        final color = colors[i % colors.length];
        return Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.xs),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Text(
            labels[i],
            style: TextStyle(
              color: color,
              fontSize: AppFontSize.sm,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }),
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
            'Notes',
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

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isPrimary
                ? AppColors.primary
                : AppColorsScheme.of(context).surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isPrimary
                  ? AppColors.primary
                  : AppColorsScheme.of(context).surfaceHighlight,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isPrimary
                  ? Colors.white
                  : AppColorsScheme.of(context).textPrimary,
              fontSize: AppFontSize.md,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
