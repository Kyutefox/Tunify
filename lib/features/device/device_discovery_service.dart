import 'dart:async';
import 'dart:io';

import 'package:chromecast_dlna_finder/chromecast_dlna_finder.dart';
import 'package:flutter/services.dart';

import 'package:tunify_logger/tunify_logger.dart';

/// Categories of audio output devices.
enum AudioDeviceType { thisDevice, bluetooth, wired, chromecast, dlna, airplay }

/// Represents a discovered audio output device (local, Bluetooth, or network).
class AudioDevice {
  final String id;
  final String name;
  final AudioDeviceType type;
  final String? subtype;
  final String? ip;
  final bool isActive;

  const AudioDevice({
    required this.id,
    required this.name,
    required this.type,
    this.subtype,
    this.ip,
    this.isActive = false,
  });
}

/// Discovers available audio output devices: Bluetooth via a native method channel,
/// and Chromecast/DLNA/AirPlay via mDNS network scan.
class DeviceDiscoveryService {
  static const _channel = MethodChannel('com.kyutefox.tunify/audio_devices');
  ChromecastDlnaFinder? _finder;

  Future<List<AudioDevice>> getConnectedBluetoothDevices() async {
    try {
      final result = await _channel
          .invokeListMethod<Map>('getConnectedBluetoothAudioDevices');
      if (result == null) return [];
      return result.map((d) {
        final map = Map<String, dynamic>.from(d);
        return AudioDevice(
          id: map['id'] as String? ?? 'bt-unknown',
          name: map['name'] as String? ?? 'Bluetooth Device',
          type: AudioDeviceType.bluetooth,
          subtype: map['subtype'] as String?,
          isActive: map['isActive'] as bool? ?? false,
        );
      }).toList();
    } on PlatformException {
      return [];
    } on MissingPluginException {
      return [];
    }
  }

  Future<AudioDevice> getActiveDevice() async {
    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('getActiveAudioDevice');
      if (result == null) {
        return const AudioDevice(
          id: 'this-device',
          name: 'This Device',
          type: AudioDeviceType.thisDevice,
          isActive: true,
        );
      }
      final typeStr = result['type'] as String? ?? 'speaker';
      AudioDeviceType type;
      switch (typeStr) {
        case 'bluetooth':
          type = AudioDeviceType.bluetooth;
          break;
        case 'wired':
          type = AudioDeviceType.wired;
          break;
        default:
          type = AudioDeviceType.thisDevice;
      }
      return AudioDevice(
        id: 'active',
        name: result['name'] as String? ?? 'This Device',
        type: type,
        isActive: true,
      );
    } catch (e) {
      return const AudioDevice(
        id: 'this-device',
        name: 'This Device',
        type: AudioDeviceType.thisDevice,
        isActive: true,
      );
    }
  }

  Future<void> openBluetoothSettings() async {
    if (Platform.isMacOS) {
      // macOS: open the Bluetooth pane in System Settings / System Preferences.
      // Try the macOS 13+ URL first; fall back to the legacy pane path.
      try {
        final result = await Process.run('open', [
          'x-apple.systempreferences:com.apple.Bluetooth-Settings.extension',
        ]);
        if (result.exitCode != 0) {
          await Process.run('open', [
            'x-apple.systempreferences:com.apple.preferences.Bluetooth',
          ]);
        }
      } catch (e) {
        logWarning('DeviceDiscovery: openBluetoothSettings (macOS) failed: $e',
            tag: 'DeviceDiscovery');
      }
      return;
    }
    try {
      await _channel.invokeMethod<bool>('openBluetoothSettings');
    } on MissingPluginException {
      // Channel not implemented on this platform — silently no-op.
    } catch (e) {
      logWarning('DeviceDiscovery: openBluetoothSettings failed: $e',
          tag: 'DeviceDiscovery');
    }
  }

  Future<List<AudioDevice>> scanNetworkDevices({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final devices = <AudioDevice>[];
    try {
      // Always recreate: ChromecastDlnaFinder stops its internal MDnsClient
      // after each scan, so reusing the same instance causes
      // "mDNS client must be started before calling lookup" on the next call.
      _finder?.dispose();
      _finder = ChromecastDlnaFinder();
      final result = await _finder!.findDevices(scanDuration: timeout);

      final all = result['all'] as List<dynamic>? ?? [];
      for (final d in all) {
        if (d is! DiscoveredDevice) continue;
        AudioDeviceType type;
        if (d.isChromecast) {
          type = AudioDeviceType.chromecast;
        } else if (d.isDlnaRenderer || d.isDlnaMediaServer) {
          type = AudioDeviceType.dlna;
        } else if (d.isAirplay) {
          type = AudioDeviceType.airplay;
        } else {
          continue;
        }
        devices.add(AudioDevice(
          id: d.id ?? d.ip,
          name: d.friendlyName ?? d.name,
          type: type,
          subtype: d.model,
          ip: d.ip,
        ));
      }
    } catch (e) {
      logWarning('DeviceDiscovery: scanNetworkDevices failed: $e', tag: 'DeviceDiscovery');
    }
    return devices;
  }

  void dispose() {
    _finder?.dispose();
    _finder = null;
  }
}
