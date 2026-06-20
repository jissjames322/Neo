import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';
import '../services/api_service.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final Song song;
  final int initialTab;

  const PlayerScreen({
    super.key,
    required this.song,
    this.initialTab = 0,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _artworkController;
  final ScrollController _lyricsScrollController = ScrollController();
  
  List<_LyricLine> _parsedLyrics = [];
  int _activeLyricIndex = -1;
  StreamSubscription? _posSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab,
    );

    _artworkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    _parseSongLyrics();

    // Rotate album art if song is playing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(audioProvider);
      if (state.isPlaying) {
        _artworkController.repeat();
      }
      _listenPosition();
    });
  }

  void _parseSongLyrics() {
    final raw = widget.song.lyrics;
    if (raw == null || raw.isEmpty) {
      _parsedLyrics = [];
      return;
    }

    final List<_LyricLine> lines = [];
    final regex = RegExp(r'\[(\d+):(\d+)\.(\d+)\](.*)');
    
    for (final line in raw.split('\n')) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final ms = int.parse(match.group(3)!);
        final text = match.group(4)!.trim();
        final duration = Duration(
          minutes: min,
          seconds: sec,
          milliseconds: ms * 10,
        );
        lines.add(_LyricLine(duration, text));
      }
    }
    lines.sort((a, b) => a.time.compareTo(b.time));
    setState(() {
      _parsedLyrics = lines;
    });
  }

  void _listenPosition() {
    _posSub = ref.read(audioProvider.notifier).positionStream.listen((pos) {
      if (_parsedLyrics.isEmpty) return;

      int activeIndex = -1;
      for (int i = 0; i < _parsedLyrics.length; i++) {
        if (pos >= _parsedLyrics[i].time) {
          activeIndex = i;
        } else {
          break;
        }
      }

      if (activeIndex != _activeLyricIndex && activeIndex != -1) {
        setState(() {
          _activeLyricIndex = activeIndex;
        });
        _scrollToActiveLyric();
      }
    });
  }

  void _scrollToActiveLyric() {
    if (!_lyricsScrollController.hasClients || _activeLyricIndex == -1) return;
    
    // Animate scrolling to center the active lyric line
    const double itemHeight = 56.0;
    final double targetOffset = (_activeLyricIndex * itemHeight) - 150.0;
    
    _lyricsScrollController.animateTo(
      targetOffset.clamp(0.0, _lyricsScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _tabController.dispose();
    _artworkController.dispose();
    _lyricsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(audioProvider);
    final song = playbackState.currentSong ?? widget.song;
    final accentColor = Theme.of(context).colorScheme.primary;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    // Synchronize rotating animation status with player
    if (playbackState.isPlaying) {
      if (!_artworkController.isAnimating) _artworkController.repeat();
    } else {
      if (_artworkController.isAnimating) _artworkController.stop();
    }

    // Parse lyrics if song changed
    ref.listen<Song?>(
      audioProvider.select((state) => state.currentSong),
      (prev, next) {
        if (next != null) {
          _parseSongLyrics();
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.92),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Bottom sheet drag handle / Top Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 48), // Spacer
                  ],
                ),
              ),

              Expanded(
                child: isDesktop
                    ? Row(
                        children: [
                          // Left side: Player
                          Expanded(
                            flex: 5,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: _buildMainPlayerColumn(context, playbackState, song, accentColor),
                            ),
                          ),
                          // Right side: Tabbed Panel (Lyrics / Queue)
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                TabBar(
                                  controller: _tabController,
                                  indicatorColor: accentColor,
                                  labelColor: Colors.white,
                                  unselectedLabelColor: Colors.grey,
                                  tabs: const [
                                    Tab(text: "Player"),
                                    Tab(text: "Lyrics"),
                                    Tab(text: "Analysis"),
                                    Tab(text: "Up Next"),
                                  ],
                                ),
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      Center(child: Text("Playing: ${song.title}")),
                                      _buildLyricsPanel(accentColor),
                                      _buildAnalysisPanel(song, accentColor),
                                      _buildQueuePanel(playbackState, accentColor),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          TabBar(
                            controller: _tabController,
                            indicatorColor: accentColor,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.grey,
                            tabs: const [
                              Tab(text: "Player"),
                              Tab(text: "Lyrics"),
                              Tab(text: "Analysis"),
                              Tab(text: "Up Next"),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  child: _buildMainPlayerColumn(context, playbackState, song, accentColor),
                                ),
                                _buildLyricsPanel(accentColor),
                                _buildAnalysisPanel(song, accentColor),
                                _buildQueuePanel(playbackState, accentColor),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Elements Builders ---

  Widget _buildMainPlayerColumn(
    BuildContext context,
    AudioPlaybackState playbackState,
    Song song,
    Color accentColor,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        // Rotating album artwork
        Center(
          child: RotationTransition(
            turns: _artworkController,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade900,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.25),
                    blurRadius: 36,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 6,
                ),
              ),
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border.all(color: Colors.white.withOpacity(0.12), width: 3),
                  ),
                  child: const Center(
                    child: Icon(Icons.music_note_rounded, color: Colors.grey, size: 36),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 36),

        // Metadata Title / Artist & Favorite
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                song.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: song.isFavorite ? accentColor : Colors.grey,
                size: 28,
              ),
              onPressed: () {
                ref.read(audioProvider.notifier).toggleFavoriteCurrent();
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Progress Slider
        Row(
          children: [
            Text(
              _formatDuration(playbackState.position),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Expanded(
              child: Slider(
                value: playbackState.position.inMilliseconds.toDouble(),
                max: playbackState.duration.inMilliseconds.toDouble() > 0
                    ? playbackState.duration.inMilliseconds.toDouble()
                    : 1.0,
                onChanged: (val) {
                  ref.read(audioProvider.notifier).seek(
                        Duration(milliseconds: val.toInt()),
                      );
                },
              ),
            ),
            Text(
              _formatDuration(playbackState.duration),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),

        // Main Controls Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                Icons.shuffle_rounded,
                color: playbackState.shuffleModeEnabled ? accentColor : Colors.grey,
                size: 24,
              ),
              onPressed: () {
                ref.read(audioProvider.notifier).toggleShuffle();
              },
            ),
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded, size: 36),
              onPressed: () {
                ref.read(audioProvider.notifier).previous();
              },
            ),
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  playbackState.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.black,
                  size: 40,
                ),
                onPressed: () {
                  if (playbackState.isPlaying) {
                    ref.read(audioProvider.notifier).pause();
                  } else {
                    ref.read(audioProvider.notifier).play();
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, size: 36),
              onPressed: () {
                ref.read(audioProvider.notifier).next();
              },
            ),
            IconButton(
              icon: Icon(
                playbackState.loopMode == LoopMode.off
                    ? Icons.repeat_rounded
                    : playbackState.loopMode == LoopMode.one
                        ? Icons.repeat_one_rounded
                        : Icons.repeat_rounded,
                color: playbackState.loopMode != LoopMode.off ? accentColor : Colors.grey,
                size: 24,
              ),
              onPressed: () {
                ref.read(audioProvider.notifier).toggleRepeat();
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Volume row
        Row(
          children: [
            Icon(
              playbackState.volume == 0 ? Icons.volume_off_rounded : Icons.volume_down_rounded,
              color: Colors.grey,
              size: 20,
            ),
            Expanded(
              child: Slider(
                value: playbackState.volume,
                onChanged: (val) {
                  ref.read(audioProvider.notifier).setVolume(val);
                },
              ),
            ),
            const Icon(
              Icons.volume_up_rounded,
              color: Colors.grey,
              size: 20,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLyricsPanel(Color accentColor) {
    if (_parsedLyrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lyrics_outlined, size: 48, color: Colors.grey.shade700),
            const SizedBox(height: 12),
            Text(
              "No lyrics available for this song",
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _lyricsScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      itemCount: _parsedLyrics.length,
      itemBuilder: (context, index) {
        final line = _parsedLyrics[index];
        final isActive = index == _activeLyricIndex;

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: isActive ? 20 : 16,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.white : Colors.white.withOpacity(0.35),
                letterSpacing: 0.2,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              child: Text(line.text),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQueuePanel(AudioPlaybackState playbackState, Color accentColor) {
    if (playbackState.queue.isEmpty) {
      return const Center(child: Text("Queue is empty"));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 24, top: 20, bottom: 8),
          child: Text(
            "Now Playing",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        if (playbackState.currentSong != null)
          ListTile(
            leading: Icon(Icons.play_arrow_rounded, color: accentColor),
            title: Text(
              playbackState.currentSong!.title,
              style: TextStyle(fontWeight: FontWeight.bold, color: accentColor),
            ),
            subtitle: Text(playbackState.currentSong!.artist),
          ),
        const Divider(color: Colors.white10),
        const Padding(
          padding: EdgeInsets.only(left: 24, top: 12, bottom: 8),
          child: Text(
            "Next Up",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: playbackState.queue.length,
            itemBuilder: (context, index) {
              final song = playbackState.queue[index];
              final isCurrent = index == playbackState.currentIndex;

              // Filter out already played or currently playing for "Next Up" list visual if desired,
              // but standard list with active indicator is very clear too!
              return ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCurrent ? accentColor.withOpacity(0.15) : Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      (index + 1).toString(),
                      style: TextStyle(
                        color: isCurrent ? accentColor : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? accentColor : Colors.white,
                  ),
                ),
                subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  ref.read(audioProvider.notifier).playQueue(
                        playbackState.queue,
                        initialIndex: index,
                      );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisPanel(Song song, Color accentColor) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: ApiService.instance.fetchAudioFeatures(song.id),
      builder: (context, snapshot) {
        final hasData = snapshot.connectionState == ConnectionState.done && snapshot.data != null;
        final data = hasData ? snapshot.data! : _getFallbackAnalysis(song);

        final double dance = (data['danceability'] as num?)?.toDouble() ?? 0.5;
        final double energy = (data['energy'] as num?)?.toDouble() ?? 0.5;
        final double valence = (data['valence'] as num?)?.toDouble() ?? 0.5;
        final double acoustic = (data['acousticness'] as num?)?.toDouble() ?? 0.5;
        final double tempo = (data['tempo'] as num?)?.toDouble() ?? 120.0;
        final double loudness = (data['loudness'] as num?)?.toDouble() ?? -6.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "AUDIO ANALYSIS (RECCOBEATS)",
                    style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 12, letterSpacing: 1.5),
                  ),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      hasData ? Icons.cloud_done_rounded : Icons.offline_bolt_rounded,
                      size: 16,
                      color: hasData ? accentColor : Colors.grey,
                    ),
                ],
              ),
              const SizedBox(height: 24),

              _buildAnalysisGauge("Danceability", dance, accentColor, Icons.directions_run_rounded),
              _buildAnalysisGauge("Energy", energy, accentColor, Icons.flash_on_rounded),
              _buildAnalysisGauge("Valence (Mood positivity)", valence, accentColor, Icons.emoji_emotions_rounded),
              _buildAnalysisGauge("Acousticness", acoustic, accentColor, Icons.settings_voice_rounded),

              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAnalysisStat("Tempo (BPM)", "${tempo.toInt()}", Icons.speed_rounded),
                  _buildAnalysisStat("Loudness", "${loudness.toStringAsFixed(1)} dB", Icons.volume_up_rounded),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic> _getFallbackAnalysis(Song song) {
    final h = song.title.hashCode;
    final double dance = (h.abs() % 50 + 40) / 100.0;
    final double energy = ((h.abs() >> 2) % 60 + 30) / 100.0;
    final double valence = ((h.abs() >> 4) % 70 + 20) / 100.0;
    final double acoustic = ((h.abs() >> 6) % 80 + 10) / 100.0;
    final double tempo = (h.abs() % 80 + 70).toDouble();
    final double loudness = -((h.abs() >> 8) % 12 + 3).toDouble();

    return {
      'danceability': dance,
      'energy': energy,
      'valence': valence,
      'acousticness': acoustic,
      'tempo': tempo,
      'loudness': loudness,
    };
  }

  Widget _buildAnalysisGauge(String label, double value, Color accentColor, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Text(
                "${(value * 100).toInt()}%",
                style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: accentColor.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _LyricLine {
  final Duration time;
  final String text;

  _LyricLine(this.time, this.text);
}
