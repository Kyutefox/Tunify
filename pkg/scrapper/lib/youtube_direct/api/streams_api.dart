import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:scrapper/models/youtube_stream.dart';

/// Fetches YouTube audio stream URLs by posting directly to the InnerTube
class StreamsApi {
  /// Posts to `music.youtube.com/youtubei/v1/player` with the exact headers
  /// with no cipher, n-transform, or PoToken needed.
  ///
  /// Tries ANDROID_VR 1.43.32 → ANDROID_VR 1.61.48 → IOS in order,
  /// stopping at the first client that returns a playable stream.
  static Future<YouTubeStream?> fetchBestAudioStreamDirect(
    String videoId, {
    bool preferAac = false,
    String? visitorData,
  }) async {
    const clients = [
      {
        'clientName': 'ANDROID_VR',
        'clientVersion': '1.43.32',
        'clientId': '28',
        'userAgent':
            'com.google.android.apps.youtube.vr.oculus/1.43.32 (Linux; U; Android 12; en_US; Quest 3; Build/SQ3A.220605.009.A1; Cronet/107.0.5284.2)',
        'osName': 'Android',
        'osVersion': '12',
        'deviceMake': 'Oculus',
        'deviceModel': 'Quest 3',
        'androidSdkVersion': '32',
      },
      {
        'clientName': 'ANDROID_VR',
        'clientVersion': '1.61.48',
        'clientId': '28',
        'userAgent':
            'com.google.android.apps.youtube.vr.oculus/1.61.48 (Linux; U; Android 12; en_US; Quest 3; Build/SQ3A.220605.009.A1; Cronet/132.0.6808.3)',
        'osName': 'Android',
        'osVersion': '12',
        'deviceMake': 'Oculus',
        'deviceModel': 'Quest 3',
        'androidSdkVersion': '32',
      },
      {
        'clientName': 'IOS',
        'clientVersion': '21.03.1',
        'clientId': '5',
        'userAgent':
            'com.google.ios.youtube/21.03.1 (iPhone16,2; U; CPU iOS 18_2 like Mac OS X;)',
      },
    ];

    const apiBase = 'https://music.youtube.com';

    for (final c in clients) {
      try {
        final clientName = c['clientName']!;
        final clientVersion = c['clientVersion']!;
        final clientId = c['clientId']!;
        final userAgent = c['userAgent']!;

        final clientContext = <String, dynamic>{
          'clientName': clientName,
          'clientVersion': clientVersion,
          'gl': 'US',
          'hl': 'en',
          if (visitorData != null && visitorData.isNotEmpty)
            'visitorData': visitorData,
          if (c['osName'] != null) 'osName': c['osName'],
          if (c['osVersion'] != null) 'osVersion': c['osVersion'],
          if (c['deviceMake'] != null) 'deviceMake': c['deviceMake'],
          if (c['deviceModel'] != null) 'deviceModel': c['deviceModel'],
          if (c['androidSdkVersion'] != null)
            'androidSdkVersion': c['androidSdkVersion'],
        };

        final body = jsonEncode({
          'context': {
            'client': clientContext,
            'user': {'onBehalfOfUser': null},
          },
          'videoId': videoId,
          'contentCheckOk': true,
          'racyCheckOk': true,
        });

        final uri = Uri.parse('$apiBase/youtubei/v1/player?prettyPrint=false');
        final response = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'X-Goog-Api-Format-Version': '1',
                'X-YouTube-Client-Name': clientId,
                'X-YouTube-Client-Version': clientVersion,
                'X-Origin': apiBase,
                'Referer': '$apiBase/',
                'User-Agent': userAgent,
                if (visitorData != null && visitorData.isNotEmpty)
                  'X-Goog-Visitor-Id': visitorData,
              },
              body: body,
            )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode != 200) continue;

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = data['playabilityStatus']?['status'] as String?;
        if (status != 'OK') continue;

        final adaptiveFormats =
            data['streamingData']?['adaptiveFormats'] as List?;
        if (adaptiveFormats == null) continue;

        // Audio-only: no width/height, and a direct url (no signatureCipher)
        final audioFormats = adaptiveFormats
            .cast<Map<String, dynamic>>()
            .where((f) => f['width'] == null && (f['url'] as String?) != null)
            .toList();

        if (audioFormats.isEmpty) continue;

        audioFormats.sort(
          (a, b) => ((a['bitrate'] as int?) ?? 0)
              .compareTo((b['bitrate'] as int?) ?? 0),
        );

        final Map<String, dynamic> best;
        if (preferAac) {
          final aac = audioFormats.where((f) {
            final mime = (f['mimeType'] as String?) ?? '';
            return mime.contains('mp4') ||
                mime.contains('m4a') ||
                mime.contains('aac');
          }).toList();
          best = aac.isNotEmpty ? aac.last : audioFormats.last;
        } else {
          best = audioFormats.last;
        }

        final url = best['url'] as String;
        final bitrateRaw = (best['bitrate'] as int?) ?? 128000;
        final kbps = bitrateRaw ~/ 1000;
        final mimeType =
            ((best['mimeType'] as String?) ?? 'audio/mp4').split(';').first;
        final lengthSeconds = int.tryParse(
          data['videoDetails']?['lengthSeconds']?.toString() ?? '',
        );
        final duration = (lengthSeconds != null && lengthSeconds > 0)
            ? Duration(seconds: lengthSeconds)
            : null;

        return YouTubeStream(
          itag: (best['itag'] as int?) ?? 0,
          url: url,
          quality: kbps >= 160
              ? 'high'
              : kbps >= 80
                  ? 'medium'
                  : 'low',
          qualityLabel: '${kbps}kbps',
          bitrate: kbps,
          mimeType: mimeType,
          width: null,
          height: null,
          duration: duration,
          contentLength: null,
          isAudioOnly: true,
        );
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}
