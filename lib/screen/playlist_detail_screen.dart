// screen/playlist_detail_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:clone_mp/services/music_service.dart';
import 'package:clone_mp/services/playlist_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clone_mp/screen/add_songs_screen.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  // Method to show rename dialog
  void _showRenamePlaylistDialog() {
    // This is using listen: false, which is correct for calls inside functions.
    final playlistService = Provider.of<PlaylistService>(
      context,
      listen: false,
    );
    final TextEditingController nameController = TextEditingController(
      text: widget.playlist.name,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename Playlist"),
        content: TextField(controller: nameController, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                playlistService.renamePlaylist(
                  widget.playlist.id,
                  nameController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // Method to show options for a song
  void _showSongOptions(Song song) {
    final playlistService = Provider.of<PlaylistService>(
      context,
      listen: false,
    );
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(
                Icons.remove_circle_outline,
                color: Colors.red[400],
              ),
              title: Text(
                'Remove from this playlist',
                style: TextStyle(color: Colors.red[400]),
              ),
              onTap: () {
                playlistService.removeSongFromPlaylist(
                  widget.playlist.id,
                  song.title,
                );
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ### FIX: Get the one, shared MusicService from Provider ###
    // Do NOT create a new one like this: final musicService = MusicService();
    final musicService = context.read<MusicService>();

    return Consumer<PlaylistService>(
      builder: (context, playlistService, child) {
        // This logic correctly finds the latest version of the playlist
        final currentPlaylist = playlistService.playlists.firstWhere(
          (p) => p.id == widget.playlist.id,
          // Fallback in case the playlist was just deleted.
          orElse: () => widget.playlist,
        );

        final List<Map<String, String>> songMaps = playlistService
            .getSongsForPlaylist(currentPlaylist);

        final List<Song> playlistSongs = songMaps
            .map(
              (songData) => Song(
                title: songData['title']!,
                artist: songData['artist']!,
                assetPath: 'audio/${songData['path']!}',
                imageUrl: songData['image']!,
              ),
            )
            .toList();

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(
                context,
                theme,
                currentPlaylist.name,
                songMaps,
              ),
              _buildActionButtons(
                context,
                musicService,
                playlistSongs,
                currentPlaylist,
              ),
              if (playlistSongs.isEmpty)
                _buildEmptyState(theme)
              else
                _buildSongList(playlistSongs, musicService),
            ],
          ),
        );
      },
    );
  }

  SliverAppBar _buildSliverAppBar(
    BuildContext context,
    ThemeData theme,
    String playlistName,
    List<Map<String, String>> songMaps,
  ) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.surface,
      // Icon theme is now inherited, but this is fine
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: _showRenamePlaylistDialog,
          tooltip: 'Rename Playlist',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          playlistName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Color.fromARGB(178, 0, 0, 0),
                offset: Offset(2.0, 2.0),
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildPlaylistArt(songMaps),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(153, 0, 0, 0),
                    Colors.transparent,
                    Color.fromARGB(204, 0, 0, 0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistArt(List<Map<String, String>> songMaps) {
    if (songMaps.isEmpty) {
      return Container(
        color: Colors.grey[800],
        child: const Icon(Icons.music_note, color: Colors.white, size: 80),
      );
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemCount: songMaps.length > 4 ? 4 : songMaps.length,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Image.network(songMaps[index]['image']!, fit: BoxFit.cover);
      },
    );
  }

  SliverToBoxAdapter _buildActionButtons(
    BuildContext context,
    MusicService musicService,
    List<Song> playlistSongs,
    Playlist currentPlaylist, // Pass the current playlist object
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.playlist_add, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Pass the most up-to-date playlist object
                    builder: (context) =>
                        AddSongsScreen(playlist: currentPlaylist),
                  ),
                );
              },
              tooltip: 'Add Songs',
            ),
            ElevatedButton.icon(
              onPressed: playlistSongs.isEmpty
                  ? null
                  : () {
                      musicService.loadPlaylist(playlistSongs, 0);
                    },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6600),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.shuffle, size: 28),
              onPressed: playlistSongs.isEmpty
                  ? null
                  : () {
                      final shuffledList = List<Song>.from(playlistSongs)
                        ..shuffle();
                      musicService.loadPlaylist(shuffledList, 0);
                    },
              tooltip: 'Shuffle',
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildEmptyState(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.playlist_add, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                "This playlist is empty",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Tap the '+' icon above to add songs.",
                // ### FIX: Use .withOpacity for cleaner code ###
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverList _buildSongList(
    List<Song> playlistSongs,
    MusicService musicService,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final song = playlistSongs[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              song.imageUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(song.title),
          subtitle: Text(song.artist),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showSongOptions(song),
          ),
          onTap: () {
            musicService.loadPlaylist(playlistSongs, index);
          },
        );
      }, childCount: playlistSongs.length),
    );
  }
}
