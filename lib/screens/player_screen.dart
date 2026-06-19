import 'package:flutter/material.dart';
import '../models/song.dart';

class PlayerScreen extends StatelessWidget {
  final Song song;

  const PlayerScreen({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(song.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 150),

            const SizedBox(height: 20),

            Text(
              song.title,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              song.artist,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),

            const SizedBox(height: 40),

            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.skip_previous, size: 40),
                SizedBox(width: 20),
                Icon(Icons.play_circle_fill, size: 70),
                SizedBox(width: 20),
                Icon(Icons.skip_next, size: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
