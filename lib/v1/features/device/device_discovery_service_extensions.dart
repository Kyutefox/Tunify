import 'package:tunify/v1/core/constants/app_icons.dart';
import 'package:tunify/v1/features/device/device_discovery_service.dart';

extension AudioDeviceTypeExtension on AudioDeviceType {
  List<List<dynamic>> get icon {
    switch (this) {
      case AudioDeviceType.thisDevice:
        return AppIcons.smartphone;
      case AudioDeviceType.bluetooth:
        return AppIcons.bluetooth;
      case AudioDeviceType.wired:
        return AppIcons.headphones;
      case AudioDeviceType.chromecast:
        return AppIcons.cast;
      case AudioDeviceType.dlna:
        return AppIcons.tv;
      case AudioDeviceType.airplay:
        return AppIcons.airplay;
    }
  }

  String get subtitle {
    switch (this) {
      case AudioDeviceType.thisDevice:
        return 'Phone speaker';
      case AudioDeviceType.bluetooth:
        return 'Bluetooth';
      case AudioDeviceType.wired:
        return 'Wired';
      case AudioDeviceType.chromecast:
        return 'Google Cast';
      case AudioDeviceType.dlna:
        return 'DLNA';
      case AudioDeviceType.airplay:
        return 'AirPlay';
    }
  }
}
