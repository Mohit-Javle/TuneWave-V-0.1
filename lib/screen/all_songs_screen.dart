// lib/screen/all_songs_screen.dart
import 'package:clone_mp/data/updated_music_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 👍 ADD these imports for your services and models
import 'package:clone_mp/services/playlist_service.dart';
import 'package:clone_mp/services/music_service.dart';

// 👎 REMOVE this unused provider import
// import 'package:clone_mp/providers/liked_songs_provider.dart';

class AllSongsScreen extends StatelessWidget {
  const AllSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 👍 CHANGE the provider you are watching to PlaylistService
    final playlistService = context.watch<PlaylistService>();

    return Scaffold(
      appBar: AppBar(title: const Text('All Songs')),
      body: ListView.builder(
        itemCount: allSongs.length,
        itemBuilder: (context, index) {
          final songData = allSongs[index];
          // 👍 CREATE a Song object, which is what your service expects
          final song = Song(
            title: songData['title']!,
            artist: songData['artist']!,
            assetPath: 'audio/${songData['path']!}',
            imageUrl: songData['image']!,
          );

          // 👍 UPDATE the logic to use the playlistService
          final isLiked = playlistService.isLiked(song);

          return ListTile(
            leading: const Icon(Icons.music_note),
            title: Text(song.title),
            subtitle: Text(song.artist),
            trailing: IconButton(
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : null,
              ),
              onPressed: () {
                // 👍 UPDATE the call to use the correct service with the Song object
                context.read<PlaylistService>().toggleLike(song);
              },
            ),
          );
        },
      ),
    );
  }
}
