import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/ui/widgets/common/sheet.dart'
    show showAppDraggableSheet, showAppSheet, kSheetHorizontalPadding;
import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/library_playlist.dart' show ShuffleMode;
import 'package:tunify/data/models/song.dart';
import 'package:tunify/features/downloads/download_provider.dart';
import 'package:tunify/features/downloads/download_service.dart';
import 'package:tunify/features/library/library_provider.dart';
import 'package:tunify/data/models/lyrics_result.dart';
import 'package:tunify/features/player/lyrics_provider.dart';
import 'package:tunify/features/player/palette_provider.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/features/player/sleep_timer_provider.dart';
import 'package:tunify/features/device/device_discovery_service.dart';
import 'package:tunify/features/device/device_discovery_service_extensions.dart';
import 'package:tunify/ui/screens/shared/player/song_options_sheet.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/widgets/player/download_progress_ring.dart';
import 'package:tunify/ui/widgets/library/song_list_tile.dart';
import 'package:tunify/ui/widgets/player/mini_player_play_button.dart';
import 'package:tunify/ui/widgets/common/empty_state_placeholder.dart';
import 'package:tunify/ui/widgets/common/button.dart';
import 'package:tunify/ui/screens/shared/player/player_controls.dart';
import 'package:tunify/ui/screens/shared/player/player_progress_bar.dart';
import 'package:tunify/ui/screens/shared/player/player_shared.dart';
import 'package:tunify/ui/shell/shell_context.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with SingleTickerProviderStateMixin {
  double _dragDy = 0;

  late AnimationController _artScaleCtrl;
  late Animation<double> _artScale;

  @override
  void initState() {
    super.initState();
    _artScaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0,
    );
    _artScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _artScaleCtrl, curve: Curves.easeOutCubic),
    );

    ref.listenManual(currentSongProvider, (_, next) {
      if (next != null) _fetchLyrics();
    });
    ref.listenManual(playerProvider.select((s) => s.isPlaying), (_, isPlaying) {
      if (isPlaying) {
        _artScaleCtrl.forward();
      } else {
        _artScaleCtrl.reverse();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchLyrics();
    });
  }

  void _fetchLyrics() {
    final song = ref.read(currentSongProvider);
    if (song != null) {
      ref.read(lyricsProvider.notifier).fetchForVideo(song.id);
    }
  }

  @override
  void dispose() {
    _artScaleCtrl.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final dominantColor = ref.watch(dominantColorProvider);

    final song = ref.watch(playerProvider.select((s) => s.currentSong));

    if (song == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Nothing playing',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: GestureDetector(
        onVerticalDragEnd: (d) {
          final velocity = d.primaryVelocity ?? 0;
          if (velocity > 600 || _dragDy > 100) {
            _dragDy = 0;
            _close();
          } else {
            _dragDy = 0;
          }
        },
        onVerticalDragUpdate: (d) {
          if (d.delta.dy > 0) _dragDy += d.delta.dy;
        },
        onVerticalDragCancel: () => _dragDy = 0,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: PlayerBlurredBackground(
                  url: song.thumbnailUrl,
                  dominantColor: dominantColor,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      _buildTopBar(),
                      const Spacer(flex: 2),
                      _buildAlbumArt(song, dominantColor),
                      const Spacer(flex: 2),
                      _buildSongInfo(song),
                      const SizedBox(height: AppSpacing.xxl),
                      const RepaintBoundary(child: PlayerProgressBar()),
                      const SizedBox(height: AppSpacing.lg),
                      RepaintBoundary(
                        child: PlayerControls(dominantColor: dominantColor),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildExtraControls(dominantColor),
                      const SizedBox(height: AppSpacing.base),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final status = ref.watch(playerProvider.select((s) => s.status));
    final label = switch (status) {
      PlayerStatus.loading || PlayerStatus.buffering => 'LOADING',
      PlayerStatus.paused => 'PAUSED',
      PlayerStatus.error => 'ERROR',
      _ => 'NOW PLAYING',
    };
    return Row(
      children: [
        PlayerGlassButton(
          icon: AppIcons.keyboardArrowDown,
          size: 24,
          onTap: _close,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xA6FFFFFF),
                  fontSize: AppFontSize.xs,
                  fontWeight: FontWeight.w600,
                  letterSpacing: AppLetterSpacing.label,
                ),
              ),
            ],
          ),
        ),
        PlayerGlassButton(
          icon: AppIcons.moreHoriz,
          size: 20,
          onTap: () {
            final currentSong = ref.read(playerProvider).currentSong;
            if (currentSong == null) return;
            showSongOptionsSheet(context, song: currentSong, ref: ref);
          },
        ),
      ],
    );
  }

  Widget _buildAlbumArt(Song song, Color dominantColor) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final artSize = screenWidth - (AppSpacing.xl * 2) - 32;
    final cachePx = (artSize * MediaQuery.devicePixelRatioOf(context)).round();

    return ScaleTransition(
      scale: _artScale,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          final notifier = ref.read(playerProvider.notifier);
          if (v < -400) {
            notifier.playNext();
          } else if (v > 400) {
            notifier.playPrevious();
          }
        },
        child: Hero(
          tag: 'player-album-art',
          flightShuttleBuilder: (_, anim, direction, __, ___) {
            final radius = Tween<double>(
              begin: direction == HeroFlightDirection.push
                  ? AppRadius.md
                  : AppRadius.xl,
              end: direction == HeroFlightDirection.push
                  ? AppRadius.xl
                  : AppRadius.md,
            ).animate(CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutCubic,
            ));
            return AnimatedBuilder(
              animation: radius,
              builder: (_, __) => ClipRRect(
                borderRadius: BorderRadius.circular(radius.value),
                child: song.thumbnailUrl.isEmpty
                    ? Container(
                        color: AppColors.surfaceLight,
                        child: AppIcon(
                            icon: AppIcons.musicNote,
                            color: AppColors.textMuted,
                            size: 80),
                      )
                    : CachedNetworkImage(
                        imageUrl: song.thumbnailUrl,
                        fit: BoxFit.contain,
                      ),
              ),
            );
          },
          child: Container(
            width: artSize,
            height: artSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: dominantColor.withValues(
                      alpha: PaletteTheme.playerArtGlowAlpha),
                  blurRadius: 50,
                  spreadRadius: 5,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: song.thumbnailUrl.isEmpty
                  ? Container(
                      width: artSize,
                      height: artSize,
                      color: AppColors.surfaceLight,
                      child: AppIcon(
                          icon: AppIcons.musicNote,
                          color: AppColors.textMuted,
                          size: 80),
                    )
                  : Container(
                      color: Colors.black.withValues(alpha: 0.22),
                      child: CachedNetworkImage(
                        imageUrl: song.thumbnailUrl,
                        width: artSize,
                        height: artSize,
                        memCacheWidth: cachePx,
                        memCacheHeight: cachePx,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => Container(
                          width: artSize,
                          height: artSize,
                          color: AppColors.surfaceLight,
                          child: AppIcon(
                              icon: AppIcons.musicNote,
                              color: AppColors.textMuted,
                              size: 80),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(Song song) {
    final isLiked = ref
        .watch(libraryProvider.select((s) => s.likedSongIds.contains(song.id)));
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppFontSize.h2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: AppLetterSpacing.heading,
                  height: AppLineHeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                song.artist,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppFontSize.xl,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        GestureDetector(
          onTap: () => ref.read(libraryProvider.notifier).toggleLiked(song),
          child: AnimatedSwitcher(
            duration: AppDuration.fast,
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: FavouriteIcon(
              key: ValueKey(isLiked),
              isLiked: isLiked,
              songId: song.id,
              size: 26,
              emptyColor: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  void _showQueueSheet() => showQueueSheet(context);
  void _showLyricsSheet(Color dominantColor) =>
      showLyricsSheet(context, dominantColor: dominantColor);
  void _showDevicesSheet() => showDevicesSheet(context);
  void _showSleepTimerSheet() => showSleepTimerSheet(context);

  Widget _buildExtraControls(Color dominantColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        PlayerExtraButton(
            icon: AppIcons.devices, label: 'Devices', onTap: _showDevicesSheet),
        PlayerExtraButton(
            icon: AppIcons.lyrics,
            label: 'Lyrics',
            onTap: () => _showLyricsSheet(dominantColor)),
        PlayerExtraButton(
            icon: AppIcons.queueMusic, label: 'Queue', onTap: _showQueueSheet),
        PlayerExtraButton(
            icon: AppIcons.bedtime,
            label: 'Sleep',
            onTap: _showSleepTimerSheet),
      ],
    );
  }
}

// ── Public sheet launchers — shared by PlayerScreen and DesktopPlayerBar ──────

void showQueueSheet(BuildContext context, {BuildContext? buttonContext}) {
  if (ShellContext.isDesktopPlatform) {
    _showDesktopQueuePanel(context, buttonContext: buttonContext);
    return;
  }
  showAppDraggableSheet(
    context,
    initialChildSize: 0.55,
    minChildSize: 0.3,
    maxChildSize: 0.85,
    builder: (scrollController) =>
        QueuePanelContent(scrollController: scrollController),
  );
}


void _showDesktopQueuePanel(BuildContext context,
    {BuildContext? buttonContext}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _DesktopQueueOverlay(
      onDismiss: () => entry.remove(),
      anchorContext: buttonContext,
    ),
  );
  overlay.insert(entry);
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
          AppColors.surface,
          AppColors.surface,
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
              color: AppColors.textPrimary.withValues(alpha: 0.95),
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
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: AppFontSize.base,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Minutes (e.g. 20)',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.6),
                          fontSize: AppFontSize.base,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceHighlight,
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
            color: AppColors.surface.withValues(alpha: 0.5),
            blurRadius: 40,
            spreadRadius: -8,
          ),
        ],
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceHighlight,
            AppColors.surface,
            AppColors.background,
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
                      color: AppColors.textPrimary,
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
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
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
                        color: AppColors.textSecondary,
                        size: 28,
                      ),
                      const SizedBox(height: AppSpacing.xs + 2),
                      Text(
                        'End of song',
                        style: TextStyle(
                          color:
                              AppColors.textSecondary.withValues(alpha: 0.95),
                          fontSize: AppFontSize.xs,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : AppIcon(
                    icon: AppIcons.bedtime,
                    color: AppColors.textPrimary.withValues(alpha: 0.85),
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
                ? AppColors.surfaceHighlight.withValues(alpha: 0.6)
                : AppColors.surfaceHighlight,
            border: Border.all(
              color: isCancel
                  ? AppColors.textMuted.withValues(alpha: 0.3)
                  : AppColors.glassBorder.withValues(alpha: 0.4),
              width: 0.6,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isCancel
                  ? AppColors.textMuted
                  : AppColors.textPrimary.withValues(alpha: 0.95),
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
      duration: const Duration(milliseconds: 1200),
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
                  color: AppColors.textPrimary,
                  size: 22),
              const SizedBox(width: AppSpacing.sm + 2),
              const Expanded(
                child: Text(
                  'Connect to a device',
                  style: TextStyle(
                    color: AppColors.textPrimary,
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
        const Divider(
          color: AppColors.surfaceHighlight,
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textMuted,
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
        const Divider(
          color: AppColors.surfaceHighlight,
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
                      ? AppColors.textMuted
                      : AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  _scanningNetwork ? 'Scanning...' : 'Scan',
                  style: TextStyle(
                    color: _scanningNetwork
                        ? AppColors.textMuted
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
              style: const TextStyle(
                color: AppColors.textMuted,
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
                  : AppColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: AppIcon(
              icon: icon,
              color: isActive ? accentColor : AppColors.textSecondary,
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
                    color: isActive ? accentColor : AppColors.textPrimary,
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
                        : AppColors.textMuted,
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
              color: AppColors.textMuted,
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
            color: color.withValues(alpha: 0.5),
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
          AppIcon(icon: icon, color: AppColors.textMuted, size: 28),
          const SizedBox(width: AppSpacing.md + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textMuted,
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
          const Text(
            'Scanning your network...',
            style: TextStyle(
              color: AppColors.textSecondary,
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
      duration: const Duration(milliseconds: 1200),
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
              const Text(
                'On Device',
                style: TextStyle(
                  color: AppColors.textMuted,
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
                    trackColor: AppColors.textMuted,
                    progressColor: AppColors.primary,
                    strokeWidth: 2,
                  ),
                );
              },
            ),
            AppIcon(
              icon: AppIcons.download,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      );
    } else {
      icon = AppIcon(
        icon: AppIcons.download,
        color: AppColors.textSecondary,
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
              style: const TextStyle(
                color: AppColors.textMuted,
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
    final currentSong = (currentIndex >= 0 && currentIndex < queue.length)
        ? queue[currentIndex]
        : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              kSheetHorizontalPadding, 16, kSheetHorizontalPadding, 8),
          child: Row(
            children: [
              AppIcon(
                  icon: AppIcons.queueMusic,
                  color: AppColors.textPrimary,
                  size: 22),
              const SizedBox(width: AppSpacing.sm + 2),
              const Text(
                'Queue',
                style: TextStyle(
                  color: AppColors.textPrimary,
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
                  style: const TextStyle(
                    color: AppColors.textSecondary,
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
                color: AppColors.textMuted,
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
                    style: const TextStyle(
                      color: AppColors.textSecondary,
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
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AppIcon(
                          icon: AppIcons.shuffle,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                        if (activeShuffleMode == ShuffleMode.smart)
                          const Positioned(
                            right: -3,
                            bottom: -3,
                            child: Icon(
                              Icons.auto_awesome,
                              size: 9,
                              color: AppColors.textSecondary,
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
                      color: AppColors.textSecondary,
                      fontSize: AppFontSize.md,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ReorderableListView.builder(
              scrollController: scrollController,
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.only(
                left: kSheetHorizontalPadding,
                right: kSheetHorizontalPadding,
                bottom: 32,
              ),
              itemCount: queue.isEmpty
                  ? 0
                  : (currentIndex >= 0)
                      ? queue.length - 1
                      : queue.length,
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
                final int actualIndex;
                if (currentIndex >= 0) {
                  actualIndex = i >= currentIndex ? i + 1 : i;
                } else {
                  actualIndex = i;
                }
                final song = queue[actualIndex];
                final smartIds = ref.watch(
                    playerProvider.select((s) => s.smartShuffleSongIds));
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
                        color: AppColors.textMuted,
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

class _DesktopQueueOverlay extends StatefulWidget {
  const _DesktopQueueOverlay({
    required this.onDismiss,
    this.anchorContext,
  });

  final VoidCallback onDismiss;
  final BuildContext? anchorContext;

  @override
  State<_DesktopQueueOverlay> createState() => _DesktopQueueOverlayState();
}

class _DesktopQueueOverlayState extends State<_DesktopQueueOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  )..forward();

  final _scrollController = ScrollController();

  void _dismiss() {
    _ctrl.reverse().then((_) => widget.onDismiss());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    const panelWidth = 340.0;
    const panelHeight = 480.0;

    // Position: bottom-right area near the player bar
    double left = screenSize.width - panelWidth - 16;
    double top = screenSize.height - panelHeight - 100; // above player bar

    // If anchor context provided, position near it
    if (widget.anchorContext != null) {
      final box = widget.anchorContext!.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final offset = box.localToGlobal(Offset.zero);
        left = (offset.dx - panelWidth + box.size.width)
            .clamp(8.0, screenSize.width - panelWidth - 8);
        top = offset.dy - panelHeight - 4;
        if (top < 8) top = offset.dy + box.size.height + 4;
      }
    }

    return Stack(
      children: [
        // Dismiss barrier
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _dismiss,
          ),
        ),
        // Panel
        Positioned(
          top: top,
          left: left,
          width: panelWidth,
          height: panelHeight,
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(
                CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
              ),
              alignment: Alignment.bottomRight,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: QueuePanelContent(
                      scrollController: _scrollController,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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
                    style: const TextStyle(
                      color: AppColors.textMuted,
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
                      color: AppColors.textMuted,
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
  ProviderSubscription<Duration>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _positionSubscription = ref.listenManual(
      playerProvider.select((s) => s.position),
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
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          alignment: 0.3,
        );
      }
    });
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
              const Text(
                'Lyrics',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppFontSize.xxl,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (lyricsState.hasLyrics && lyricsState.lyrics!.source != null)
                Text(
                  lyricsState.lyrics!.source!,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: AppFontSize.xs,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _buildLyricsContent(lyricsState),
        ),
      ],
    );
  }

  Widget _buildLyricsContent(LyricsState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(AppColors.textSecondary),
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
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                  size: 56),
              const SizedBox(height: AppSpacing.base),
              const Text(
                'Couldn\'t load lyrics',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppFontSize.xl,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.xs + 2),
              const Text(
                'A network error occurred. Tap to retry.',
                style: TextStyle(
                  color: AppColors.textMuted,
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
                    color: AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: AppColors.glassBorder.withValues(alpha: 0.4),
                      width: 0.6,
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      color: AppColors.textPrimary,
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
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                  size: 56),
              const SizedBox(height: AppSpacing.base),
              const Text(
                'No lyrics available.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppFontSize.xl,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.xs + 2),
              const Text(
                'Lyrics are not available for this song',
                style: TextStyle(
                  color: AppColors.textMuted,
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

    return AnimatedDefaultTextStyle(
      key: _lineKeys[index],
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      style: TextStyle(
        color: isSynced
            ? (isActive
                ? AppColors.textPrimary
                : AppColors.textPrimary.withValues(alpha: 0.3))
            : AppColors.textPrimary,
        fontSize: isActive ? 22 : 20,
        fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
        height: AppLineHeight.relaxed,
        letterSpacing: AppLetterSpacing.heading,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(line.text),
      ),
    );
  }
}
