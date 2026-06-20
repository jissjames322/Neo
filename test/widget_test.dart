import 'package:flutter_test/flutter_test.dart';
import 'package:neo/models/song.dart';

void main() {
  group('Song Model Tests', () {
    test('Song serialization and deserialization should match', () {
      final song = Song(
        id: 'test_song',
        title: 'Cyberpunk Breeze',
        artist: 'Lofi Pulse',
        filePath: 'https://example.com/stream.mp3',
        durationMs: 180000,
        sourceType: 'stream',
        isFavorite: true,
      );

      final map = song.toMap();
      expect(map['id'], 'test_song');
      expect(map['isFavorite'], 1);

      final decoded = Song.fromMap(map);
      expect(decoded.id, 'test_song');
      expect(decoded.title, 'Cyberpunk Breeze');
      expect(decoded.artist, 'Lofi Pulse');
      expect(decoded.filePath, 'https://example.com/stream.mp3');
      expect(decoded.durationMs, 180000);
      expect(decoded.sourceType, 'stream');
      expect(decoded.isFavorite, true);
    });
  });
}
