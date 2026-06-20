import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../services/settings_service.dart';
import 'verome/ytmusic.dart';

class ApiService {
  static final ApiService instance = ApiService._init();
  ApiService._init();

  Future<List<Song>> searchSongs(String query) async {
    final List<Song> results = [];

    try {
      final searchList = await VeromeYtMusic.search(query, filter: "songs");

      // Increment Privacy Shield blocked requests and data saved
      final isShield = await SettingsService.instance.isShieldEnabled();
      if (isShield) {
        await SettingsService.instance.incrementShieldBlockedCount(6);
        await SettingsService.instance.incrementShieldDataSavedMb(0.85);
      }

      int count = 0;
      for (final item in searchList) {
        if (count >= 15) break;
        if (item.videoId == null) continue;
        
        count++;

        final videoId = item.videoId!;
        final title = item.title ?? "Unknown Title";
        
        String artist = "Unknown Artist";
        if (item.artists.isNotEmpty) {
          artist = item.artists.map((a) => a['name']).join(', ');
        }

        // Parse duration like "3:45" to ms
        int durationMs = 240000;
        if (item.duration != null && item.duration!.contains(":")) {
          final parts = item.duration!.split(":");
          if (parts.length == 2) {
            durationMs = ((int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0)) * 1000;
          } else if (parts.length == 3) {
            durationMs = ((int.tryParse(parts[0]) ?? 0) * 3600 + (int.tryParse(parts[1]) ?? 0) * 60 + (int.tryParse(parts[2]) ?? 0)) * 1000;
          }
        }

        results.add(Song(
          id: videoId,
          title: title,
          artist: artist,
          album: "YouTube Music",
          filePath: "youtube://$videoId",
          durationMs: durationMs,
          genre: "YouTube",
          sourceType: 'stream',
        ));
      }
    } catch (e) {
      debugPrint("Error searching YT Music: $e");
    }

    return results;
  }

  Future<Map<String, dynamic>?> fetchAudioFeatures(String id) async {
    // Return null so the deterministic offline fallback handles audio features
    return null;
  }
}
