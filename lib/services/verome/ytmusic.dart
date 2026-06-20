import 'dart:convert';
import 'package:http/http.dart' as http;

class YtMusicItem {
  final String? title;
  final String? thumbnail;
  final String? videoId;
  final String? browseId;
  final List<Map<String, dynamic>> artists;
  final String? duration;
  final String resultType;

  YtMusicItem({
    this.title,
    this.thumbnail,
    this.videoId,
    this.browseId,
    this.artists = const [],
    this.duration,
    required this.resultType,
  });
}

class VeromeYtMusic {
  static const String _baseURL = "https://music.youtube.com/youtubei/v1";
  static const String _apiKey = "AIzaSyC9XL3ZjWjXClIX1FmUxJq--EohcD4_oSs";
  
  static const Map<String, dynamic> _context = {
    "client": {
      "hl": "en",
      "gl": "US",
      "clientName": "WEB_REMIX",
      "clientVersion": "1.20251015.03.00",
      "platform": "DESKTOP",
      "utcOffsetMinutes": 0,
    }
  };

  static Future<List<YtMusicItem>> search(String query, {String? filter}) async {
    final String url = "$_baseURL/search?key=$_apiKey";
    
    Map<String, dynamic> params = {
      "query": query,
      "context": _context,
    };

    if (filter != null) {
      final String? filterParams = _getFilterParams(filter);
      if (filterParams != null) {
        params["params"] = filterParams;
      }
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(params),
    );

    if (response.statusCode != 200) {
      return [];
    }

    final data = jsonDecode(response.body);
    return _parseSearchResults(data);
  }

  static String? _getFilterParams(String filter) {
    const filterMap = {
      "songs": "EgWKAQIIAWoKEAkQAxAEEAoQBQ%3D%3D",
      "videos": "EgWKAQIQAWoKEAkQAxAEEAoQBQ%3D%3D",
      "albums": "EgWKAQIYAWoKEAkQAxAEEAoQBQ%3D%3D",
      "artists": "EgWKAQIgAWoKEAkQAxAEEAoQBQ%3D%3D",
      "playlists": "EgWKAQIoAWoKEAkQAxAEEAoQBQ%3D%3D",
    };
    return filterMap[filter];
  }

  static List<YtMusicItem> _parseSearchResults(dynamic data) {
    final List<YtMusicItem> results = [];

    // Handle initial results
    try {
      final tabs = data['contents']?['tabbedSearchResultsRenderer']?['tabs'] as List?;
      if (tabs != null && tabs.isNotEmpty) {
        final contents = tabs[0]['tabRenderer']?['content']?['sectionListRenderer']?['contents'] as List?;
        if (contents != null) {
          for (var section in contents) {
            // Check for musicShelfRenderer
            final shelf = section['musicShelfRenderer'];
            if (shelf != null) {
              final items = shelf['contents'] as List?;
              if (items != null) {
                for (var item in items) {
                  final parsed = _parseMusicItem(item['musicResponsiveListItemRenderer']);
                  if (parsed != null) {
                    results.add(parsed);
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      // safe fallback
    }

    return results;
  }

  static YtMusicItem? _parseMusicItem(dynamic item) {
    if (item == null) return null;

    try {
      final titleRuns = item['flexColumns']?[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List?;
      final title = titleRuns?.isNotEmpty == true ? titleRuns![0]['text'] : null;

      final thumbnails = item['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?;
      final thumbnail = thumbnails?.isNotEmpty == true ? thumbnails![0]['url'] : null;

      final videoId = item['overlay']?['musicItemThumbnailOverlayRenderer']?['content']
          ?['musicPlayButtonRenderer']?['playNavigationEndpoint']?['watchEndpoint']?['videoId'];

      final browseId = item['navigationEndpoint']?['browseEndpoint']?['browseId'];

      final subtitleRuns = item['flexColumns']?[1]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List?;
      
      final List<Map<String, dynamic>> artists = [];
      String? duration;

      if (subtitleRuns != null) {
        for (var r in subtitleRuns) {
          final pageType = r['navigationEndpoint']?['browseEndpoint']?['browseEndpointContextSupportedConfigs']
              ?['browseEndpointContextMusicConfig']?['pageType'];
          
          if (pageType == "MUSIC_PAGE_TYPE_ARTIST") {
            artists.add({
              "name": r['text'],
              "id": r['navigationEndpoint']?['browseEndpoint']?['browseId']
            });
          } else if (r['text'] != null && RegExp(r'^\d+:\d+$').hasMatch(r['text'].toString())) {
             // Basic duration matching fallback if it's in subtitle
             duration = r['text'];
          }
        }
      }

      final fixedColsRuns = item['fixedColumns']?[0]?['musicResponsiveListItemFixedColumnRenderer']?['text']?['runs'] as List?;
      if (fixedColsRuns != null && fixedColsRuns.isNotEmpty) {
        duration = fixedColsRuns[0]['text'];
      }

      String resultType = "album";
      if (videoId != null) {
        resultType = "song";
      } else if (browseId != null && browseId.startsWith("UC")) {
        resultType = "artist";
      }

      return YtMusicItem(
        title: title,
        thumbnail: thumbnail,
        videoId: videoId,
        browseId: browseId,
        artists: artists,
        duration: duration,
        resultType: resultType,
      );
    } catch (e) {
      return null;
    }
  }
}
