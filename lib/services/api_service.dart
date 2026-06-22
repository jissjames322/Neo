import 'package:flutter/foundation.dart';
import '../models/song.dart';
import 'yt_dlp_service.dart';

/// ApiService — Facade for all music search and metadata.
/// Now powered by yt-dlp (local subprocess) instead of third-party proxies.
class ApiService {
  static final ApiService instance = ApiService._init();
  ApiService._init();

  Future<List<Song>> searchSongs(String query) async {
    try {
      return await YtDlpService.instance.searchSongs(query, maxResults: 12);
    } catch (e) {
      debugPrint('[NEO] ApiService.searchSongs error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchAudioFeatures(String id) async {
    // Returns null so the deterministic offline fallback handles audio features
    return null;
  }
}
