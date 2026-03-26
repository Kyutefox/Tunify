import 'dart:io';

/// True when running on iOS or macOS (Apple platforms that prefer AAC
/// and use AVFoundation for audio).
bool get isApplePlatform => Platform.isIOS || Platform.isMacOS;
