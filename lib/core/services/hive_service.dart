import 'package:hive_flutter/hive_flutter.dart';
import 'package:tunify_logger/tunify_logger.dart';

/// Centralized Hive box management to prevent repeated box opening.
/// All boxes are opened once at app startup and cached for the app lifetime.
class HiveService {
  static HiveService? _instance;
  static HiveService get instance => _instance ??= HiveService._();

  HiveService._();

  Box<dynamic>? _playerStateBox;
  Box<dynamic>? _homeFeedBox;
  Box<dynamic>? _streamUrlsBox;

  /// Initialize all Hive boxes at app startup.
  /// This prevents blocking UI operations later.
  Future<void> init() async {
    try {
      await Hive.initFlutter();

      // Open all boxes in parallel
      final results = await Future.wait([
        Hive.openBox<dynamic>('player_state'),
        Hive.openBox<dynamic>('home_feed'),
        Hive.openBox<dynamic>('stream_urls'),
      ]);

      _playerStateBox = results[0];
      _homeFeedBox = results[1];
      _streamUrlsBox = results[2];
    } catch (e) {
      logWarning('HiveService: Failed to open boxes - $e', tag: 'HiveService');
    }
  }

  Box<dynamic>? get playerStateBox => _playerStateBox;
  Box<dynamic>? get homeFeedBox => _homeFeedBox;
  Box<dynamic>? get streamUrlsBox => _streamUrlsBox;

  /// Close all boxes (call on app dispose)
  Future<void> dispose() async {
    await Future.wait([
      _playerStateBox?.close() ?? Future.value(),
      _homeFeedBox?.close() ?? Future.value(),
      _streamUrlsBox?.close() ?? Future.value(),
    ]);
  }
}
