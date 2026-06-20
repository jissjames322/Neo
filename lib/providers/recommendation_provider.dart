import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../services/db_helper.dart';
import '../services/settings_service.dart';
import 'db_provider.dart';

class RecommendationState {
  final List<Song> recentlyPlayed;
  final List<Song> recommended;
  final List<Song> favorites;
  final List<Song> trending;
  final List<Song> discoveries;

  RecommendationState({
    required this.recentlyPlayed,
    required this.recommended,
    required this.favorites,
    required this.trending,
    required this.discoveries,
  });

  factory RecommendationState.empty() {
    return RecommendationState(
      recentlyPlayed: [],
      recommended: [],
      favorites: [],
      trending: [],
      discoveries: [],
    );
  }
}

class RecommendationNotifier extends Notifier<RecommendationState> {
  final DbHelper _db = DbHelper.instance;
  final SettingsService _settings = SettingsService.instance;

  @override
  RecommendationState build() {
    ref.listen(dbSongsProvider, (previous, next) {
      refreshRecommendations();
    });
    refreshRecommendations();
    return RecommendationState.empty();
  }

  Future<void> refreshRecommendations() async {
    try {
      final songsVal = ref.read(dbSongsProvider);
      final List<Song> allSongs = songsVal.maybeWhen(
        data: (songs) => songs,
        orElse: () => [],
      );

      if (allSongs.isEmpty) {
        state = RecommendationState.empty();
        return;
      }

      // 1. Recently Played
      final recentData = await _db.getRecentlyPlayed(10);
      final recentlyPlayed = recentData
          .map((m) {
            try {
              return allSongs.firstWhere((s) => s.id == m['id']);
            } catch (_) {
              return Song.fromMap(m);
            }
          })
          .toList();

      // 2. Favorites
      final favorites = allSongs.where((s) => s.isFavorite).toList();

      // 3. Recommended For You (Based on selected genres and plays count)
      final selectedGenres = await _settings.getSelectedGenres();
      
      final List<Song> recommended = List.from(allSongs);
      recommended.sort((a, b) {
        // Boost if genre is user-selected
        final aBoost = selectedGenres.contains(a.genre) ? 20 : 0;
        final bBoost = selectedGenres.contains(b.genre) ? 20 : 0;
        
        final aScore = a.playsCount * 2 + aBoost;
        final bScore = b.playsCount * 2 + bBoost;
        return bScore.compareTo(aScore); // Descending score
      });

      // 4. Trending Free Music (Simulated trending / most played in catalog)
      final List<Song> trending = List.from(allSongs);
      trending.sort((a, b) => b.playsCount.compareTo(a.playsCount));

      // 5. New Discoveries (Songs user has never played or has low play count, shuffled)
      final List<Song> discoveries = allSongs.where((s) => s.playsCount == 0).toList();
      discoveries.shuffle();

      state = RecommendationState(
        recentlyPlayed: recentlyPlayed,
        recommended: recommended.take(10).toList(),
        favorites: favorites,
        trending: trending.take(10).toList(),
        discoveries: discoveries.take(10).toList(),
      );
    } catch (_) {
      // Graceful fallback
    }
  }
}

final recommendationProvider =
    NotifierProvider<RecommendationNotifier, RecommendationState>(() {
  return RecommendationNotifier();
});
