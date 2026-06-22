import 'dart:async';
import 'dart:math';
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

  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;

  @override
  AudioPlaybackState build() {
    _init();

    ref.onDispose(() {
      _playerStateSub?.cancel();
      _positionSub?.cancel();
      _durationSub?.cancel();
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
  }

  Stream<Duration> get positionStream => _player.positionStream;

  // Removed _resolveSongStreamUrl since we now use proxy server.

  Future<void> playQueue(List<Song> songs, {int initialIndex = 0}) async {
    if (songs.isEmpty) return;

    List<Song> updatedSongs = List<Song>.from(songs);

    state = state.copyWith(
      queue: updatedSongs,
    );

    await _playSongAtIndex(initialIndex);
  }

  int _playActionId = 0;

  Future<void> _playSongAtIndex(int index) async {
    if (index < 0 || index >= state.queue.length) return;

    final actionId = ++_playActionId;
    
    // Debounce rapid clicks
    await Future.delayed(const Duration(milliseconds: 200));
    if (_playActionId != actionId) return;

    final s = state.queue[index];
    AudioSource source;
    if (s.sourceType == 'local') {
      source = AudioSource.uri(Uri.file(s.filePath));
    } else if (s.filePath.startsWith('https://')) {
      source = AudioSource.uri(Uri.parse(s.filePath));
    } else if (s.sourceType == 'stream' && s.filePath.startsWith('youtube://')) {
      final url = await YtDlpService.instance.getStreamUrl(s.id);
      if (_playActionId != actionId) return;
      if (url == null) {
        // Fallback: skip to next if resolution failed
        await next();
        return;
      }
      source = AudioSource.uri(Uri.parse(url));
    } else {
      source = AudioSource.uri(Uri.parse(s.filePath));
    }

    if (_playActionId != actionId) return;
    
    state = state.copyWith(currentIndex: index, currentSong: s);
    
    try {
      await _player.setAudioSource(source);
      if (_playActionId != actionId) return;
      _incrementPlayCount(s);
      await _player.play();
      
      // Start background prefetch for the next songs to make playback instant
      _prefetchNextSongs(index);
    } catch (e) {
      // Catch "Loading interrupted" from just_audio if aborted rapidly
      print('[NEO] Audio play interrupted or failed: $e');
    }
  }

  void _prefetchNextSongs(int currentIndex) {
    if (state.queue.isEmpty) return;
    
    // Pre-fetch the next 2 songs
    for (int i = 1; i <= 2; i++) {
      int nextIndex = currentIndex + i;
      if (nextIndex < state.queue.length) {
        final s = state.queue[nextIndex];
        if (s.sourceType == 'stream' && s.filePath.startsWith('youtube://')) {
          // Fire and forget: this resolves and populates the cache
          YtDlpService.instance.getStreamUrl(s.id);
        }
      }
    }
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
    if (state.queue.isEmpty) return;
    int nextIndex = (state.currentIndex ?? 0) + 1;

    if (state.shuffleModeEnabled) {
      nextIndex = Random().nextInt(state.queue.length);
    } else if (nextIndex >= state.queue.length) {
      if (state.loopMode == LoopMode.all) {
        nextIndex = 0;
      } else {
        await _player.stop();
        return;
      }
    }
    await _playSongAtIndex(nextIndex);
  }

  Future<void> previous() async {
    if (state.queue.isEmpty) return;
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    int prevIndex = (state.currentIndex ?? 0) - 1;

    if (state.shuffleModeEnabled) {
      prevIndex = Random().nextInt(state.queue.length);
    } else if (prevIndex < 0) {
      if (state.loopMode == LoopMode.all) {
        prevIndex = state.queue.length - 1;
      } else {
        prevIndex = 0;
      }
    }
    await _playSongAtIndex(prevIndex);
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
    if (state.loopMode == LoopMode.one) {
      await _player.seek(Duration.zero);
      await _player.play();
    } else {
      await next();
    }
  }
}

final audioProvider = NotifierProvider<AudioNotifier, AudioPlaybackState>(() {
  return AudioNotifier();
});
