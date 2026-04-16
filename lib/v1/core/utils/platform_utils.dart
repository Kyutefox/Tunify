import 'dart:io';

/// True when running on iOS (Apple platform that prefers AAC
/// and uses AVFoundation for audio). macOS support removed.
bool get isApplePlatform => Platform.isIOS;
