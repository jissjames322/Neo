import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../providers/db_provider.dart';
import '../providers/recommendation_provider.dart';
import '../widgets/song_card.dart';
import '../services/api_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = ref.watch(recommendationProvider);
    final allSongsVal = ref.watch(dbSongsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Search songs, artists, genres...",
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = "";
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Contents
            Expanded(
              child: _searchQuery.isNotEmpty
                  ? allSongsVal.when(
                      data: (songs) {
                        final filtered = songs.where((s) {
                          final query = _searchQuery.toLowerCase();
                          return s.title.toLowerCase().contains(query) ||
                              s.artist.toLowerCase().contains(query) ||
                              (s.album?.toLowerCase().contains(query) ?? false) ||
                              (s.genre?.toLowerCase().contains(query) ?? false);
                        }).toList();

                        return _buildSearchResults(filtered);
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text("Error searching: $err")),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Recommended
                          if (recommendation.recommended.isNotEmpty)
                            _buildSongRow("Recommended For You", recommendation.recommended),

                          // 2. Recently Played
                          if (recommendation.recentlyPlayed.isNotEmpty)
                            _buildSongRow("Recently Played", recommendation.recentlyPlayed),

                          // 3. Favorites
                          if (recommendation.favorites.isNotEmpty)
                            _buildSongRow("Favorites", recommendation.favorites),

                          // 4. Trending Free Music
                          if (recommendation.trending.isNotEmpty)
                            _buildSongRow("Trending Free Music", recommendation.trending),

                          // 5. New Discoveries
                          if (recommendation.discoveries.isNotEmpty)
                            _buildSongRow("New Discoveries", recommendation.discoveries),

                          // Empty State fallback
                          if (recommendation.recommended.isEmpty &&
                              recommendation.recentlyPlayed.isEmpty &&
                              recommendation.favorites.isEmpty &&
                              recommendation.trending.isEmpty &&
                              recommendation.discoveries.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 80, left: 24, right: 24),
                                child: Column(
                                  children: [
                                    Icon(Icons.music_note_rounded, size: 80, color: Colors.grey.shade700),
                                    const SizedBox(height: 16),
                                    const Text(
                                      "Your library is empty",
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Import your local MP3s in the Library tab to start playing!",
                                      style: TextStyle(color: Colors.grey.shade500),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongRow(String title, List<Song> songs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24, top: 24, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              return SongCard(
                song: songs[index],
                queueContext: songs,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(List<Song> localResults) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Section 1: Local Results
        if (localResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              "Local Library Results",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: localResults.length,
              itemBuilder: (context, index) {
                return SongCard(
                  song: localResults[index],
                  queueContext: localResults,
                );
              },
            ),
          ),
        ],

        // Section 2: Online Results
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            "Online Discoveries (via Workers / MusicBrainz)",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        FutureBuilder<List<Song>>(
          future: ApiService.instance.searchSongs(_searchQuery),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final onlineSongs = snapshot.data ?? [];
            if (onlineSongs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  "No online results found or server offline",
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              );
            }

            return SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: onlineSongs.length,
                itemBuilder: (context, index) {
                  return SongCard(
                    song: onlineSongs[index],
                    queueContext: onlineSongs,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
