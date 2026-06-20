import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../models/song.dart';
import '../models/playlist.dart';
import '../providers/db_provider.dart';
import '../providers/audio_provider.dart';
import '../services/db_helper.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _sortBy = 'title'; // 'title', 'artist', 'plays'
  Playlist? _selectedPlaylist;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Import Logic ---

  Future<void> _importSongs() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'ogg', 'flac'],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      int importedCount = 0;
      for (final file in result.files) {
        if (file.path != null) {
          final isImported = await _addSongToDb(file.path!);
          if (isImported) importedCount++;
        }
      }
      if (mounted && importedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Successfully imported $importedCount songs")),
        );
      }
    }
  }

  Future<void> _importFolder() async {
    final path = await FilePicker.getDirectoryPath();
    if (path != null) {
      final dir = Directory(path);
      final List<FileSystemEntity> entities = await dir.list(recursive: false).toList();
      final audioExtensions = ['.mp3', '.wav', '.m4a', '.ogg', '.flac'];

      int importedCount = 0;
      for (final entity in entities) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (audioExtensions.contains(ext)) {
            final isImported = await _addSongToDb(entity.path);
            if (isImported) importedCount++;
          }
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Imported $importedCount songs from directory")),
        );
      }
    }
  }

  Future<bool> _addSongToDb(String filePath) async {
    final file = File(filePath);
    final filename = p.basenameWithoutExtension(file.path);
    
    // Parse Artist and Title if name format is "Artist - Title"
    String artist = "Unknown Artist";
    String title = filename;
    if (filename.contains(" - ")) {
      final parts = filename.split(" - ");
      artist = parts[0].trim();
      title = parts.sublist(1).join(" - ").trim();
    }

    final id = DateTime.now().microsecondsSinceEpoch.toString() + filename.hashCode.toString();
    final newSong = Song(
      id: id,
      title: title,
      artist: artist,
      album: "Local Album",
      filePath: filePath,
      durationMs: 180000, // Default to 3 min, just_audio updates on loading
      genre: "Local",
      sourceType: 'local',
    );

    try {
      await ref.read(dbSongsProvider.notifier).importSong(newSong);
      return true;
    } catch (_) {
      return false;
    }
  }

  // --- Sort & Helper ---

  List<Song> _sortSongs(List<Song> songs) {
    final sorted = List<Song>.from(songs);
    if (_sortBy == 'title') {
      sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (_sortBy == 'artist') {
      sorted.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
    } else if (_sortBy == 'plays') {
      sorted.sort((a, b) => b.playsCount.compareTo(a.playsCount));
    }
    return sorted;
  }

  // --- Playlist Actions ---

  void _showCreatePlaylistDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Playlist"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter playlist name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(dbPlaylistsProvider.notifier).createPlaylist(name);
                Navigator.pop(context);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _showPlaylistExport(Playlist playlist, List<Song> songs) {
    try {
      final exportData = {
        'playlistName': playlist.name,
        'createdAt': playlist.createdAt.toIso8601String(),
        'songs': songs.map((s) => {
          'title': s.title,
          'artist': s.artist,
          'album': s.album,
          'filePath': s.filePath,
          'sourceType': s.sourceType,
          'durationMs': s.durationMs,
        }).toList(),
      };
      final jsonStr = jsonEncode(exportData);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Export \"${playlist.name}\""),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Copy the JSON below to share or back up this playlist:"),
                const SizedBox(height: 12),
                SelectableText(
                  jsonStr,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final songsVal = ref.watch(dbSongsProvider);
    final playlistsVal = ref.watch(dbPlaylistsProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (_selectedPlaylist != null) {
      return _buildPlaylistDetailView(_selectedPlaylist!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Library"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (val) {
              setState(() {
                _sortBy = val;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'title', child: Text("Sort by Title")),
              PopupMenuItem(value: 'artist', child: Text("Sort by Artist")),
              PopupMenuItem(value: 'plays', child: Text("Sort by Most Played")),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_box_rounded),
            onSelected: (val) {
              if (val == 'files') {
                _importSongs();
              } else if (val == 'folder') {
                _importFolder();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'files', child: Text("Import Audio Files")),
              PopupMenuItem(value: 'folder', child: Text("Import Folder")),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Songs"),
            Tab(text: "Playlists"),
            Tab(text: "Favorites"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Songs Tab
          songsVal.when(
            data: (songs) => _buildSongsList(songs),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text("Error: $err")),
          ),
          // 2. Playlists Tab
          playlistsVal.when(
            data: (playlists) => _buildPlaylistsTab(playlists),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text("Error: $err")),
          ),
          // 3. Favorites Tab
          songsVal.when(
            data: (songs) {
              final favorites = songs.where((s) => s.isFavorite).toList();
              return _buildSongsList(favorites, showImportHint: false);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text("Error: $err")),
          ),
        ],
      ),
    );
  }

  // --- UI Blocks ---

  Widget _buildSongsList(List<Song> songs, {bool showImportHint = true}) {
    if (songs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_note_rounded, size: 64, color: Colors.grey.shade700),
              const SizedBox(height: 16),
              const Text("No songs in this library"),
              if (showImportHint) ...[
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _importSongs,
                  icon: const Icon(Icons.file_open_rounded),
                  label: const Text("Import Music"),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final sorted = _sortSongs(songs);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final song = sorted[index];
        final isPlayingThis = ref.watch(audioProvider).currentSong?.id == song.id;

        return ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                isPlayingThis ? Icons.volume_up_rounded : Icons.music_note_rounded,
                color: isPlayingThis ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
              ),
            ),
          ),
          title: Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPlayingThis ? Theme.of(context).colorScheme.primary : Colors.white,
            ),
          ),
          subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  song.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: song.isFavorite ? Theme.of(context).colorScheme.primary : Colors.grey,
                ),
                onPressed: () {
                  ref.read(dbSongsProvider.notifier).toggleFavorite(song);
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (val) async {
                  if (val == 'delete') {
                    ref.read(dbSongsProvider.notifier).removeSong(song.id);
                  } else if (val.startsWith('add_to_')) {
                    final playlistId = val.replaceFirst('add_to_', '');
                    await DbHelper.instance.addSongToPlaylist(playlistId, song.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Added song to playlist")),
                      );
                    }
                  }
                },
                itemBuilder: (context) {
                  final playlists = ref.read(dbPlaylistsProvider).maybeWhen(
                        data: (list) => list,
                        orElse: () => <Playlist>[],
                      );
                  return [
                    ...playlists.map(
                      (p) => PopupMenuItem(
                        value: 'add_to_${p.id}',
                        child: Text("Add to \"${p.name}\""),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text("Delete from Library", style: TextStyle(color: Colors.red)),
                    ),
                  ];
                },
              ),
            ],
          ),
          onTap: () {
            ref.read(audioProvider.notifier).playQueue(sorted, initialIndex: index);
          },
        );
      },
    );
  }

  Widget _buildPlaylistsTab(List<Playlist> playlists) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showCreatePlaylistDialog,
            icon: const Icon(Icons.playlist_add_rounded),
            label: const Text("Create Playlist"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ),
        Expanded(
          child: playlists.isEmpty
              ? const Center(child: Text("No custom playlists yet"))
              : ListView.builder(
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.playlist_play_rounded, color: Theme.of(context).colorScheme.primary),
                      ),
                      title: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Created: ${playlist.createdAt.toString().split(' ')[0]}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                        onPressed: () {
                          ref.read(dbPlaylistsProvider.notifier).deletePlaylist(playlist.id);
                        },
                      ),
                      onTap: () {
                        setState(() {
                          _selectedPlaylist = playlist;
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- Playlist Detail Subview ---

  Widget _buildPlaylistDetailView(Playlist playlist) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DbHelper.instance.getSongsForPlaylist(playlist.id),
      builder: (context, snapshot) {
        final songsData = snapshot.data ?? [];
        final songs = songsData.map((e) => Song.fromMap(e)).toList();

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                setState(() {
                  _selectedPlaylist = null;
                });
              },
            ),
            title: Text(playlist.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.ios_share_rounded),
                onPressed: () => _showPlaylistExport(playlist, songs),
              ),
            ],
          ),
          body: Column(
            children: [
              if (songs.isEmpty)
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        "No songs in this playlist. Open Songs tab and select 'Add to Playlist' from popup menu.",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ReorderableListView.builder(
                    itemCount: songs.length,
                    onReorder: (oldIdx, newIdx) async {
                      if (newIdx > oldIdx) newIdx -= 1;
                      final item = songs.removeAt(oldIdx);
                      songs.insert(newIdx, item);
                      await DbHelper.instance.reorderPlaylistSongs(
                        playlist.id,
                        songs.map((s) => s.id).toList(),
                      );
                      setState(() {});
                    },
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final isPlayingThis = ref.watch(audioProvider).currentSong?.id == song.id;

                      return ListTile(
                        key: ValueKey(song.id),
                        leading: const Icon(Icons.drag_handle_rounded, color: Colors.grey),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPlayingThis ? Theme.of(context).colorScheme.primary : Colors.white,
                          ),
                        ),
                        subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.red),
                          onPressed: () async {
                            await DbHelper.instance.removeSongFromPlaylist(playlist.id, song.id);
                            setState(() {});
                          },
                        ),
                        onTap: () {
                          ref.read(audioProvider.notifier).playQueue(songs, initialIndex: index);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
