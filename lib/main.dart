import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tunify/config/app_icons.dart';
import 'package:tunify/config/app_strings.dart';
import 'package:tunify/shared/providers/auth_provider.dart';
import 'package:tunify/shared/providers/connectivity_provider.dart';
import 'package:tunify/shared/providers/content_settings_provider.dart';
import 'package:tunify/shared/providers/home_state_provider.dart';
import 'package:tunify/shared/providers/library_provider.dart';
import 'package:tunify/shared/providers/player_state_provider.dart';
import 'package:tunify/shared/providers/recent_search_provider.dart';
import 'package:tunify/shared/providers/search_provider.dart';
import 'package:tunify/system/bridges/database_repository.dart';
import 'package:tunify/shared/services/audio/audio_handler.dart';
import 'package:tunify/shared/services/audio/audio_player_service.dart';
import 'package:tunify_logger/tunify_logger.dart';
import 'package:tunify/system/databases/supabase/supabase_prefs.dart';
import 'package:tunify/ui/components/ui/button.dart';
import 'package:tunify/ui/components/ui/sheet.dart';
import 'package:tunify/ui/components/ui/widgets/mini_player.dart';
import 'package:tunify/ui/screens/home_screen.dart';
import 'package:tunify/ui/screens/library/create_library_item_screen.dart';
import 'package:tunify/ui/screens/library_screen.dart';
import 'package:tunify/ui/screens/loading_screen.dart';
import 'package:tunify/ui/screens/search_screen.dart';
import 'package:tunify/ui/screens/welcome_screen.dart';
import 'package:tunify/ui/theme/app_theme.dart';
import 'package:tunify/ui/theme/app_colors.dart';

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

    final audioPlayerService = AudioPlayerService();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF121212),
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    runApp(ProviderScope(
      overrides: [
        audioPlayerServiceProvider.overrideWithValue(audioPlayerService),
      ],
      child: TunifyApp(audioPlayerService: audioPlayerService),
    ));
  }, (error, stack) {
    if (error is SocketException) {
      logWarning('Background SocketException (suppressed): $error', tag: 'Audio');
      return;
    }
    logError('Unhandled error in main zone: $error\n$stack', tag: 'Main');
  });
}

class TunifyApp extends ConsumerStatefulWidget {
  const TunifyApp({super.key, required this.audioPlayerService});

  final AudioPlayerService audioPlayerService;

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
        builder: () => TunifyAudioHandler(widget.audioPlayerService),
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
    final init = ref.watch(supabaseInitProvider);

    if (init.isLoading) {
      return MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        builder: _noKeyboardShiftBuilder,
        home: const LoadingScreen(),
      );
    }

    if (init.hasError) {
      return MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
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
        theme: AppTheme.darkTheme,
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
            ref.read(databaseHydrationInProgressProvider.notifier).state = true;
            // Await pull so SQLite is filled before providers reload; then start sync and notify.
            bridge.pullFromSupabase(next.id).then((_) async {
              if (!ref.exists(homeProvider)) return;
              if (ref.read(currentUserProvider)?.id != next.id) return;
              try {
                await ref.read(homeProvider.notifier).prepareHomeForLogin();
              } catch (e) {
                logWarning('Auth: prepareHomeForLogin failed ($e), continuing', tag: 'Auth');
              }
              if (ref.read(currentUserProvider)?.id != next.id) return;
              ref.read(databaseHydrationInProgressProvider.notifier).state = false;
              syncManager.start(next.id);
              ref.read(homeProvider.notifier).onAuthChanged(next);
              ref.read(libraryProvider.notifier).onAuthChanged(next);
              ref.read(recentSearchProvider.notifier).onAuthChanged();
              ref.read(showExplicitContentProvider.notifier).onAuthChanged();
              ref.read(smartRecommendationShuffleProvider.notifier).onAuthChanged();
            }).catchError((e, st) {
              if (!ref.exists(homeProvider)) return;
              logWarning('Auth: pullFromSupabase failed ($e), continuing with local data', tag: 'Auth');
              if (ref.read(currentUserProvider)?.id == next.id) {
                ref.read(databaseHydrationInProgressProvider.notifier).state = false;
              }
              // Still let user in; start sync and reload with whatever is in SQLite
              syncManager.start(next.id);
              ref.read(homeProvider.notifier).onAuthChanged(next);
              ref.read(libraryProvider.notifier).onAuthChanged(next);
              ref.read(recentSearchProvider.notifier).onAuthChanged();
              ref.read(showExplicitContentProvider.notifier).onAuthChanged();
              ref.read(smartRecommendationShuffleProvider.notifier).onAuthChanged();
            });
          } else {
            ref.read(syncManagerProvider).stop();
            ref.read(databaseHydrationInProgressProvider.notifier).state = false;
            // Flush cached stream URLs on logout — they are tied to session
            // cookies and would fail or serve wrong content for the next user.
            ref.read(streamManagerProvider).clearCache();
            ref.read(homeProvider.notifier).onAuthChanged(next);
            ref.read(libraryProvider.notifier).onAuthChanged(next);
            ref.read(recentSearchProvider.notifier).onAuthChanged();
            ref.read(showExplicitContentProvider.notifier).onAuthChanged();
            ref.read(smartRecommendationShuffleProvider.notifier).onAuthChanged();
          }
        }
      },
    );

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: _noKeyboardShiftBuilder,
      home: isGuest
          ? const AppShell()
          : (user == null
              ? const WelcomeScreen()
              : (isHydrating ? const LoadingScreen() : const AppShell())),
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

// ── App Shell ─────────────────────────────────────────────────────────────────

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// Page index in the IndexedStack: 0=Home, 1=Search, 2=Library, 3=DeviceMusic
  int _selectedIndex = 0;

  // Nav icon list is final — hoist to avoid per-build List allocation.
  // AppIcons uses getters (not const), so static final is used instead of const.
  static final _navIcons = [
    AppIcons.home,
    AppIcons.search,
    AppIcons.library,
    AppIcons.add,
  ];

  @override
  Widget build(BuildContext context) {
    final isGuest = ref.watch(guestModeProvider);
    final homeIsLoading = ref.watch(homeIsLoadingProvider);
    final homeIsLoaded = ref.watch(homeIsLoadedProvider);
    final hasSong = ref.watch(currentSongProvider) != null;

    final showGuestHomeFullScreenLoading =
        isGuest && _selectedIndex == 0 && homeIsLoading && !homeIsLoaded;

    if (showGuestHomeFullScreenLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingScreen(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Offline banner — isolated ConsumerWidget so only the banner rebuilds
          // on connectivity changes, not the entire AppShell.
          const _OfflineBanner(),
          // IndexedStack preserves tab state (scroll position, loaded data)
          // across navigation — screens are built once and kept alive.
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [HomeScreen(), SearchScreen(), LibraryScreen()],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Persistent mini player sits above the nav bar
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => SizeTransition(
              sizeFactor: CurvedAnimation(
                parent: anim,
                curve: Curves.easeOut,
              ),
              axisAlignment: -1,
              child: child,
            ),
            child: hasSong
                ? const MiniPlayer(key: ValueKey('mini-player'))
                : const SizedBox.shrink(key: ValueKey('hidden')),
          ),
          _buildNavBar(),
        ],
      ),
    );
  }

  void _showCreateSheet() {
    showAppSheet(
      context,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kSheetHorizontalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetOptionTile(
              icon: AppIcons.playlistAdd,
              label: 'Create playlist',
              showChevron: false,
              onTap: () async {
                Navigator.of(context).pop();
                final name = await Navigator.of(context).push<String>(
                  MaterialPageRoute<String>(
                    builder: (_) => const CreateLibraryItemScreen(
                      mode: CreateLibraryItemMode.createPlaylist,
                    ),
                  ),
                );
                if (name != null && name.trim().isNotEmpty && mounted) {
                  await ref
                      .read(libraryProvider.notifier)
                      .createPlaylist(name.trim());
                }
              },
            ),
            SheetOptionTile(
              icon: AppIcons.newFolder,
              label: 'Create folder',
              showChevron: false,
              onTap: () async {
                Navigator.of(context).pop();
                final name = await Navigator.of(context).push<String>(
                  MaterialPageRoute<String>(
                    builder: (_) => const CreateLibraryItemScreen(
                      mode: CreateLibraryItemMode.createFolder,
                    ),
                  ),
                );
                if (name != null && name.trim().isNotEmpty && mounted) {
                  await ref
                      .read(libraryProvider.notifier)
                      .createFolder(name.trim());
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBar() {
    // Nav order: Home, Search, Library, + (create)
    // The + button (index 3) is modal — doesn't map to a page.
    // Page indices: 0=Home, 1=Search, 2=Library

    /// Map nav bar index → page index (-1 for modal-only items).
    const navToPage = [0, 1, 2, -1];

    /// Map page index → nav bar index for highlighting.
    const pageToNav = [0, 1, 2];

    final activeNavIndex =
        _selectedIndex >= 0 && _selectedIndex < pageToNav.length
            ? pageToNav[_selectedIndex]
            : 0;

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 56 + bottomPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.glassBorder,
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding > 0 ? bottomPadding : 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(4, (i) {
            final selected = activeNavIndex == i;
            final isCreate = i == 3;

            return Expanded(
              child: isCreate
                  ? _NavCreateButton(onTap: _showCreateSheet)
                  : _NavItem(
                      icon: _navIcons[i],
                      selected: selected,
                      onTap: () {
                        final pageIndex = navToPage[i];
                        if (pageIndex < 0) return;
                        if (_selectedIndex == 1 && pageIndex != 1) {
                          ref.read(searchProvider.notifier).search('');
                        }
                        final wasOnHome = _selectedIndex == 0;
                        setState(() => _selectedIndex = pageIndex);
                        if (pageIndex == 0 && !wasOnHome) {
                          ref.read(homeProvider.notifier).refresh();
                        }
                      },
                    ),
            );
          }),
        ),
      ),
    );
  }
}

/// Watches [connectivityProvider] in isolation so only this widget rebuilds
/// on network changes, not the entire [AppShell].
class _OfflineBanner extends ConsumerWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider).maybeWhen(
      data: (connected) => connected,
      orElse: () => true,
    );

    if (isOnline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orangeAccent.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 18, color: Colors.orangeAccent),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "You're offline — some features may be limited",
              style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final bool selected;
  final VoidCallback onTap;

  static const double _iconSize = 24.0;
  static const double _circleSize = 40.0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: AppColors.primary.withValues(alpha: 0.12),
          highlightColor: AppColors.primary.withValues(alpha: 0.06),
          child: SizedBox(
            width: _circleSize,
            height: _circleSize,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: _circleSize,
                height: _circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : Colors.transparent,
                ),
                child: Center(
                  child: AppIcon(
                    icon: icon,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textMuted,
                    size: _iconSize,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavCreateButton extends StatelessWidget {
  const _NavCreateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.primary.withValues(alpha: 0.3),
          highlightColor: AppColors.primary.withValues(alpha: 0.2),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: AppIcon(
                icon: AppIcons.add,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InitErrorScreen extends StatelessWidget {
  const _InitErrorScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                icon: AppIcons.cloudOff,
                color: AppColors.textMuted,
                size: 42,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to initialize services',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
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
