import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v1/core/constants/app_strings.dart';
import 'package:tunify/v1/core/services/hive_service.dart';
import 'package:tunify/v1/core/services/shared_prefs_service.dart';
import 'package:tunify/v1/features/auth/auth_provider.dart';
import 'package:tunify/v1/features/settings/content_settings_provider.dart';
import 'package:tunify/v1/features/home/home_state_provider.dart';
import 'package:tunify/v1/features/library/library_provider.dart';
import 'package:tunify/v1/features/player/player_state_provider.dart';
import 'package:tunify/v1/features/search/recent_search_provider.dart';
import 'package:tunify/v1/ui/shell/mobile_shell.dart';
import 'package:tunify/v1/features/settings/theme_provider.dart';
import 'package:tunify/v1/ui/theme/app_theme.dart';
import 'package:tunify/v1/ui/system/keyboard_insets_unmask.dart';
import 'package:tunify/v1/features/player/audio/audio_handler.dart';
import 'package:tunify/v1/features/player/audio/crossfade_engine.dart';
import 'package:tunify/v1/features/player/audio/audio_player_service.dart';
import 'package:tunify/v1/features/carplay/carplay_provider.dart';
import 'package:tunify/v1/core/utils/app_log.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Future.wait([
      HiveService.instance.init(),
      SharedPrefsService.instance.init(),
    ]);

    final crossfadeEngine = CrossfadeEngine(AudioPlayerService());

    // SystemChrome APIs are mobile-only (Android/iOS status bar + nav bar).
    if (Platform.isAndroid || Platform.isIOS) {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF121212),
        systemNavigationBarIconBrightness: Brightness.light,
      ));
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    runApp(ProviderScope(
      overrides: [
        crossfadeEngineProvider.overrideWithValue(crossfadeEngine),
      ],
      child: TunifyApp(crossfadeEngine: crossfadeEngine),
    ));
  }, (error, stack) {
    if (error is SocketException) {
      logWarning('Background SocketException (suppressed): $error',
          tag: 'Audio');
      return;
    }
    logError('Unhandled error in main zone: $error\n$stack', tag: 'Main');
  });
}

class TunifyApp extends ConsumerStatefulWidget {
  const TunifyApp({super.key, required this.crossfadeEngine});

  final CrossfadeEngine crossfadeEngine;

  @override
  ConsumerState<TunifyApp> createState() => _TunifyAppState();
}

class _TunifyAppState extends ConsumerState<TunifyApp> {
  @override
  void initState() {
    super.initState();
    _initAudioService();
  }

  Future<void> _initAudioService() async {
    TunifyAudioHandler? handler;
    try {
      handler = await AudioService.init(
        builder: () => TunifyAudioHandler(widget.crossfadeEngine),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.tunify.audio',
          androidNotificationChannelName: 'Tunify Playback',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
          androidNotificationIcon: 'mipmap/ic_launcher',
        ),
      ).timeout(const Duration(seconds: 10));
    } on StateError catch (e) {
      logWarning('AudioService already initialised ($e)', tag: 'AudioService');
    } catch (e) {
      logError('AudioService init failed: $e', tag: 'AudioService');
    }
    if (handler != null && mounted) {
      ref.read(audioHandlerProvider.notifier).setHandler(handler);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const _TunifyAppContent();
  }
}

class _TunifyAppContent extends ConsumerWidget {
  const _TunifyAppContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    if (Platform.isIOS) {
      ref.read(carPlayProvider);
    }

    ref.listen<bool>(
      guestModeProvider,
      (prev, next) {
        if (prev == next) return;
        if (!ref.exists(homeProvider)) return;
        ref.read(homeProvider.notifier).onAuthChanged();
        ref.read(libraryProvider.notifier).onAuthChanged();
        ref.read(recentSearchProvider.notifier).onAuthChanged();
        ref.read(showExplicitContentProvider.notifier).onAuthChanged();
      },
    );

    Widget shell() => const MobileShell();

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) => _NoKeyboardShift(child: child),
      home: shell(),
    );
  }
}

/// Keeps all content fixed when the keyboard opens; keyboard draws above content.
class _NoKeyboardShift extends ConsumerStatefulWidget {
  const _NoKeyboardShift({this.child});

  final Widget? child;

  @override
  ConsumerState<_NoKeyboardShift> createState() => _NoKeyboardShiftState();
}

class _NoKeyboardShiftState extends ConsumerState<_NoKeyboardShift> {
  Size? _cachedSize;
  EdgeInsets? _cachedViewPadding;

  @override
  Widget build(BuildContext context) {
    final unmaskCount = ref.watch(keyboardInsetsUnmaskCountProvider);
    final mq = MediaQuery.of(context);

    if (unmaskCount > 0) {
      return widget.child ?? const SizedBox.shrink();
    }

    final keyboardHeight = mq.viewInsets.bottom;

    if (keyboardHeight == 0) {
      if (_cachedSize != mq.size || _cachedViewPadding != mq.viewPadding) {
        _cachedSize = mq.size;
        _cachedViewPadding = mq.viewPadding;
      }
    }

    final size = _cachedSize ?? mq.size;
    final viewPadding = _cachedViewPadding ?? mq.viewPadding;

    return MediaQuery(
      data: mq.copyWith(
        viewInsets: EdgeInsets.zero,
        size: size,
        viewPadding: viewPadding,
        padding: viewPadding,
      ),
      child: widget.child ?? const SizedBox.shrink(),
    );
  }
}
