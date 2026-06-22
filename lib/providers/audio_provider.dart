import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/db_helper.dart';
import '../services/settings_service.dart';
import '../services/yt_dlp_service.dart';
import 'db_provider.dart';

class AudioPlaybackState {
  final Song? currentSong;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final double volume;
  final double speed;
  final LoopMode loopMode;
  final bool shuffleModeEnabled;
  final List<Song> queue;
  final int? currentIndex;

  AudioPlaybackState({
    this.currentSong,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.speed = 1.0,
    this.loopMode = LoopMode.off,
    this.shuffleModeEnabled = false,
    this.queue = const [],
    this.currentIndex,
  });

  AudioPlaybackState copyWith({
    Song? currentSong,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    double? volume,
    double? speed,
    LoopMode? loopMode,
    bool? shuffleModeEnabled,
    List<Song>? queue,
    int? currentIndex,
    bool clearCurrentSong = false,
  }) {
    return AudioPlaybackState(
      currentSong: clearCurrentSong ? null : (currentSong ?? this.currentSong),
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      loopMode: loopMode ?? this.loopMode,
      shuffleModeEnabled: shuffleModeEnabled ?? this.shuffleModeEnabled,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

class AudioNotifier extends Notifier<AudioPlaybackState> {
  final AudioPlayer _player = AudioPlayer();
  final DbHelper _db = DbHelper.instance;
  final SettingsService _settings = SettingsService.instance;

  // ignore: deprecated_member_use
  ConcatenatingAudioSource? _playlistSource;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _indexSub;

  @override
  AudioPlaybackState build() {
    _init();

    ref.onDispose(() {
      _playerStateSub?.cancel();
      _positionSub?.cancel();
      _durationSub?.cancel();
      _indexSub?.cancel();
      _player.dispose();
    });

    return AudioPlaybackState();
  }

  Future<void> _init() async {
    final storedVolume = _player.volume;
    final storedSpeed = await _settings.getPlaybackSpeed();
    await _player.setSpeed(storedSpeed);

    state = state.copyWith(
      volume: storedVolume,
      speed: storedSpeed,
    );

    _playerStateSub = _player.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;
      final isBuffering = processingState == ProcessingState.buffering ||
          processingState == ProcessingState.loading;

      state = state.copyWith(
        isPlaying: isPlaying,
        isBuffering: isBuffering,
      );

      if (processingState == ProcessingState.completed) {
        _onSongCompleted();
      }
    });

    _positionSub = _player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });

    _durationSub = _player.durationStream.listen((dur) {
      state = state.copyWith(duration: dur ?? Duration.zero);
    });

    _indexSub = _player.currentIndexStream.listen((index) async {
      if (index != null && state.queue.isNotEmpty && index < state.queue.length) {
        var currentSong = state.queue[index];

        // Resolve stream URL if not yet resolved (using yt-dlp)
        if (currentSong.sourceType == 'stream' &&
            currentSong.filePath.startsWith('youtube://')) {
          state = state.copyWith(isBuffering: true);
          final resolvedUrl = await _resolveSongStreamUrl(currentSong);
          currentSong = currentSong.copyWith(filePath: resolvedUrl);

          final updatedQueue = List<Song>.from(state.queue);
          updatedQueue[index] = currentSong;

          state = state.copyWith(
            queue: updatedQueue,
            currentSong: currentSong,
            currentIndex: index,
          );

          if (_playlistSource != null && index < _playlistSource!.length) {
            await _playlistSource!.insert(index, AudioSource.uri(Uri.parse(resolvedUrl)));
            await _playlistSource!.removeAt(index + 1);
          }
        } else {
          state = state.copyWith(
            currentIndex: index,
            currentSong: currentSong,
          );
        }
        _incrementPlayCount(currentSong);
      }
    });
  }

  Stream<Duration> get positionStream => _player.positionStream;

  /// Resolve a youtube:// URI to a real HTTPS stream URL using yt-dlp.
  Future<String> _resolveSongStreamUrl(Song song) async {
    if (song.sourceType != 'stream') return song.filePath;
    if (!song.filePath.startsWith('youtube://')) return song.filePath;

    final videoId = song.id;
    final streamUrl = await YtDlpService.instance.getStreamUrl(videoId);

    if (streamUrl != null && streamUrl.startsWith('https://')) {
      return streamUrl;
    }

    return song.filePath; // fallback (will likely fail playback gracefully)
  }

  Future<void> playQueue(List<Song> songs, {int initialIndex = 0}) async {
    if (songs.isEmpty) return;

    List<Song> updatedSongs = List<Song>.from(songs);
    var initialSong = songs[initialIndex];

    // Pre-resolve the initial song to prevent double-buffering
    if (initialSong.sourceType == 'stream' &&
        initialSong.filePath.startsWith('youtube://')) {
      state = state.copyWith(
        queue: songs,
        currentIndex: initialIndex,
        currentSong: initialSong,
        isBuffering: true,
      );
      final resolvedUrl = await _resolveSongStreamUrl(initialSong);
      initialSong = initialSong.copyWith(filePath: resolvedUrl);
      updatedSongs[initialIndex] = initialSong;
    }

    state = state.copyWith(
      queue: updatedSongs,
      currentIndex: initialIndex,
      currentSong: initialSong,
    );

    final sources = updatedSongs.map((s) {
      if (s.sourceType == 'local') {
        return AudioSource.uri(Uri.file(s.filePath));
      } else if (s.filePath.startsWith('https://')) {
        return AudioSource.uri(Uri.parse(s.filePath));
      } else {
        // Placeholder for unresolved tracks (will resolve via index stream listener)
        return AudioSource.uri(Uri.parse('https://www.example.com/placeholder'));
      }
    }).toList();

    // ignore: deprecated_member_use
    _playlistSource = ConcatenatingAudioSource(children: sources);
    await _player.setAudioSource(_playlistSource!, initialIndex: initialIndex);
    await _player.play();
  }

  Future<void> play() async {
    if (state.queue.isEmpty) return;
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
    state = state.copyWith(clearCurrentSong: true, position: Duration.zero, duration: Duration.zero);
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> next() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  Future<void> previous() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  Future<void> setVolume(double vol) async {
    await _player.setVolume(vol);
    state = state.copyWith(volume: vol);
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    await _settings.setPlaybackSpeed(speed);
    state = state.copyWith(speed: speed);
  }

  Future<void> toggleShuffle() async {
    final enable = !state.shuffleModeEnabled;
    await _player.setShuffleModeEnabled(enable);
    state = state.copyWith(shuffleModeEnabled: enable);
  }

  Future<void> toggleRepeat() async {
    LoopMode nextMode;
    switch (state.loopMode) {
      case LoopMode.off:
        nextMode = LoopMode.all;
        break;
      case LoopMode.all:
        nextMode = LoopMode.one;
        break;
      case LoopMode.one:
        nextMode = LoopMode.off;
        break;
    }
    await _player.setLoopMode(nextMode);
    state = state.copyWith(loopMode: nextMode);
  }

  Future<void> toggleFavoriteCurrent() async {
    final song = state.currentSong;
    if (song == null) return;

    final updated = song.copyWith(isFavorite: !song.isFavorite);
    await _db.insertSong(updated.toMap());

    final updatedQueue = state.queue.map((s) => s.id == song.id ? updated : s).toList();
    state = state.copyWith(
      currentSong: updated,
      queue: updatedQueue,
    );

    ref.read(dbSongsProvider.notifier).refreshSongs();
  }

  Future<void> _incrementPlayCount(Song song) async {
    final enabled = await _settings.isHistoryTrackingEnabled();
    if (!enabled) return;

    final updated = song.copyWith(
      playsCount: song.playsCount + 1,
      lastPlayedAt: DateTime.now(),
    );

    await _db.insertSong(updated.toMap());
    await _db.insertHistoryRecord({
      'songId': song.id,
      'playedAt': DateTime.now().toIso8601String(),
      'skipped': 0,
      'durationPlayedMs': song.durationMs,
    });

    ref.read(dbSongsProvider.notifier).refreshSongs();
  }

  Future<void> _onSongCompleted() async {
    // Standard handler — just_audio queue handles auto-advancing.
  }
}

final audioProvider = NotifierProvider<AudioNotifier, AudioPlaybackState>(() {
  return AudioNotifier();
});
