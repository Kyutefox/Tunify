import 'package:tunify/data/models/audio_quality.dart';

/// Effective stream tier used for player state / quality notifier (not InnerTube labels).
enum StreamQuality {
  low,
  medium,
  high,
  auto,
}

StreamQuality streamQualityFromAudioQuality(AudioQuality q) {
  switch (q) {
    case AudioQuality.low:
      return StreamQuality.low;
    case AudioQuality.medium:
      return StreamQuality.medium;
    case AudioQuality.high:
    case AudioQuality.auto:
      return StreamQuality.high;
  }
}
