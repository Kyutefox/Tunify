import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/core/constants/app_strings.dart';
import 'package:tunify/core/services/hive_service.dart';
import 'package:tunify/core/services/shared_prefs_service.dart';
import 'package:tunify/ui/widgets/common/button.dart';
import 'package:tunify/features/auth/auth_provider.dart';
import 'package:tunify/features/settings/content_settings_provider.dart';
import 'package:tunify/features/home/home_state_provider.dart';
import 'package:tunify/features/library/library_provider.dart';
import 'package:tunify/features/library/collection_track_cache.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/features/search/recent_search_provider.dart';
import 'package:tunify/data/repositories/database_repository.dart';
import 'package:tunify/features/player/audio/audio_handler.dart';
import 'package:tunify/features/player/audio/crossfade_engine.dart';
import 'package:tunify/features/player/audio/audio_player_service.dart';
import 'package:tunify/features/carplay/carplay_provider.dart';
import 'package:tunify_logger/tunify_logger.dart';
import 'package:tunify/data/databases/supabase/supabase_prefs.dart';
import 'package:tunify/ui/shell/desktop_shell.dart';
import 'package:tunify/ui/shell/mobile_shell.dart';
import 'package:tunify/ui/screens/shared/auth/loading_screen.dart';
import 'package:tunify/ui/screens/shared/auth/welcome_screen.dart';
import 'package:tunify/features/settings/theme_provider.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_theme.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

final supabaseInitProvider = FutureProvider<void>((ref) async {
  try {
    final url = await getEffectiveSupabaseUrl();
    final anonKey = await getEffectiveSupabaseAnonKey();
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );
  } catch (e, st) {
    logError('Supabase initialization failed: $e\n$st', tag: 'Init');
    rethrow;
  }
});

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
      // audio_service throws StateError("init() may only be called once") on
      // hot restart. In that case the handler already exists on the native side
      // but Dart lost the reference — log and continue without controls.
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

    // Initialize CarPlay service for iOS
    if (Platform.isIOS) {
      ref.read(carPlayProvider);
    }

    final init = ref.watch(supabaseInitProvider);

    if (init.isLoading) {
      return MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        builder: _noKeyboardShiftBuilder,
        home: const LoadingScreen(),
      );
    }

    if (init.hasError) {
      return MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        builder: _noKeyboardShiftBuilder,
        home: _InitErrorScreen(
          onRetry: () => ref.invalidate(supabaseInitProvider),
        ),
      );
    }

    // Wait until the auth session stream emits once so restored sessions
    // route directly to home instead of briefly showing welcome.
    final authSession = ref.watch(authSessionProvider);
    if (authSession.isLoading) {
      return MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        builder: _noKeyboardShiftBuilder,
        home: const LoadingScreen(),
      );
    }

    final user = ref.watch(currentUserProvider);
    final isGuest = ref.watch(guestModeProvider);
    final isHydrating = ref.watch(databaseHydrationInProgressProvider);

    // Ensure sync is started whenever we have a logged-in user (covers restored session on app open).
    if (user != null && !isGuest) {
      ref.read(syncManagerProvider).start(user.id);
    }

    // On login: pull from Supabase into SQLite once, then start sync and reload UI. On logout: stop sync. SQLite is source of truth.
    ref.listen<User?>(
      currentUserProvider,
      (User? prev, User? next) {
        final idChanged = prev?.id != next?.id;
        final hadLoginOrLogout = prev != null || next != null;
        if (idChanged && hadLoginOrLogout) {
          if (next != null) {
            final bridge = ref.read(databaseBridgeProvider);
            final syncManager = ref.read(syncManagerProvider);
            ref.read(databaseHydrationInProgressProvider.notifier).set(true);
            // Await pull so SQLite is filled before providers reload; then start sync and notify.
            bridge.pullFromSupabase(next.id).then((_) async {
              if (ref.read(currentUserProvider)?.id != next.id) return;
              ref.read(databaseHydrationInProgressProvider.notifier).set(false);
              if (!ref.exists(homeProvider)) return;
              try {
                await ref.read(homeProvider.notifier).prepareHomeForLogin();
              } catch (e) {
                logWarning('Auth: prepareHomeForLogin failed ($e), continuing',
                    tag: 'Auth');
              }
              if (ref.read(currentUserProvider)?.id != next.id) return;
              syncManager.start(next.id);
              ref.read(homeProvider.notifier).onAuthChanged(next);
              ref.read(libraryProvider.notifier).onAuthChanged(next);
              ref.read(recentSearchProvider.notifier).onAuthChanged();
              ref.read(showExplicitContentProvider.notifier).onAuthChanged();
            }).catchError((e, st) {
              logWarning(
                  'Auth: pullFromSupabase failed ($e), continuing with local data',
                  tag: 'Auth');
              if (ref.read(currentUserProvider)?.id != next.id) return;
              ref.read(databaseHydrationInProgressProvider.notifier).set(false);
              if (!ref.exists(homeProvider)) return;
              // Still let user in; start sync and reload with whatever is in SQLite
              syncManager.start(next.id);
              ref.read(homeProvider.notifier).onAuthChanged(next);
              ref.read(libraryProvider.notifier).onAuthChanged(next);
              ref.read(recentSearchProvider.notifier).onAuthChanged();
              ref.read(showExplicitContentProvider.notifier).onAuthChanged();
            });
          } else {
            ref.read(syncManagerProvider).stop();
            ref.read(databaseHydrationInProgressProvider.notifier).set(false);
            // Flush cached stream URLs on logout — they are tied to session
            // cookies and would fail or serve wrong content for the next user.
            ref.read(streamManagerProvider).clearCache();
            CollectionTrackCache.instance.clear();
            ref.read(homeProvider.notifier).onAuthChanged(next);
            ref.read(libraryProvider.notifier).onAuthChanged(next);
            ref.read(recentSearchProvider.notifier).onAuthChanged();
            ref.read(showExplicitContentProvider.notifier).onAuthChanged();
          }
        }
      },
    );

    // Use the Spotify-style desktop shell on macOS; the standard mobile
    // shell (bottom nav + mini player) on iOS and Android.
    Widget shell() =>
        Platform.isMacOS ? const DesktopShell() : const MobileShell();

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: _noKeyboardShiftBuilder,
      home: isGuest
          ? shell()
          : (user == null
              ? const WelcomeScreen()
              : (isHydrating ? const LoadingScreen() : shell())),
    );
  }
}

/// Keeps all content fixed when the keyboard opens; keyboard draws above content.
/// Caches size, viewPadding, and padding when keyboard is closed and reuses them
/// when open so nothing shifts, stretches, or moves across all screens.
/// Zeroing viewInsets prevents Scaffold resize; freezing padding prevents
/// SafeArea from shifting when padding.bottom drops to 0 as keyboard covers
/// the home indicator.
Widget _noKeyboardShiftBuilder(BuildContext context, Widget? child) {
  return _NoKeyboardShift(child: child);
}

class _NoKeyboardShift extends StatefulWidget {
  const _NoKeyboardShift({this.child});

  final Widget? child;

  @override
  State<_NoKeyboardShift> createState() => _NoKeyboardShiftState();
}

class _NoKeyboardShiftState extends State<_NoKeyboardShift> {
  Size? _cachedSize;
  EdgeInsets? _cachedViewPadding;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboardHeight = mq.viewInsets.bottom;

    if (keyboardHeight == 0) {
      // Only write cache when values actually changed — avoids unnecessary
      // field assignments on every build pass when keyboard is hidden.
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

class _InitErrorScreen extends StatelessWidget {
  const _InitErrorScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsScheme.of(context).background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                icon: AppIcons.cloudOff,
                color: AppColorsScheme.of(context).textMuted,
                size: 42,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Unable to initialize services',
                style: TextStyle(
                  color: AppColorsScheme.of(context).textPrimary,
                  fontSize: AppFontSize.xl,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Please check your connection and try again.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: AppColorsScheme.of(context).textSecondary),
              ),
              const SizedBox(height: AppSpacing.base),
              AppButton(
                label: 'Retry',
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
