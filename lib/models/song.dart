class Song {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String filePath;
  final int durationMs;
  final String? genre;
  final String sourceType; // 'local' or 'stream'
  final int playsCount;
  final DateTime? lastPlayedAt;
  final bool isFavorite;
  final String? lyrics;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    required this.filePath,
    required this.durationMs,
    this.genre,
    required this.sourceType,
    this.playsCount = 0,
    this.lastPlayedAt,
    this.isFavorite = false,
    this.lyrics,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? filePath,
    int? durationMs,
    String? genre,
    String? sourceType,
    int? playsCount,
    DateTime? lastPlayedAt,
    bool? isFavorite,
    String? lyrics,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      filePath: filePath ?? this.filePath,
      durationMs: durationMs ?? this.durationMs,
      genre: genre ?? this.genre,
      sourceType: sourceType ?? this.sourceType,
      playsCount: playsCount ?? this.playsCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      lyrics: lyrics ?? this.lyrics,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'filePath': filePath,
      'durationMs': durationMs,
      'genre': genre,
      'sourceType': sourceType,
      'playsCount': playsCount,
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
      'isFavorite': isFavorite ? 1 : 0,
      'lyrics': lyrics,
    };
  }

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String,
      album: map['album'] as String?,
      filePath: map['filePath'] as String,
      durationMs: map['durationMs'] as int,
      genre: map['genre'] as String?,
      sourceType: map['sourceType'] as String,
      playsCount: map['playsCount'] as int? ?? 0,
      lastPlayedAt: map['lastPlayedAt'] != null
          ? DateTime.tryParse(map['lastPlayedAt'] as String)
          : null,
      isFavorite: (map['isFavorite'] as int? ?? 0) == 1,
      lyrics: map['lyrics'] as String?,
    );
  }
}
