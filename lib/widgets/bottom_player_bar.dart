import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../providers/audio_provider.dart';
import '../screens/player_screen.dart';

class BottomPlayerBar extends ConsumerWidget {
  const BottomPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(audioProvider);
    final song = playbackState.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    final accentColor = Theme.of(context).colorScheme.primary;
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Left: Song info (title, artist, album art, like button)
          Expanded(
            flex: isDesktop ? 3 : 4,
            child: GestureDetector(
              onTap: () => _openPlayerScreen(context, ref),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Hero(
                    tag: 'player_artwork',
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.music_note_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      song.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: song.isFavorite ? accentColor : Colors.grey,
                      size: 20,
                    ),
                    onPressed: () {
                      ref.read(audioProvider.notifier).toggleFavoriteCurrent();
                    },
                  ),
                ],
              ),
            ),
          ),

          // 2. Center: Controls & Seek bar
          Expanded(
            flex: isDesktop ? 5 : 6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.shuffle_rounded,
                        color: playbackState.shuffleModeEnabled ? accentColor : Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        ref.read(audioProvider.notifier).toggleShuffle();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 24),
                      onPressed: () {
                        ref.read(audioProvider.notifier).previous();
                      },
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          playbackState.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.black,
                          size: 26,
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
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 24),
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
                        size: 20,
                      ),
                      onPressed: () {
                        ref.read(audioProvider.notifier).toggleRepeat();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Progress Slider row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Text(
                        _formatDuration(playbackState.position),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Expanded(
                        child: SizedBox(
                          height: 12,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                            ),
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
                        ),
                      ),
                      Text(
                        _formatDuration(playbackState.duration),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Right: Additional features (lyrics, queue, volume)
          if (isDesktop)
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.lyrics_rounded, color: Colors.grey, size: 20),
                    onPressed: () => _openPlayerScreen(context, ref, initialTab: 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.queue_music_rounded, color: Colors.grey, size: 20),
                    onPressed: () => _openPlayerScreen(context, ref, initialTab: 2),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    playbackState.volume == 0
                        ? Icons.volume_off_rounded
                        : playbackState.volume < 0.5
                            ? Icons.volume_down_rounded
                            : Icons.volume_up_rounded,
                    color: Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 90,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                      ),
                      child: Slider(
                        value: playbackState.volume,
                        max: 1.0,
                        min: 0.0,
                        onChanged: (val) {
                          ref.read(audioProvider.notifier).setVolume(val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _openPlayerScreen(BuildContext context, WidgetRef ref, {int initialTab = 0}) {
    final state = ref.read(audioProvider);
    if (state.currentSong == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlayerScreen(song: state.currentSong!, initialTab: initialTab),
    );
  }
}
