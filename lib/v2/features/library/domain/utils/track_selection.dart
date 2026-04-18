import 'dart:math';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';

/// Utility functions for track selection in the library domain layer.
class TrackSelection {
  /// Returns a random track thumb URL from the given details.
  /// Returns null if no tracks have valid thumb URLs.
  static String? getRandomTrackThumbUrl(LibraryDetailsModel details) {
    final tracksWithThumbs = details.tracks
        .where((t) => t.thumbUrl != null && t.thumbUrl!.isNotEmpty)
        .toList();
    
    if (tracksWithThumbs.isEmpty) return null;
    
    final random = Random();
    final randomTrack = tracksWithThumbs[random.nextInt(tracksWithThumbs.length)];
    return randomTrack.thumbUrl;
  }
}
