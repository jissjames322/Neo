class PlaybackHistory {
  final int? id;
  final String songId;
  final DateTime playedAt;
  final bool skipped;
  final int durationPlayedMs;

  PlaybackHistory({
    this.id,
    required this.songId,
    required this.playedAt,
    this.skipped = false,
    this.durationPlayedMs = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'songId': songId,
      'playedAt': playedAt.toIso8601String(),
      'skipped': skipped ? 1 : 0,
      'durationPlayedMs': durationPlayedMs,
    };
  }

  factory PlaybackHistory.fromMap(Map<String, dynamic> map) {
    return PlaybackHistory(
      id: map['id'] as int?,
      songId: map['songId'] as String,
      playedAt: DateTime.parse(map['playedAt'] as String),
      skipped: (map['skipped'] as int? ?? 0) == 1,
      durationPlayedMs: map['durationPlayedMs'] as int? ?? 0,
    );
  }
}
