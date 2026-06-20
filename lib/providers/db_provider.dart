import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../services/db_helper.dart';

class DbSongsNotifier extends Notifier<AsyncValue<List<Song>>> {
  final DbHelper _db = DbHelper.instance;

  @override
  AsyncValue<List<Song>> build() {
    refreshSongs();
    return const AsyncValue.loading();
  }

  Future<void> refreshSongs() async {
    try {
      final list = await _db.getAllSongs();
      final songs = list.map((e) => Song.fromMap(e)).toList();
      state = AsyncValue.data(songs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> importSong(Song song) async {
    await _db.insertSong(song.toMap());
    await refreshSongs();
  }

  Future<void> removeSong(String id) async {
    await _db.deleteSong(id);
    await refreshSongs();
  }

  Future<void> toggleFavorite(Song song) async {
    final updated = song.copyWith(isFavorite: !song.isFavorite);
    await _db.insertSong(updated.toMap());
    await refreshSongs();
  }

  Future<void> updateSongRecord(Song song) async {
    await _db.insertSong(song.toMap());
    await refreshSongs();
  }
}

final dbSongsProvider = NotifierProvider<DbSongsNotifier, AsyncValue<List<Song>>>(() {
  return DbSongsNotifier();
});

class DbPlaylistsNotifier extends Notifier<AsyncValue<List<Playlist>>> {
  final DbHelper _db = DbHelper.instance;

  @override
  AsyncValue<List<Playlist>> build() {
    refreshPlaylists();
    return const AsyncValue.loading();
  }

  Future<void> refreshPlaylists() async {
    try {
      final list = await _db.getAllPlaylists();
      final playlists = list.map((e) => Playlist.fromMap(e)).toList();
      state = AsyncValue.data(playlists);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createPlaylist(String name) async {
    final pl = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
    );
    await _db.insertPlaylist(pl.toMap());
    await refreshPlaylists();
  }

  Future<void> deletePlaylist(String id) async {
    await _db.deletePlaylist(id);
    await refreshPlaylists();
  }

  Future<void> renamePlaylist(String id, String newName) async {
    await _db.renamePlaylist(id, newName);
    await refreshPlaylists();
  }
}

final dbPlaylistsProvider = NotifierProvider<DbPlaylistsNotifier, AsyncValue<List<Playlist>>>(() {
  return DbPlaylistsNotifier();
});
