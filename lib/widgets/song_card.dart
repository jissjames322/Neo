import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';

class SongCard extends ConsumerStatefulWidget {
  final Song song;
  final List<Song> queueContext;

  const SongCard({
    super.key,
    required this.song,
    required this.queueContext,
  });

  @override
  ConsumerState<SongCard> createState() => _SongCardState();
}

class _SongCardState extends ConsumerState<SongCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final isPlayingThis = ref.watch(audioProvider).currentSong?.id == widget.song.id &&
        ref.watch(audioProvider).isPlaying;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          final index = widget.queueContext.indexWhere((s) => s.id == widget.song.id);
          ref.read(audioProvider.notifier).playQueue(
                widget.queueContext,
                initialIndex: index >= 0 ? index : 0,
              );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 170,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isHovered
                ? Theme.of(context).cardColor.withBlue(30)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: _isHovered ? 12 : 6,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isPlayingThis
                  ? accentColor.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.04),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover art with overlay play button on hover
              Stack(
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey.shade800,
                          Colors.grey.shade900,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isPlayingThis ? Icons.volume_up_rounded : Icons.music_note_rounded,
                        size: 40,
                        color: isPlayingThis ? accentColor : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  // Hover Play Button Overlay
                  Positioned.fill(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _isHovered || isPlayingThis ? 1.0 : 0.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              isPlayingThis ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Song details
              Text(
                widget.song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isPlayingThis ? accentColor : Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
