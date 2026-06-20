import 'dart:convert';
import 'package:http/http.dart' as http;

class StreamingService {
  static Map<String, dynamic>? _instancesCache;
  static int _instancesCacheTime = 0;
  static const int _cacheDuration = 5 * 60 * 1000; // 5 mins

  static const List<String> _defaultPipedInstances = [
    "https://api.piped.private.coffee",
    "https://pipedapi.darkness.services",
    "https://pipedapi.r4fo.com",
    "https://api.piped.yt",
    "https://pipedapi.kavin.rocks",
    "https://pipedapi.adminforge.de",
    "https://pipedapi.in.projectsegfau.lt",
    "https://api.piped.projectsegfau.lt",
    "https://pipedapi.leptons.xyz",
  ];

  static const List<String> _defaultInvidiousInstances = [
    "https://yt.omada.cafe",
    "https://y.com.sb",
    "https://inv.nadeko.net"
  ];

  static Future<Map<String, dynamic>> _getDynamicInstances() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_instancesCache != null && (now - _instancesCacheTime) < _cacheDuration) {
      return _instancesCache!;
    }

    try {
      final response = await http.get(Uri.parse("https://raw.githubusercontent.com/n-ce/Uma/main/dynamic_instances.json"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        data['piped'] = _defaultPipedInstances;
        _instancesCache = data;
        _instancesCacheTime = now;
        return _instancesCache!;
      }
    } catch (_) {
      // fallback
    }

    return {
      "piped": _defaultPipedInstances,
      "invidious": _defaultInvidiousInstances,
    };
  }

  static Future<Map<String, dynamic>> fetchFromPiped(String videoId) async {
    final instancesData = await _getDynamicInstances();
    final List<dynamic> pipedInstances = instancesData['piped'] ?? [];

    for (var instance in pipedInstances) {
      try {
        final response = await http.get(
          Uri.parse("$instance/streams/$videoId"),
          headers: {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"},
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['error'] != null) continue;

          final audioStreams = data['audioStreams'] as List?;
          if (audioStreams != null && audioStreams.isNotEmpty) {
            final uri = Uri.parse(instance.toString());
            final proxyHost = uri.host.replaceAll("pipedapi", "pipedproxy").replaceAll("api.", "proxy.");

            return {
              "success": true,
              "instance": instance,
              "streamingUrls": audioStreams.map((s) => {
                "url": s['url'],
                "quality": s['quality'],
                "mimeType": s['mimeType'],
                "bitrate": s['bitrate'],
                "proxyHost": proxyHost,
              }).toList(),
            };
          }
        }
      } catch (_) {
        continue;
      }
    }

    return {"success": false, "error": "No working Piped instances found"};
  }

  static Future<Map<String, dynamic>> fetchFromInvidious(String videoId) async {
    final instancesData = await _getDynamicInstances();
    final List<dynamic> invidiousInstances = instancesData['invidious'] ?? [];

    for (var instance in invidiousInstances) {
      try {
        final response = await http.get(
          Uri.parse("$instance/api/v1/videos/$videoId"),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final adaptiveFormats = data['adaptiveFormats'] as List?;

          if (adaptiveFormats != null) {
            final audioFormats = adaptiveFormats.where((f) {
              final type = f['type']?.toString() ?? "";
              final mimeType = f['mimeType']?.toString() ?? "";
              return type.contains("audio") || mimeType.contains("audio");
            }).toList();

            if (audioFormats.isNotEmpty) {
              return {
                "success": true,
                "instance": instance,
                "streamingUrls": audioFormats.map((f) => {
                  "url": "$instance/latest_version?id=$videoId&itag=${f['itag']}",
                  "directUrl": f['url'],
                  "bitrate": f['bitrate'],
                  "type": f['type'],
                  "audioQuality": f['audioQuality'],
                  "itag": f['itag'],
                }).toList(),
              };
            }
          }
        }
      } catch (_) {
        continue;
      }
    }

    return {"success": false, "error": "No working Invidious instances found"};
  }

  static Future<String?> getBestStreamUrl(String videoId) async {
    final pipedResult = await fetchFromPiped(videoId);
    if (pipedResult['success'] == true) {
      final urls = pipedResult['streamingUrls'] as List;
      if (urls.isNotEmpty) {
        return urls[0]['url'];
      }
    }

    final invidiousResult = await fetchFromInvidious(videoId);
    if (invidiousResult['success'] == true) {
      final urls = invidiousResult['streamingUrls'] as List;
      if (urls.isNotEmpty) {
        return urls[0]['url'];
      }
    }

    return null;
  }
}
