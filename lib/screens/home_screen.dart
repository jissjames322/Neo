import 'package:flutter/material.dart';
import '../widgets/song_card.dart';
import '../models/song.dart';

class PulseMusic extends StatelessWidget {
  const PulseMusic({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pulse Music',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 220,
            color: const Color(0xFF121212),
            child: Column(
              children: const [
                SizedBox(height: 30),
                Text(
                  "PULSE",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 30),
                ListTile(leading: Icon(Icons.home), title: Text("Home")),
                ListTile(
                  leading: Icon(Icons.library_music),
                  title: Text("Library"),
                ),
                ListTile(
                  leading: Icon(Icons.favorite),
                  title: Text("Favorites"),
                ),
                ListTile(
                  leading: Icon(Icons.playlist_play),
                  title: Text("Playlists"),
                ),
              ],
            ),
          ),

          Expanded(
            child: Column(
              children: [
                Container(
                  height: 70,
                  padding: const EdgeInsets.all(15),
                  child: const SearchBar(hintText: "Search songs..."),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            "Recently Played",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        Wrap(
                          children: [
                            SongCard(
                              song: Song(
                                title: "Believer",
                                artist: "Imagine Dragons",
                              ),
                            ),
                            SongCard(
                              song: Song(
                                title: "Starboy",
                                artist: "The Weeknd",
                              ),
                            ),
                            SongCard(
                              song: Song(
                                title: "Heat Waves",
                                artist: "Glass Animals",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                Container(
                  height: 90,
                  color: Colors.black54,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.skip_previous, size: 32),
                      SizedBox(width: 20),
                      Icon(Icons.play_circle_fill, size: 50),
                      SizedBox(width: 20),
                      Icon(Icons.skip_next, size: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
