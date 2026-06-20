import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pulse_music.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbDir = await getApplicationSupportDirectory();
    final path = join(dbDir.path, filePath);

    final file = File(path);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    final db = await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
    await _checkAndPopulateSongs(db);
    return db;
  }

  Future _createDB(Database db, int version) async {
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const integerType = 'INTEGER NOT NULL';
    const integerDefault0 = 'INTEGER NOT NULL DEFAULT 0';

    await db.execute('''
      CREATE TABLE songs (
        id TEXT PRIMARY KEY,
        title $textType,
        artist $textType,
        album $textNullable,
        filePath $textType,
        durationMs $integerType,
        genre $textNullable,
        sourceType $textType,
        playsCount $integerDefault0,
        lastPlayedAt $textNullable,
        isFavorite $integerDefault0,
        lyrics $textNullable
      )
    ''');

    await db.execute('''
      CREATE TABLE playlists (
        id TEXT PRIMARY KEY,
        name $textType,
        createdAt $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE playlist_songs (
        playlistId TEXT,
        songId TEXT,
        sequenceNumber $integerType,
        PRIMARY KEY (playlistId, songId),
        FOREIGN KEY (playlistId) REFERENCES playlists (id) ON DELETE CASCADE,
        FOREIGN KEY (songId) REFERENCES songs (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE playback_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        songId TEXT,
        playedAt $textType,
        skipped $integerDefault0,
        durationPlayedMs $integerDefault0,
        FOREIGN KEY (songId) REFERENCES songs (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _checkAndPopulateSongs(Database db) async {
    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM songs');
    final count = countResult.first['count'] as int;
    if (count > 0) return;

    final initialSongs = [
      {
        'id': 'sh1',
        'title': 'Synthwave Breeze',
        'artist': 'Lofi Hour',
        'album': 'Neon Nights',
        'filePath': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        'durationMs': 372000,
        'genre': 'Synthwave',
        'sourceType': 'stream',
        'playsCount': 0,
        'lastPlayedAt': null,
        'isFavorite': 0,
        'lyrics': '[00:02.00] Welcome to Pulse Music\n[00:06.00] Enjoy the local-first sound experience\n[00:12.00] No logins, no tracking, just you and the music\n[00:22.00] The synthwave beats keep repeating...\n[00:35.00] Feel the rhythm of the neon lights\n[00:50.00] The sound waves are rolling over you\n[01:05.00] Under the gravity of beautiful code\n[01:20.00] Pulse is your privacy-safe sanctuary\n[01:40.00] Relax and code with this soundtrack\n[02:00.00] Thank you for choosing Pulse Music'
      },
      {
        'id': 'sh2',
        'title': 'Summer Chill',
        'artist': 'Lofi Dreamer',
        'album': 'Sunny Days',
        'filePath': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        'durationMs': 423000,
        'genre': 'LoFi',
        'sourceType': 'stream',
        'playsCount': 0,
        'lastPlayedAt': null,
        'isFavorite': 0,
        'lyrics': '[00:03.00] Summer nights and cool breezes\n[00:10.00] Time slows down under the sun\n[00:18.00] Relax your mind, let the lofi play\n[00:28.00] Smooth beats and guitars\n[00:40.00] Perfect backdrop for reading or studying\n[01:00.00] Feel the warmth of the summer sun\n[01:20.00] Sunset brings the starlight\n[01:45.00] Just float along the music river'
      },
      {
        'id': 'sh3',
        'title': 'Cyberpunk City',
        'artist': 'Neon Drive',
        'album': 'Grid Runner',
        'filePath': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        'durationMs': 324000,
        'genre': 'Synthwave',
        'sourceType': 'stream',
        'playsCount': 0,
        'lastPlayedAt': null,
        'isFavorite': 0,
        'lyrics': '[00:04.00] Code in the dark, glow in the neon\n[00:09.00] Running the grid under rain-slicked streets\n[00:15.00] Synth beats pounding in your ears\n[00:25.00] The future is now, and it belongs to you\n[00:40.00] Keep searching for the ghost in the machine\n[01:00.00] Digital dreams, analog hearts\n[01:25.00] Accelerate into the sunset'
      },
      {
        'id': 'sh4',
        'title': 'EDM Energy',
        'artist': 'DJ Pulse',
        'album': 'Mainstage',
        'filePath': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
        'durationMs': 302000,
        'genre': 'EDM',
        'sourceType': 'stream',
        'playsCount': 0,
        'lastPlayedAt': null,
        'isFavorite': 0,
        'lyrics': '[00:02.00] Get ready for the drop\n[00:08.00] Feel the bass rising up\n[00:15.00] Stand up and dance!\n[00:25.00] Pulse is beating, hearts are racing\n[00:38.00] 3, 2, 1, GO!\n[01:00.00] Electric energy flowing through the crowd\n[01:30.00] The night is young, keep it loud'
      },
      {
        'id': 'sh5',
        'title': 'Rock Anthem',
        'artist': 'The Shredders',
        'album': 'Heavy Duty',
        'filePath': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
        'durationMs': 362000,
        'genre': 'Rock',
        'sourceType': 'stream',
        'playsCount': 0,
        'lastPlayedAt': null,
        'isFavorite': 0,
        'lyrics': '[00:05.00] Heavy guitars, pounding drums\n[00:12.00] Here comes the rock storm!\n[00:20.00] Stand up, make some noise\n[00:30.00] Rocking the stadium tonight\n[00:45.00] Guitar solo coming up\n[01:15.00] Sing it out loud and proud\n[01:45.00] Rock will never die'
      }
    ];

    for (final song in initialSongs) {
      await db.insert('songs', song);
    }
  }

  // --- CRUD Operations for Songs ---

  Future<List<Map<String, dynamic>>> getAllSongs() async {
    final db = await database;
    return await db.query('songs');
  }

  Future<int> insertSong(Map<String, dynamic> song) async {
    final db = await database;
    return await db.insert(
      'songs',
      song,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateSong(String id, Map<String, dynamic> song) async {
    final db = await database;
    return await db.update(
      'songs',
      song,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSong(String id) async {
    final db = await database;
    return await db.delete(
      'songs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Playlists ---

  Future<List<Map<String, dynamic>>> getAllPlaylists() async {
    final db = await database;
    return await db.query('playlists', orderBy: 'createdAt DESC');
  }

  Future<int> insertPlaylist(Map<String, dynamic> playlist) async {
    final db = await database;
    return await db.insert('playlists', playlist, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deletePlaylist(String id) async {
    final db = await database;
    return await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> renamePlaylist(String id, String newName) async {
    final db = await database;
    return await db.update(
      'playlists',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Playlist Songs ---

  Future<List<Map<String, dynamic>>> getSongsForPlaylist(String playlistId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT s.* FROM songs s
      INNER JOIN playlist_songs ps ON s.id = ps.songId
      WHERE ps.playlistId = ?
      ORDER BY ps.sequenceNumber ASC
    ''', [playlistId]);
  }

  Future<int> addSongToPlaylist(String playlistId, String songId) async {
    final db = await database;
    final maxSeqResult = await db.rawQuery(
      'SELECT MAX(sequenceNumber) as maxSeq FROM playlist_songs WHERE playlistId = ?',
      [playlistId],
    );
    final maxSeq = (maxSeqResult.first['maxSeq'] as int?) ?? 0;

    return await db.insert(
      'playlist_songs',
      {
        'playlistId': playlistId,
        'songId': songId,
        'sequenceNumber': maxSeq + 1,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<int> removeSongFromPlaylist(String playlistId, String songId) async {
    final db = await database;
    return await db.delete(
      'playlist_songs',
      where: 'playlistId = ? AND songId = ?',
      whereArgs: [playlistId, songId],
    );
  }

  Future<void> reorderPlaylistSongs(String playlistId, List<String> songIds) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < songIds.length; i++) {
      batch.update(
        'playlist_songs',
        {'sequenceNumber': i},
        where: 'playlistId = ? AND songId = ?',
        whereArgs: [playlistId, songIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  // --- History and Recommendations ---

  Future<int> insertHistoryRecord(Map<String, dynamic> history) async {
    final db = await database;
    return await db.insert('playback_history', history);
  }

  Future<List<Map<String, dynamic>>> getRecentlyPlayed(int limit) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT s.*, h.playedAt FROM songs s
      INNER JOIN (
        SELECT songId, MAX(playedAt) as playedAt 
        FROM playback_history 
        GROUP BY songId
      ) h ON s.id = h.songId
      ORDER BY h.playedAt DESC
      LIMIT ?
    ''', [limit]);
  }

  Future<List<Map<String, dynamic>>> getMostPlayed(int limit) async {
    final db = await database;
    return await db.query(
      'songs',
      orderBy: 'playsCount DESC',
      limit: limit,
      where: 'playsCount > 0',
    );
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final db = await database;
    return await db.query(
      'songs',
      where: 'isFavorite = 1',
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
