import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _SongCardState extends ConsumerState<SongCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final audioState = ref.watch(audioProvider);
    final isCurrentSong = audioState.currentSong?.id == widget.song.id;
    final isPlaying = isCurrentSong && audioState.isPlaying;
    final thumbnailUrl = widget.song.effectiveThumbnailUrl;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _scaleController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _scaleController.reverse();
      },
      child: GestureDetector(
        onTap: () {
          final index = widget.queueContext.indexWhere((s) => s.id == widget.song.id);
          ref.read(audioProvider.notifier).playQueue(
                widget.queueContext,
                initialIndex: index >= 0 ? index : 0,
              );
        },
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 165,
            margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: isCurrentSong
                      ? accentColor.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: _isHovered ? 0.5 : 0.25),
                  blurRadius: _isHovered ? 18 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isCurrentSong
                    ? accentColor.withValues(alpha: 0.6)
                    : _isHovered
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.04),
                width: isCurrentSong ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail / Cover Art
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 118,
                        width: double.infinity,
                        child: thumbnailUrl != null
                            ? Image.network(
                                thumbnailUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, e, s) => _buildPlaceholder(accentColor, isPlaying),
                                loadingBuilder: (ctx, child, progress) {
                                  if (progress == null) return child;
                                  return _buildPlaceholder(accentColor, isPlaying);
                                },
                              )
                            : _buildPlaceholder(accentColor, isPlaying),
                      ),
                    ),

                    // Now playing glow overlay
                    if (isCurrentSong)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                accentColor.withValues(alpha: 0.5),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Play / Pause overlay on hover or currently playing
                    Positioned.fill(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: _isHovered || isCurrentSong ? 1.0 : 0.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: isCurrentSong ? 0.2 : 0.45),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.5),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // YouTube badge for stream songs
                    if (widget.song.sourceType == 'stream' && !widget.song.id.startsWith('sh'))
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'YT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Song title
                Text(
                  widget.song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isCurrentSong ? accentColor : Colors.white,
                  ),
                ),
                const SizedBox(height: 3),

                // Artist
                Text(
                  widget.song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Color accentColor, bool isPlaying) {
    return Container(
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.05),
            accentColor.withValues(alpha: 0.15),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          isPlaying ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
          size: 36,
          color: accentColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
