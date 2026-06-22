import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';
import '../providers/db_provider.dart';
import '../providers/recommendation_provider.dart';
import '../widgets/song_card.dart';
import '../services/api_service.dart';
import '../services/yt_dlp_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;
  late AnimationController _headerAnimController;
  late Animation<double> _headerFadeAnim;

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerFadeAnim = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOut,
    );
    _headerAnimController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _headerAnimController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _searchQuery = val.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = ref.watch(recommendationProvider);
    final allSongsVal = ref.watch(dbSongsProvider);
    final accentColor = Theme.of(context).colorScheme.primary;
    final ytDlpAvailable = YtDlpService.instance.isAvailable;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- NEO Header ---
            FadeTransition(
              opacity: _headerFadeAnim,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo mark
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withValues(alpha: 0.12),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.graphic_eq_rounded,
                        color: accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'NEO',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 5,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: accentColor.withValues(alpha: 0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // yt-dlp status indicator
                    Tooltip(
                      message: ytDlpAvailable
                          ? 'YouTube streaming: Ready'
                          : 'YouTube streaming: Unavailable (yt-dlp not found)',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: ytDlpAvailable
                              ? Colors.greenAccent.withValues(alpha: 0.12)
                              : Colors.redAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: ytDlpAvailable
                                ? Colors.greenAccent.withValues(alpha: 0.4)
                                : Colors.redAccent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ytDlpAvailable ? Colors.greenAccent : Colors.redAccent,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              ytDlpAvailable ? 'LIVE' : 'OFFLINE',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: ytDlpAvailable ? Colors.greenAccent : Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Search Bar ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _searchQuery.isNotEmpty
                        ? accentColor.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.06),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                    if (_searchQuery.isNotEmpty)
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search YouTube — songs, artists...',
                    hintStyle: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 15,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: _searchQuery.isNotEmpty ? accentColor : Colors.white.withValues(alpha: 0.3),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : Icon(
                            Icons.youtube_searched_for_rounded,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // --- Main Content ---
            Expanded(
              child: _searchQuery.isNotEmpty
                  ? _buildSearchView(allSongsVal, accentColor)
                  : _buildHomeView(recommendation, accentColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeView(dynamic recommendation, Color accentColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recommendation.recommended.isNotEmpty)
            _buildSongRow('Recommended For You', recommendation.recommended, accentColor),
          if (recommendation.recentlyPlayed.isNotEmpty)
            _buildSongRow('Recently Played', recommendation.recentlyPlayed, accentColor),
          if (recommendation.favorites.isNotEmpty)
            _buildSongRow('Favorites ♥', recommendation.favorites, accentColor),
          if (recommendation.trending.isNotEmpty)
            _buildSongRow('Trending Free Music', recommendation.trending, accentColor),
          if (recommendation.discoveries.isNotEmpty)
            _buildSongRow('New Discoveries', recommendation.discoveries, accentColor),

          // Empty state
          if (recommendation.recommended.isEmpty &&
              recommendation.recentlyPlayed.isEmpty &&
              recommendation.favorites.isEmpty &&
              recommendation.trending.isEmpty &&
              recommendation.discoveries.isEmpty)
            _buildEmptyState(accentColor),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color accentColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.08),
              border: Border.all(color: accentColor.withValues(alpha: 0.2)),
            ),
            child: Icon(Icons.search_rounded, size: 48, color: accentColor.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          Text(
            'Search YouTube for Music',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type any song or artist name above to\nstream it instantly from YouTube — ad-free.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.4),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSearchChip('Lofi beats', accentColor),
              const SizedBox(width: 8),
              _buildSearchChip('Taylor Swift', accentColor),
              const SizedBox(width: 8),
              _buildSearchChip('EDM 2025', accentColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchChip(String label, Color accentColor) {
    return GestureDetector(
      onTap: () {
        _searchController.text = label;
        setState(() => _searchQuery = label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: accentColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchView(AsyncValue<List<Song>> allSongsVal, Color accentColor) {
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 40),
      children: [
        // Local Library Results
        allSongsVal.when(
          data: (songs) {
            final q = _searchQuery.toLowerCase();
            final filtered = songs.where((s) =>
                s.title.toLowerCase().contains(q) ||
                s.artist.toLowerCase().contains(q) ||
                (s.album?.toLowerCase().contains(q) ?? false)).toList();

            if (filtered.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Local Library', Icons.library_music_rounded, accentColor),
                SizedBox(
                  height: 230,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => SongCard(
                      song: filtered[i],
                      queueContext: filtered,
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (e, s) => const SizedBox.shrink(),
        ),

        // YouTube Results via yt-dlp
        _buildSectionHeader('YouTube Results', Icons.play_circle_fill_rounded, accentColor),
        FutureBuilder<List<Song>>(
          future: ApiService.instance.searchSongs(_searchQuery),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Searching YouTube...',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }

            final songs = snapshot.data ?? [];
            if (songs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text(
                  YtDlpService.instance.isAvailable
                      ? 'No results found for "$_searchQuery"'
                      : 'yt-dlp not available — YouTube search disabled.\nInstall Python and run: pip install yt-dlp',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.35),
                    height: 1.6,
                  ),
                ),
              );
            }

            return Column(
              children: [
                SizedBox(
                  height: 230,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: songs.length,
                    itemBuilder: (context, i) => SongCard(
                      song: songs[i],
                      queueContext: songs,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Show all as vertical list too
                ...songs.map((song) => _buildYouTubeSongTile(song, songs, accentColor)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYouTubeSongTile(Song song, List<Song> queue, Color accentColor) {
    final thumb = song.effectiveThumbnailUrl;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: thumb != null
            ? Image.network(
                thumb,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (ctx, e, s) => _placeholderThumb(accentColor),
              )
            : _placeholderThumb(accentColor),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        song.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.45),
        ),
      ),
      trailing: Icon(Icons.play_circle_outline_rounded, color: accentColor, size: 28),
      onTap: () {
        final idx = queue.indexOf(song);
        ref.read(audioProvider.notifier).playQueue(queue, initialIndex: idx < 0 ? 0 : idx);
      },
    );
  }

  Widget _placeholderThumb(Color accentColor) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.music_note_rounded, color: accentColor.withValues(alpha: 0.5), size: 24),
    );
  }

  Widget _buildSongRow(String title, List<Song> songs, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: songs.length,
            itemBuilder: (context, index) => SongCard(
              song: songs[index],
              queueContext: songs,
            ),
          ),
        ),
      ],
    );
  }
}

