import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:tunify/core/constants/app_strings.dart';
import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/lyrics_result.dart';
import 'package:tunify/data/models/song.dart';
import 'package:tunify/data/models/library_playlist.dart';
import 'package:tunify/features/device/device_discovery_service.dart';
import 'package:tunify/features/device/device_discovery_service_extensions.dart';
import 'package:tunify/features/downloads/download_provider.dart';
import 'package:tunify/features/downloads/download_service.dart';
import 'package:tunify/features/player/lyrics_provider.dart';
import 'package:tunify/features/player/playback_position_provider.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/features/player/sleep_timer_provider.dart';
import 'package:tunify/ui/screens/shared/player/song_options_sheet.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';
import 'package:tunify/ui/theme/app_routes.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/widgets/common/button.dart';
import 'package:tunify/ui/widgets/common/empty_state_placeholder.dart';
import 'package:tunify/ui/widgets/common/page_foundation.dart';
import 'package:tunify/ui/widgets/common/sheet.dart';
import 'package:tunify/ui/widgets/library/song_list_tile.dart';
import 'package:tunify/ui/widgets/player/download_progress_ring.dart';
import 'package:tunify/ui/widgets/player/mini_player_play_button.dart';

void showQueueSheet(BuildContext context, {BuildContext? buttonContext}) {
  showAppDraggableSheet(
    context,
    initialChildSize: 0.55,
    minChildSize: 0.3,
    maxChildSize: 0.85,
    builder: (scrollController) =>
        QueuePanelContent(scrollController: scrollController),
  );
}

void showLyricsSheet(
  BuildContext context, {
  Color dominantColor = AppColors.primary,
}) {
  showAppDraggableSheet(
    context,
    initialChildSize: 0.6,
    minChildSize: 0.3,
    maxChildSize: 0.9,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          dominantColor.withValues(
              alpha: PaletteTheme.playerQueueGradientAlpha),
          AppColorsScheme.of(context).surface,
          AppColorsScheme.of(context).surface,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0, 0.3, 1],
      ),
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.xxl),
      ),
      border: Border(
        top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
    ),
    builder: (scrollController) => LyricsPanelContent(
      dominantColor: dominantColor,
      scrollController: scrollController,
    ),
  );
}

void showDevicesSheet(BuildContext context) {
  showAppDraggableSheet(
    context,
    initialChildSize: 0.50,
    minChildSize: 0.30,
    maxChildSize: 0.85,
    builder: (scrollController) =>
        DevicesPanelContent(scrollController: scrollController),
  );
}

void showSleepTimerSheet(BuildContext context) {
  showAppSheet(
    context,
    maxHeight: 500,
    child: const _SleepTimerSheetContent(),
  );
}

// Speed extra button — shows current speed when non-1×.
class SpeedExtraButton extends StatelessWidget {
  const SpeedExtraButton({
    super.key,
    required this.isActive,
    required this.speed,
    required this.onTap,
  });

  final bool isActive;
  final double speed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xBFFFFFFF);
    final activeColor = AppColors.primary;
    final displayColor = isActive ? activeColor : color;
    final speedLabel = isActive
        ? '${speed.toStringAsFixed(speed.truncateToDouble() == speed ? 0 : 2)}×'
        : 'Speed';
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
                icon: AppIcons.playbackSpeed, color: displayColor, size: 22),
            const SizedBox(height: AppSpacing.xs + 2),
            Text(
              speedLabel,
              style: TextStyle(
                color: displayColor,
                fontSize: AppFontSize.micro,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showPlaybackSpeedSheet(BuildContext context) {
  showAppSheet(
    context,
    maxHeight: 380,
    child: const _PlaybackSpeedSheetContent(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _SleepTimerSheetContent extends ConsumerStatefulWidget {
  const _SleepTimerSheetContent();

  @override
  ConsumerState<_SleepTimerSheetContent> createState() =>
      _SleepTimerSheetContentState();
}

class _SleepTimerSheetContentState
    extends ConsumerState<_SleepTimerSheetContent> {
  bool _showCustomInput = false;
  final _minutesController = TextEditingController();

  static String _formatSleepTimerDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m >= 60) {
      final h = m ~/ 60;
      final rm = m % 60;
      return '${h}h ${rm}m';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
  }

  void _setCustomTimer() {
    final minutes = int.tryParse(_minutesController.text.trim());
    if (minutes == null || minutes <= 0) return;
    ref.read(sleepTimerProvider.notifier).setTimer(Duration(minutes: minutes));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final sleepState = ref.watch(sleepTimerProvider);
    final notifier = ref.read(sleepTimerProvider.notifier);
    final remaining = sleepState.remaining;
    final isEndOfTrack = sleepState.endOfTrack;
    final isActive = sleepState.isActive;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.fromLTRB(
              kSheetHorizontalPadding, 4, kSheetHorizontalPadding, 0),
          child: Text(
            'Sleep timer',
            style: TextStyle(
              color: AppColorsScheme.of(context)
                  .textPrimary
                  .withValues(alpha: 0.95),
              fontSize: AppFontSize.md,
              fontWeight: FontWeight.w600,
              letterSpacing: AppLetterSpacing.label,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Hero: moon circle with state
        Center(
          child: _SleepTimerHero(
            remaining: remaining,
            isEndOfTrack: isEndOfTrack,
            isActive: isActive,
            formatDuration: _formatSleepTimerDuration,
          ),
        ),
        const SizedBox(height: 28),
        if (isActive) ...[
          Center(
            child: _SleepTimerChip(
              label: 'Cancel timer',
              onTap: () {
                notifier.cancel();
                Navigator.of(context).pop();
              },
              isCancel: true,
            ),
          ),
        ] else ...[
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: kSheetHorizontalPadding),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                _SleepTimerChip(
                  label: '15 min',
                  onTap: () {
                    notifier.setTimer(const Duration(minutes: 15));
                    Navigator.of(context).pop();
                  },
                ),
                _SleepTimerChip(
                  label: '30 min',
                  onTap: () {
                    notifier.setTimer(const Duration(minutes: 30));
                    Navigator.of(context).pop();
                  },
                ),
                _SleepTimerChip(
                  label: '45 min',
                  onTap: () {
                    notifier.setTimer(const Duration(minutes: 45));
                    Navigator.of(context).pop();
                  },
                ),
                _SleepTimerChip(
                  label: '1 hour',
                  onTap: () {
                    notifier.setTimer(const Duration(hours: 1));
                    Navigator.of(context).pop();
                  },
                ),
                _SleepTimerChip(
                  label: 'End of song',
                  onTap: () {
                    notifier.setEndOfTrack();
                    Navigator.of(context).pop();
                  },
                ),
                _SleepTimerChip(
                  label: 'Custom',
                  onTap: () =>
                      setState(() => _showCustomInput = !_showCustomInput),
                ),
              ],
            ),
          ),
          if (_showCustomInput)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  kSheetHorizontalPadding, 12, kSheetHorizontalPadding, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minutesController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _setCustomTimer(),
                      autofocus: true,
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textPrimary,
                        fontSize: AppFontSize.base,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Minutes (e.g. 20)',
                        hintStyle: TextStyle(
                          color: AppColorsScheme.of(context)
                              .textMuted
                              .withValues(alpha: 0.6),
                          fontSize: AppFontSize.base,
                        ),
                        filled: true,
                        fillColor: AppColorsScheme.of(context).surfaceHighlight,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _SleepTimerChip(
                    label: 'Set',
                    onTap: _setCustomTimer,
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _SleepTimerHero extends StatelessWidget {
  const _SleepTimerHero({
    required this.remaining,
    required this.isEndOfTrack,
    required this.isActive,
    required this.formatDuration,
  });
  final Duration? remaining;
  final bool isEndOfTrack;
  final bool isActive;
  final String Function(Duration) formatDuration;

  static const double _size = 120;

  @override
  Widget build(BuildContext context) {
    final bool showCountdown =
        isActive && remaining != null && remaining! > Duration.zero;
    final bool showEndOfTrack = isActive && isEndOfTrack;

    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 28,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColorsScheme.of(context)
                .surface
                .withValues(alpha: UIOpacity.disabled),
            blurRadius: 40,
            spreadRadius: -8,
          ),
        ],
        gradient: LinearGradient(
          colors: [
            AppColorsScheme.of(context).surfaceHighlight,
            AppColorsScheme.of(context).surface,
            AppColorsScheme.of(context).background,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        border: Border.all(
          color: AppColors.glassBorder.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Center(
        child: showCountdown
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatDuration(remaining!),
                    style: TextStyle(
                      color: AppColorsScheme.of(context).textPrimary,
                      fontSize: AppFontSize.display3,
                      fontWeight: FontWeight.w400,
                      letterSpacing: AppLetterSpacing.label,
                      height: AppLineHeight.tight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'remaining',
                    style: TextStyle(
                      color: AppColorsScheme.of(context)
                          .textSecondary
                          .withValues(alpha: 0.9),
                      fontSize: AppFontSize.xs,
                      fontWeight: FontWeight.w500,
                      letterSpacing: AppLetterSpacing.normal,
                    ),
                  ),
                ],
              )
            : showEndOfTrack
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon(
                        icon: AppIcons.musicNote,
                        color: AppColorsScheme.of(context).textSecondary,
                        size: 28,
                      ),
                      const SizedBox(height: AppSpacing.xs + 2),
                      Text(
                        'End of song',
                        style: TextStyle(
                          color: AppColorsScheme.of(context)
                              .textSecondary
                              .withValues(alpha: 0.95),
                          fontSize: AppFontSize.xs,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : AppIcon(
                    icon: AppIcons.bedtime,
                    color: AppColorsScheme.of(context)
                        .textPrimary
                        .withValues(alpha: 0.85),
                    size: 44,
                  ),
      ),
    );
  }
}

class _SleepTimerChip extends StatelessWidget {
  const _SleepTimerChip({
    required this.label,
    required this.onTap,
    this.isCancel = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool isCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.full),
            color: isCancel
                ? AppColorsScheme.of(context)
                    .surfaceHighlight
                    .withValues(alpha: 0.6)
                : AppColorsScheme.of(context).surfaceHighlight,
            border: Border.all(
              color: isCancel
                  ? AppColorsScheme.of(context).textMuted.withValues(alpha: 0.3)
                  : AppColors.glassBorder.withValues(alpha: 0.4),
              width: 0.6,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isCancel
                  ? AppColorsScheme.of(context).textMuted
                  : AppColorsScheme.of(context)
                      .textPrimary
                      .withValues(alpha: 0.95),
              fontSize: AppFontSize.base,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class DevicesPanelContent extends StatefulWidget {
  const DevicesPanelContent({super.key, required this.scrollController});
  final ScrollController scrollController;

  @override
  State<DevicesPanelContent> createState() => _DevicesPanelContentState();
}

class _DevicesPanelContentState extends State<DevicesPanelContent>
    with SingleTickerProviderStateMixin {
  final _service = DeviceDiscoveryService();
  AudioDevice _activeDevice = const AudioDevice(
    id: 'this-device',
    name: 'This Device',
    type: AudioDeviceType.thisDevice,
    isActive: true,
  );
  List<AudioDevice> _bluetoothDevices = [];
  List<AudioDevice> _networkDevices = [];
  bool _scanningNetwork = false;
  bool _loadingBluetooth = true;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: AppDuration.xslow,
    )..repeat(reverse: true);
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    final active = await _service.getActiveDevice();
    final bt = await _service.getConnectedBluetoothDevices();
    if (!mounted) return;
    setState(() {
      _activeDevice = active;
      _bluetoothDevices = bt;
      _loadingBluetooth = false;
    });
    _scanNetwork();
  }

  Future<void> _scanNetwork() async {
    setState(() => _scanningNetwork = true);
    final net = await _service.scanNetworkDevices();
    if (!mounted) return;
    setState(() {
      _networkDevices = net;
      _scanningNetwork = false;
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasBluetoothActive = _activeDevice.type == AudioDeviceType.bluetooth;
    final hasWiredActive = _activeDevice.type == AudioDeviceType.wired;

    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              kSheetHorizontalPadding, 20, kSheetHorizontalPadding, 4),
          child: Row(
            children: [
              AppIcon(
                  icon: AppIcons.speakerGroup,
                  color: AppColorsScheme.of(context).textPrimary,
                  size: 22),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Text(
                  'Connect to a device',
                  style: TextStyle(
                    color: AppColorsScheme.of(context).textPrimary,
                    fontSize: AppFontSize.xxl,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_scanningNetwork)
                FadeTransition(
                  opacity: _pulseCtrl,
                  child: const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SectionLabel(label: 'CURRENT DEVICE'),
        _DeviceTile(
          icon: _activeDevice.type.icon,
          name: hasBluetoothActive || hasWiredActive
              ? _activeDevice.name
              : 'This Phone',
          subtitle: hasBluetoothActive
              ? 'Bluetooth audio'
              : hasWiredActive
                  ? 'Wired headphones'
                  : 'Phone speaker',
          isActive: true,
          accentColor: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.xs),
        Divider(
          color: AppColorsScheme.of(context).surfaceHighlight,
          indent: 24,
          endIndent: 24,
          height: 1,
        ),
        const SizedBox(height: AppSpacing.xs),
        _SectionLabel(
          label: 'BLUETOOTH',
          trailing: GestureDetector(
            onTap: () => _service.openBluetoothSettings(),
            child: const Text(
              'Settings',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: AppFontSize.sm,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (_loadingBluetooth)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColorsScheme.of(context).textMuted,
                ),
              ),
            ),
          )
        else if (_bluetoothDevices.isEmpty && !hasBluetoothActive)
          _EmptySection(
            icon: AppIcons.bluetoothSearch,
            message: 'No Bluetooth audio devices are connected',
            actionLabel: 'Open Settings',
            onAction: () => _service.openBluetoothSettings(),
          )
        else
          ..._bluetoothDevices.map((d) => _DeviceTile(
                icon: AppIcons.bluetooth,
                name: d.name,
                subtitle: d.subtype == 'a2dp' ? 'Bluetooth audio' : 'Bluetooth',
                isActive: hasBluetoothActive && _activeDevice.name == d.name,
                accentColor: AppColors.primary,
              )),
        const SizedBox(height: AppSpacing.xs),
        Divider(
          color: AppColorsScheme.of(context).surfaceHighlight,
          indent: 24,
          endIndent: 24,
          height: 1,
        ),
        const SizedBox(height: AppSpacing.xs),
        _SectionLabel(
          label: 'NETWORK DEVICES',
          trailing: GestureDetector(
            onTap: _scanningNetwork ? null : _scanNetwork,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  icon: AppIcons.refresh,
                  size: 14,
                  color: _scanningNetwork
                      ? AppColorsScheme.of(context).textMuted
                      : AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  _scanningNetwork ? 'Scanning...' : 'Scan',
                  style: TextStyle(
                    color: _scanningNetwork
                        ? AppColorsScheme.of(context).textMuted
                        : AppColors.primary,
                    fontSize: AppFontSize.sm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_scanningNetwork && _networkDevices.isEmpty)
          _ScanningPlaceholder(pulseCtrl: _pulseCtrl)
        else if (_networkDevices.isEmpty && !_scanningNetwork)
          _EmptySection(
            icon: AppIcons.wifiFind,
            message:
                'No Chromecast, DLNA, or AirPlay devices found on your network',
          )
        else
          ..._networkDevices.map((d) => _DeviceTile(
                icon: d.type.icon,
                name: d.name,
                subtitle:
                    '${d.type.subtitle}${d.ip != null ? '  •  ${d.ip}' : ''}',
                isActive: false,
                accentColor: AppColors.primary,
              )),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.trailing});
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          kSheetHorizontalPadding, 12, kSheetHorizontalPadding, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColorsScheme.of(context).textMuted,
                fontSize: AppFontSize.xs,
                fontWeight: FontWeight.w700,
                letterSpacing: AppLetterSpacing.label,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.icon,
    required this.name,
    required this.subtitle,
    required this.isActive,
    required this.accentColor,
  });

  final List<List<dynamic>> icon;
  final String name;
  final String subtitle;
  final bool isActive;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: kSheetHorizontalPadding, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isActive
                  ? accentColor.withValues(alpha: 0.15)
                  : AppColorsScheme.of(context).surfaceHighlight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: AppIcon(
              icon: icon,
              color: isActive
                  ? accentColor
                  : AppColorsScheme.of(context).textSecondary,
              size: 21,
            ),
          ),
          const SizedBox(width: AppSpacing.md + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isActive
                        ? accentColor
                        : AppColorsScheme.of(context).textPrimary,
                    fontSize: AppFontSize.lg,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isActive
                        ? accentColor.withValues(alpha: 0.7)
                        : AppColorsScheme.of(context).textMuted,
                    fontSize: AppFontSize.sm,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isActive)
            _ActiveIndicator(color: accentColor)
          else
            AppIcon(
              icon: AppIcons.chevronRight,
              color: AppColorsScheme.of(context).textMuted,
              size: 20,
            ),
        ],
      ),
    );
  }
}

class _ActiveIndicator extends StatelessWidget {
  const _ActiveIndicator({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: UIOpacity.disabled),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final List<List<dynamic>> icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: kSheetHorizontalPadding, vertical: 16),
      child: Row(
        children: [
          AppIcon(
              icon: icon,
              color: AppColorsScheme.of(context).textMuted,
              size: 28),
          const SizedBox(width: AppSpacing.md + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: AppColorsScheme.of(context).textMuted,
                    fontSize: AppFontSize.md,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: AppSpacing.xs + 2),
                  GestureDetector(
                    onTap: onAction,
                    child: Text(
                      actionLabel!,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: AppFontSize.md,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanningPlaceholder extends StatelessWidget {
  const _ScanningPlaceholder({required this.pulseCtrl});
  final AnimationController pulseCtrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: kSheetHorizontalPadding, vertical: 20),
      child: Row(
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.3, end: 1.0).animate(pulseCtrl),
            child: AppIcon(
              icon: AppIcons.radar,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md + 2),
          Text(
            'Scanning your network...',
            style: TextStyle(
              color: AppColorsScheme.of(context).textSecondary,
              fontSize: AppFontSize.md,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerDownloadButton extends ConsumerStatefulWidget {
  const _PlayerDownloadButton();

  @override
  ConsumerState<_PlayerDownloadButton> createState() =>
      _PlayerDownloadButtonState();
}

class _PlayerDownloadButtonState extends ConsumerState<_PlayerDownloadButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  bool _wasInQueue = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: AppDuration.xslow,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final song = ref.watch(currentSongProvider);
    final isDeviceSong = song != null && song.id.startsWith('device_');

    if (isDeviceSong) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                icon: AppIcons.checkCircle,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(height: AppSpacing.xs + 2),
              Text(
                'On Device',
                style: TextStyle(
                  color: AppColorsScheme.of(context).textMuted,
                  fontSize: AppFontSize.micro,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final downloadService = ref.watch(downloadServiceProvider);
    final isDownloaded = song != null && downloadService.isDownloaded(song.id);
    final queueMatch = song != null
        ? downloadService.queue.where((e) => e.song.id == song.id)
        : <DownloadEntry>[];
    final entry = queueMatch.isEmpty ? null : queueMatch.first;
    final isInQueue = entry != null;

    if (isInQueue != _wasInQueue) {
      _wasInQueue = isInQueue;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (isInQueue) {
          _rotationController.repeat();
        } else {
          _rotationController
            ..stop()
            ..reset();
        }
      });
    }

    double? progress;
    if (entry != null &&
        entry.expectedBytes != null &&
        entry.expectedBytes! > 0 &&
        entry.downloadedBytes != null) {
      progress =
          (entry.downloadedBytes! / entry.expectedBytes!).clamp(0.0, 1.0);
    }

    Widget icon;
    if (isDownloaded) {
      icon = AppIcon(
        icon: AppIcons.checkCircle,
        color: AppColors.primary,
        size: 22,
      );
    } else if (isInQueue) {
      icon = SizedBox(
        width: 32,
        height: 32,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(32, 32),
                  painter: DownloadProgressRingPainter(
                    progress: progress,
                    rotation: _rotationController.value * 2 * 3.14159265359,
                    trackColor: AppColorsScheme.of(context).textMuted,
                    progressColor: AppColors.primary,
                    strokeWidth: 2,
                  ),
                );
              },
            ),
            AppIcon(
              icon: AppIcons.download,
              color: AppColorsScheme.of(context).textSecondary,
              size: 20,
            ),
          ],
        ),
      );
    } else {
      icon = AppIcon(
        icon: AppIcons.download,
        color: AppColorsScheme.of(context).textSecondary,
        size: 22,
      );
    }

    VoidCallback? onTap;
    if (!isDownloaded && !isInQueue && song != null) {
      onTap = () => ref.read(downloadServiceProvider).enqueue(song);
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: AppSpacing.xs + 2),
            Text(
              isInQueue ? 'Downloading' : 'Download',
              style: TextStyle(
                color: AppColorsScheme.of(context).textMuted,
                fontSize: AppFontSize.micro,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QueuePanelContent extends ConsumerWidget {
  const QueuePanelContent({super.key, required this.scrollController});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(playerProvider.select((s) => s.queue));
    final currentIndex =
        ref.watch(playerProvider.select((s) => s.currentIndex));
    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));
    final isLoading = ref.watch(playerProvider.select((s) => s.isLoading));
    final isShuffleEnabled =
        ref.watch(playerProvider.select((s) => s.isShuffleEnabled));
    final activeShuffleMode =
        ref.watch(playerProvider.select((s) => s.activeShuffleMode));
    final isSmartShuffleLoading =
        ref.watch(playerProvider.select((s) => s.isSmartShuffleLoading));
    final currentSong = (currentIndex >= 0 && currentIndex < queue.length)
        ? queue[currentIndex]
        : null;

    // Calculate item count: queue items (minus current) + skeleton if loading
    final queueItemCount = queue.isEmpty
        ? 0
        : (currentIndex >= 0 ? queue.length - 1 : queue.length);
    final showSmartShuffleSkeleton =
        isSmartShuffleLoading && activeShuffleMode == ShuffleMode.smart;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              kSheetHorizontalPadding, 16, kSheetHorizontalPadding, 8),
          child: Row(
            children: [
              AppIcon(
                  icon: AppIcons.queueMusic,
                  color: AppColorsScheme.of(context).textPrimary,
                  size: 22),
              const SizedBox(width: AppSpacing.sm + 2),
              Text(
                'Queue',
                style: TextStyle(
                  color: AppColorsScheme.of(context).textPrimary,
                  fontSize: AppFontSize.xxl,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  '${queue.length}',
                  style: TextStyle(
                    color: AppColorsScheme.of(context).textSecondary,
                    fontSize: AppFontSize.sm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (queue.isEmpty)
          Expanded(
            child: EmptyStatePlaceholder(
              icon: AppIcon(
                icon: AppIcons.queueMusic,
                color: AppColorsScheme.of(context).textMuted,
                size: 48,
              ),
              title: 'The queue is empty',
            ),
          )
        else ...[
          if (currentSong != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  kSheetHorizontalPadding, 4, kSheetHorizontalPadding, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Playing ${currentSong.title}',
                    style: TextStyle(
                      color: AppColorsScheme.of(context).textSecondary,
                      fontSize: AppFontSize.md,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SongListTile(
                    song: currentSong,
                    onTap: () {
                      ref
                          .read(playerProvider.notifier)
                          .playSong(currentSong, queue: queue);
                    },
                    thumbnailSize: 48,
                    highlightBackground: false,
                    showIndexIndicator: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: AppSpacing.xs,
                    ),
                    trailing: MiniPlayerPlayButton(
                      isPlaying: isPlaying,
                      isLoading: isLoading,
                      onTap: () =>
                          ref.read(playerProvider.notifier).togglePlayPause(),
                    ),
                  ),
                ],
              ),
            ),
          if (isShuffleEnabled || activeShuffleMode != ShuffleMode.none)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  kSheetHorizontalPadding, 4, kSheetHorizontalPadding, 8),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (activeShuffleMode == ShuffleMode.smart) {
                    ref.read(playerProvider.notifier).toggleSmartShuffle();
                  } else {
                    ref.read(playerProvider.notifier).toggleShuffle();
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AppIcon(
                            icon: AppIcons.shuffle,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          if (activeShuffleMode == ShuffleMode.smart)
                            const Positioned(
                              right: -3,
                              bottom: -3,
                              child: Icon(
                                Icons.auto_awesome,
                                size: 9,
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      activeShuffleMode == ShuffleMode.smart
                          ? 'Smart Shuffling'
                          : 'Shuffling',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: AppFontSize.md,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AppIcon(
                      icon: AppIcons.close,
                      color: AppColors.primary,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ReorderableListView.builder(
              scrollController: scrollController,
              buildDefaultDragHandles: false,
              cacheExtent: 1000,
              padding: const EdgeInsets.only(
                left: kSheetHorizontalPadding,
                right: kSheetHorizontalPadding,
                bottom: 32,
              ),
              itemCount: queueItemCount + (showSmartShuffleSkeleton ? 1 : 0),
              onReorder: (oldIndex, newIndex) {
                if (currentIndex < 0) {
                  ref
                      .read(playerProvider.notifier)
                      .reorderQueue(oldIndex, newIndex);
                  return;
                }
                int toActual(int visual) =>
                    visual >= currentIndex ? visual + 1 : visual;
                final oldActual = toActual(oldIndex);
                final newActual = toActual(newIndex);
                ref
                    .read(playerProvider.notifier)
                    .reorderQueue(oldActual, newActual);
              },
              itemBuilder: (context, i) {
                // Show skeleton loader at the end when smart shuffle is loading
                if (showSmartShuffleSkeleton && i == queueItemCount) {
                  return const _QueueItemSkeleton(
                      key: ValueKey('smart-shuffle-skeleton'));
                }

                final int actualIndex;
                if (currentIndex >= 0) {
                  actualIndex = i >= currentIndex ? i + 1 : i;
                } else {
                  actualIndex = i;
                }
                final song = queue[actualIndex];
                final smartIds = ref
                    .watch(playerProvider.select((s) => s.smartShuffleSongIds));
                return _QueueItem(
                  key: ValueKey(song.id),
                  song: song,
                  queueIndex: actualIndex,
                  isSmartShuffle: smartIds.contains(song.id),
                  onTap: () {
                    ref
                        .read(playerProvider.notifier)
                        .playSong(song, queue: queue);
                  },
                  dragHandle: ReorderableDragStartListener(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AppIcon(
                        icon: AppIcons.dragHandle,
                        color: AppColorsScheme.of(context).textMuted,
                        size: 22,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

// ── Desktop queue overlay panel ───────────────────────────────────────────────

class _QueueItem extends ConsumerWidget {
  const _QueueItem({
    super.key,
    required this.song,
    required this.onTap,
    required this.queueIndex,
    this.dragHandle,
    this.isSmartShuffle = false,
  });
  final Song song;
  final VoidCallback onTap;
  final int queueIndex;
  final Widget? dragHandle;
  final bool isSmartShuffle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: SongListTile(
              song: song,
              onTap: onTap,
              thumbnailSize: 48,
              highlightBackground: false,
              showIndexIndicator: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: AppSpacing.xs,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.durationFormatted,
                    style: TextStyle(
                      color: AppColorsScheme.of(context).textMuted,
                      fontSize: AppFontSize.md,
                    ),
                  ),
                  if (isSmartShuffle)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  AppIconButton(
                    icon: AppIcon(
                      icon: AppIcons.moreVert,
                      color: AppColorsScheme.of(context).textMuted,
                      size: 20,
                    ),
                    onPressedWithContext: (btnCtx) => showSongOptionsSheet(
                      context,
                      song: song,
                      ref: ref,
                      queueIndex: queueIndex,
                      buttonContext: btnCtx,
                    ),
                    iconSize: 20,
                    size: 40,
                  ),
                  if (dragHandle != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: dragHandle!,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueItemSkeleton extends StatelessWidget {
  const _QueueItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    const fakeSong = Song(
      id: 'skeleton-queue-song',
      title: 'Loading queued song',
      artist: 'Loading artist',
      thumbnailUrl: '',
      duration: Duration(minutes: 3, seconds: 45),
    );
    return Opacity(
      opacity: 0.45,
      child: IgnorePointer(
        child: _QueueItem(
          song: fakeSong,
          onTap: _noop,
          queueIndex: 0,
          isSmartShuffle: true,
        ),
      ),
    );
  }
}

void _noop() {}

class LyricsPanelContent extends ConsumerStatefulWidget {
  const LyricsPanelContent({
    super.key,
    this.dominantColor = AppColors.primary,
    required this.scrollController,
  });
  final Color dominantColor;
  final ScrollController scrollController;

  @override
  ConsumerState<LyricsPanelContent> createState() => _LyricsPanelContentState();
}

class _LyricsPanelContentState extends ConsumerState<LyricsPanelContent> {
  List<GlobalKey> _lineKeys = [];
  int _activeIndex = -1;
  bool _isShareSelectionMode = false;
  final List<int> _selectedLineIndices = <int>[];
  ProviderSubscription<Duration>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _positionSubscription = ref.listenManual(
      playbackPositionProvider,
      (_, position) => _updateActiveIndex(position),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _positionSubscription?.close();
    super.dispose();
  }

  void _updateActiveIndex(Duration position) {
    final lyricsState = ref.read(lyricsProvider);
    if (!lyricsState.hasLyrics || !lyricsState.lyrics!.isSynced) return;
    final lines = lyricsState.lyrics!.lines;
    if (_lineKeys.length != lines.length) return;
    int newActive = -1;
    for (int i = 0; i < lines.length; i++) {
      final t = lines[i].startTime;
      if (t != null && t <= position) newActive = i;
    }
    if (newActive != _activeIndex) {
      setState(() => _activeIndex = newActive);
      _maybeScrollToActive(newActive);
    }
  }

  void _maybeScrollToActive(int index) {
    if (index < 0 || index >= _lineKeys.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _lineKeys[index].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: AppDuration.medium,
          curve: AppCurves.decelerate,
          alignment: 0.3,
        );
      }
    });
  }

  void _toggleShareSelectionMode() {
    setState(() {
      _isShareSelectionMode = !_isShareSelectionMode;
      _selectedLineIndices.clear();
    });
  }

  void _onTapLyricLine(int index, bool isSynced) {
    if (!_isShareSelectionMode || !isSynced) return;
    setState(() {
      if (_selectedLineIndices.isEmpty) {
        _selectedLineIndices.add(index);
        return;
      }
      final last = _selectedLineIndices.last;
      if (index == last) {
        _selectedLineIndices.removeLast();
        return;
      }
      if (_selectedLineIndices.length >= 5) return;
      if (index == last + 1) {
        _selectedLineIndices.add(index);
      }
    });
  }

  void _onLongPressLyricLine(int index, bool isSynced) {
    if (!isSynced) return;
    if (!_isShareSelectionMode) {
      setState(() {
        _isShareSelectionMode = true;
        _selectedLineIndices
          ..clear()
          ..add(index);
      });
      return;
    }
    _onTapLyricLine(index, isSynced);
  }

  Future<void> _openShareComposer(LyricsState state) async {
    final song = ref.read(currentSongProvider);
    if (song == null || !state.hasLyrics) return;
    final selectedLines = _selectedLineIndices
        .where((i) => i >= 0 && i < state.lyrics!.lines.length)
        .map((i) => state.lyrics!.lines[i].text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (selectedLines.isEmpty) return;
    await Navigator.of(context).push(
      appPageRoute<void>(
        builder: (_) => LyricsShareComposer(
          song: song,
          lyricsLines: selectedLines,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyricsState = ref.watch(lyricsProvider);
    // Position is now tracked via _positionSubscription — no longer watched here.

    if (lyricsState.hasLyrics) {
      final lines = lyricsState.lyrics!.lines;
      if (_lineKeys.length != lines.length) {
        _lineKeys = List.generate(lines.length, (_) => GlobalKey());
        _activeIndex = -1;
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              kSheetHorizontalPadding, 20, kSheetHorizontalPadding, 12),
          child: Row(
            children: [
              AppIcon(
                  icon: AppIcons.lyrics, color: widget.dominantColor, size: 22),
              const SizedBox(width: AppSpacing.sm + 2),
              Text(
                'Lyrics',
                style: TextStyle(
                  color: AppColorsScheme.of(context).textPrimary,
                  fontSize: AppFontSize.xxl,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (lyricsState.hasLyrics && lyricsState.lyrics!.isSynced)
                GestureDetector(
                  onTap: _toggleShareSelectionMode,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text(
                      _isShareSelectionMode ? 'Cancel' : 'Share',
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textPrimary,
                        fontSize: AppFontSize.sm,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              if (lyricsState.hasLyrics && lyricsState.lyrics!.source != null)
                Text(
                  lyricsState.lyrics!.source!,
                  style: TextStyle(
                    color: AppColorsScheme.of(context).textMuted,
                    fontSize: AppFontSize.xs,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _buildLyricsContent(lyricsState),
        ),
        if (_isShareSelectionMode &&
            lyricsState.hasLyrics &&
            lyricsState.lyrics!.isSynced)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              kSheetHorizontalPadding,
              8,
              kSheetHorizontalPadding,
              16,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedLineIndices.isEmpty
                    ? null
                    : () => _openShareComposer(lyricsState),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsScheme.of(context).surfaceHighlight,
                  foregroundColor: AppColorsScheme.of(context).textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Next',
                  style: TextStyle(
                    fontSize: AppFontSize.base,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLyricsContent(LyricsState state) {
    if (state.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor:
              AlwaysStoppedAnimation(AppColorsScheme.of(context).textSecondary),
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                  icon: AppIcons.lyrics,
                  color: AppColorsScheme.of(context)
                      .textMuted
                      .withValues(alpha: 0.4),
                  size: 56),
              const SizedBox(height: AppSpacing.base),
              Text(
                'Couldn\'t load lyrics',
                style: TextStyle(
                  color: AppColorsScheme.of(context).textSecondary,
                  fontSize: AppFontSize.xl,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.xs + 2),
              Text(
                'A network error occurred. Tap to retry.',
                style: TextStyle(
                  color: AppColorsScheme.of(context).textMuted,
                  fontSize: AppFontSize.md,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              GestureDetector(
                onTap: () {
                  final songId = ref.read(currentSongProvider)?.id;
                  if (songId != null) {
                    ref.read(lyricsProvider.notifier).fetchForVideo(songId);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColorsScheme.of(context).surfaceHighlight,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: AppColors.glassBorder.withValues(alpha: 0.4),
                      width: 0.6,
                    ),
                  ),
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      color: AppColorsScheme.of(context).textPrimary,
                      fontSize: AppFontSize.base,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!state.hasLyrics) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                  icon: AppIcons.lyrics,
                  color: AppColorsScheme.of(context)
                      .textMuted
                      .withValues(alpha: 0.4),
                  size: 56),
              const SizedBox(height: AppSpacing.base),
              Text(
                'No lyrics available.',
                style: TextStyle(
                  color: AppColorsScheme.of(context).textSecondary,
                  fontSize: AppFontSize.xl,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.xs + 2),
              Text(
                'Lyrics are not available for this song',
                style: TextStyle(
                  color: AppColorsScheme.of(context).textMuted,
                  fontSize: AppFontSize.md,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final lines = state.lyrics!.lines;
    final isSynced = state.lyrics!.isSynced;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          kSheetHorizontalPadding, 8, kSheetHorizontalPadding, 40),
      children: [
        for (int i = 0; i < lines.length; i++)
          _buildLine(lines[i], i, isSynced),
      ],
    );
  }

  Widget _buildLine(LyricsLine line, int index, bool isSynced) {
    final isEmpty = line.text.trim().isEmpty;
    if (isEmpty) return const SizedBox(height: AppSpacing.lg);

    final isActive = isSynced && index == _activeIndex;
    final isSelected = _selectedLineIndices.contains(index);

    return GestureDetector(
      onTap: () => _onTapLyricLine(index, isSynced),
      onLongPress: () => _onLongPressLyricLine(index, isSynced),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColorsScheme.of(context)
                  .surfaceHighlight
                  .withValues(alpha: 0.65)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: AnimatedDefaultTextStyle(
          key: _lineKeys[index],
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          style: TextStyle(
            color: isSynced
                ? (isActive
                    ? AppColorsScheme.of(context).textPrimary
                    : AppColorsScheme.of(context)
                        .textPrimary
                        .withValues(alpha: 0.3))
                : AppColorsScheme.of(context).textPrimary,
            fontSize: isActive ? 22 : 20,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            height: AppLineHeight.relaxed,
            letterSpacing: AppLetterSpacing.heading,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(line.text),
          ),
        ),
      ),
    );
  }
}

class LyricsShareComposer extends StatefulWidget {
  const LyricsShareComposer({
    super.key,
    required this.song,
    required this.lyricsLines,
  });

  final Song song;
  final List<String> lyricsLines;

  @override
  State<LyricsShareComposer> createState() => _LyricsShareComposerState();
}

class _LyricsShareComposerState extends State<LyricsShareComposer> {
  static const List<List<Color>> _gradientPresets = [
    [Color(0xFF5B86E5), Color(0xFF36D1DC)],
    [Color(0xFF2B1055), Color(0xFF7597DE)],
    [Color(0xFF42275A), Color(0xFF734B6D)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFE96443), Color(0xFF904E95)],
    [Color(0xFF1D4350), Color(0xFFA43931)],
  ];

  final GlobalKey _cardKey = GlobalKey();
  int _selectedGradient = 0;
  List<Color>? _customGradient;
  double _customGradientAngle = 135;
  bool _isCustomMode = false;
  bool _editingStart = true;
  TextEditingController? _startHexController;
  TextEditingController? _endHexController;
  bool _isSharing = false;

  TextEditingController get _startHexCtrl =>
      _startHexController ??= TextEditingController();
  TextEditingController get _endHexCtrl =>
      _endHexController ??= TextEditingController();

  @override
  void initState() {
    super.initState();
    _startHexController = TextEditingController();
    _endHexController = TextEditingController();
    _syncHexControllers();
  }

  @override
  void dispose() {
    _startHexController?.dispose();
    _endHexController?.dispose();
    super.dispose();
  }

  Future<void> _shareCardImage() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/tunify_lyrics_$timestamp.png');
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '${widget.song.title} - ${widget.song.artist}',
        ),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Alignment _gradientBegin(double angleDeg) {
    final rad = angleDeg * (math.pi / 180.0);
    final x = math.cos(rad);
    final y = math.sin(rad);
    return Alignment(-x, -y);
  }

  Alignment _gradientEnd(double angleDeg) {
    final rad = angleDeg * (math.pi / 180.0);
    final x = math.cos(rad);
    final y = math.sin(rad);
    return Alignment(x, y);
  }

  void _enterCustomMode() {
    setState(() {
      _isCustomMode = true;
      _selectedGradient = -1;
      _customGradient ??= [
        _gradientPresets.first.first,
        _gradientPresets.first.last,
      ];
      _editingStart = true;
      _syncHexControllers();
    });
  }

  Color get _customStart => (_customGradient ?? _gradientPresets.first).first;
  Color get _customEnd => (_customGradient ?? _gradientPresets.first).last;

  String _toHex(Color c) {
    final rgb = c.toARGB32() & 0xFFFFFF;
    return rgb.toRadixString(16).padLeft(6, '0').toUpperCase();
  }

  Color? _parseHex(String input) {
    final hex = input.replaceAll('#', '').trim();
    if (hex.length != 6) return null;
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }

  void _syncHexControllers() {
    _startHexCtrl.text = _toHex(_customStart);
    _endHexCtrl.text = _toHex(_customEnd);
  }

  void _applyHex(bool isStart) {
    final parsed = _parseHex(isStart ? _startHexCtrl.text : _endHexCtrl.text);
    if (parsed == null) return;
    final list = [...(_customGradient ?? _gradientPresets.first)];
    list[isStart ? 0 : 1] = parsed;
    setState(() => _customGradient = list);
  }

  @override
  Widget build(BuildContext context) {
    final colors = _selectedGradient == -1
        ? (_customGradient ?? _gradientPresets.first)
        : _gradientPresets[_selectedGradient];
    final gradientAngle =
        _selectedGradient == -1 ? _customGradientAngle : 135.0;
    return AppPageScaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: _gradientBegin(gradientAngle),
            end: _gradientEnd(gradientAngle),
            colors: [
              colors.first.withValues(alpha: UIOpacity.strong),
              colors.last.withValues(alpha: UIOpacity.medium),
              AppColorsScheme.of(context).background,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              kSheetHorizontalPadding,
              8,
              kSheetHorizontalPadding,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AppIconButton(
                      icon: AppIcon(
                        icon: AppIcons.back,
                        size: 22,
                        color: AppColorsScheme.of(context).textPrimary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      iconSize: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Share Lyrics',
                      style: TextStyle(
                        color: AppColorsScheme.of(context).textPrimary,
                        fontSize: AppFontSize.xl,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Center(
                    child: RepaintBoundary(
                      key: _cardKey,
                      child: Container(
                        width: 340,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: _gradientBegin(gradientAngle),
                            end: _gradientEnd(gradientAngle),
                            colors: colors,
                          ),
                          borderRadius:
                              BorderRadius.circular(UISize.cardRadius),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    widget.song.thumbnailUrl,
                                    width: UISize.mediaThumb,
                                    height: UISize.mediaThumb,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: UISize.mediaThumb,
                                      height: UISize.mediaThumb,
                                      color: Colors.white12,
                                      child: const Icon(Icons.music_note,
                                          color: Colors.white70, size: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.song.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.song.artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                            const SizedBox(height: 12),
                            for (final line in widget.lyricsLines)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  line,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            SvgPicture.asset(
                              AppStrings.logoAsset,
                              width: 20,
                              height: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: AppDuration.fastPlus,
                  switchInCurve: AppCurves.decelerate,
                  switchOutCurve: AppCurves.standard,
                  child: !_isCustomMode
                      ? Column(
                          key: const ValueKey('preset-controls'),
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: SizedBox(
                                height: UISize.swatchSize,
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _gradientPresets.length + 1,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      final selected = _selectedGradient == -1;
                                      return GestureDetector(
                                        onTap: _enterCustomMode,
                                        child: Container(
                                          width: UISize.swatchSize,
                                          height: UISize.swatchSize,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              begin: _gradientBegin(
                                                  _customGradientAngle),
                                              end: _gradientEnd(
                                                  _customGradientAngle),
                                              colors: _customGradient ??
                                                  const [
                                                    Color(0xFF5B86E5),
                                                    Color(0xFF904E95),
                                                  ],
                                            ),
                                            border: Border.all(
                                              color: selected
                                                  ? Colors.white
                                                  : Colors.white24,
                                              width: selected ? 2 : 1,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(Icons.tune,
                                                size: 18, color: Colors.white),
                                          ),
                                        ),
                                      );
                                    }
                                    final preset = _gradientPresets[index - 1];
                                    final selected =
                                        (index - 1) == _selectedGradient;
                                    return GestureDetector(
                                      onTap: () => setState(() {
                                        _selectedGradient = index - 1;
                                        _isCustomMode = false;
                                      }),
                                      child: Container(
                                        width: UISize.swatchSize,
                                        height: UISize.swatchSize,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: preset,
                                          ),
                                          border: Border.all(
                                            color: selected
                                                ? Colors.white
                                                : Colors.white24,
                                            width: selected ? 2 : 1,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: 180,
                                child: ElevatedButton(
                                  onPressed:
                                      _isSharing ? null : _shareCardImage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColorsScheme.of(context)
                                        .surfaceHighlight,
                                    foregroundColor:
                                        AppColorsScheme.of(context).textPrimary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  child: Text(
                                    _isSharing ? 'Preparing...' : 'Share',
                                    style: TextStyle(
                                      fontSize: AppFontSize.base,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          key: const ValueKey('custom-controls'),
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          decoration: BoxDecoration(
                            color: AppColorsScheme.of(context)
                                .surface
                                .withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _editingStart = true),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _customStart,
                                        border: Border.all(
                                          color: _editingStart
                                              ? Colors.white
                                              : Colors.white38,
                                          width: _editingStart ? 2 : 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _startHexCtrl,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      maxLength: 6,
                                      decoration: const InputDecoration(
                                        counterText: '',
                                        prefixText: '#',
                                        hintText: 'START HEX',
                                        isDense: true,
                                      ),
                                      onSubmitted: (_) => _applyHex(true),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _editingStart = false),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _customEnd,
                                        border: Border.all(
                                          color: !_editingStart
                                              ? Colors.white
                                              : Colors.white38,
                                          width: !_editingStart ? 2 : 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _endHexCtrl,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      maxLength: 6,
                                      decoration: const InputDecoration(
                                        counterText: '',
                                        prefixText: '#',
                                        hintText: 'END HEX',
                                        isDense: true,
                                      ),
                                      onSubmitted: (_) => _applyHex(false),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'Angle ${_customGradientAngle.round()}°',
                                    style: TextStyle(
                                      color: AppColorsScheme.of(context)
                                          .textSecondary,
                                      fontSize: AppFontSize.xs,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Slider(
                                      min: 0,
                                      max: 360,
                                      value: _customGradientAngle,
                                      onChanged: (v) => setState(
                                          () => _customGradientAngle = v),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        setState(() => _isCustomMode = false),
                                    child: const Text('Done'),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 180,
                                child: Center(
                                  child: Text(
                                    'Color wheel unavailable in this build.',
                                    style: TextStyle(
                                      color:
                                          AppColorsScheme.of(context).textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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

// ── Playback Speed Sheet ──────────────────────────────────────────────────────

class _PlaybackSpeedSheetContent extends ConsumerWidget {
  const _PlaybackSpeedSheetContent();

  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  String _label(double speed) {
    if (speed == 1.0) return '1× Normal';
    final s = speed.toStringAsFixed(speed.truncateToDouble() == speed ? 0 : 2);
    return '$s×';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(playerProvider.select((s) => s.playbackSpeed));
    final notifier = ref.read(playerProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              kSheetHorizontalPadding, 4, kSheetHorizontalPadding, 0),
          child: Text(
            'Playback speed',
            style: TextStyle(
              color: AppColorsScheme.of(context)
                  .textPrimary
                  .withValues(alpha: 0.95),
              fontSize: AppFontSize.md,
              fontWeight: FontWeight.w600,
              letterSpacing: AppLetterSpacing.label,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final speed in _speeds)
          _SpeedTile(
            label: _label(speed),
            speed: speed,
            isSelected: (current - speed).abs() < 0.01,
            onTap: () {
              HapticFeedback.selectionClick();
              notifier.setPlaybackSpeed(speed);
              Navigator.of(context).pop();
            },
          ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _SpeedTile extends StatelessWidget {
  const _SpeedTile({
    required this.label,
    required this.speed,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final double speed;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: kSheetHorizontalPadding, vertical: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : AppColorsScheme.of(context).textPrimary,
                  fontSize: AppFontSize.lg,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              AppIcon(icon: AppIcons.check, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
