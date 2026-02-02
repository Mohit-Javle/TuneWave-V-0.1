// screen/library_screen.dart
// ignore_for_file: deprecated_member_use, unused_element

import 'package:clone_mp/screen/playlist_detail_screen.dart';
import 'package:clone_mp/services/playlist_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isGridView = true;

  static const Color primaryOrange = Color(0xFFFF6600);
  static const Color veryLightOrange = Color(0xFFFF9D5C);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playlistService = context.watch<PlaylistService>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.brightness == Brightness.light
                ? [Colors.white, const Color.fromARGB(100, 255, 218, 192)]
                : [theme.colorScheme.surface, theme.colorScheme.background],
            stops: const [0.3, 0.7],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                // ✨ FIX: Removed the condition to always show playlist content
                Expanded(child: _buildPlaylistContent(playlistService)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final textDark = theme.colorScheme.onSurface;
    final iconColor = theme.unselectedWidgetColor;

    return Row(
      children: [
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            "Your Library",
            style: TextStyle(
              color: textDark,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            _isGridView ? Icons.view_list : Icons.view_module,
            color: iconColor,
          ),
          onPressed: () {
            setState(() {
              _isGridView = !_isGridView;
            });
          },
        ),
        IconButton(
          icon: Icon(Icons.add, color: iconColor),
          onPressed: () => _showCreatePlaylistDialog(),
        ),
      ],
    );
  }

  // Note: _buildEmptyState is no longer used, but we can keep it for future use.
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_note_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            "Your Library is Empty",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Create a playlist or like some songs to get started.",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistContent(PlaylistService playlistService) {
    final userPlaylists = playlistService.playlists;

    // This combined list will now always have at least "Liked Songs"
    final combinedPlaylists = [
      Playlist(id: 'liked_songs', name: 'Liked Songs'),
      ...userPlaylists,
    ];

    if (_isGridView) {
      return CustomScrollView(
        slivers: [
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = combinedPlaylists[index];
              if (item.id == 'liked_songs') {
                return _buildLikedSongsCard();
              } else {
                return _buildPlaylistCard(item);
              }
            }, childCount: combinedPlaylists.length),
          ),
        ],
      );
    } else {
      return ListView.builder(
        itemCount: combinedPlaylists.length,
        itemBuilder: (context, index) {
          final item = combinedPlaylists[index];
          if (item.id == 'liked_songs') {
            return _buildLikedSongsTile();
          } else {
            return _buildPlaylistTile(item);
          }
        },
      );
    }
  }

  Widget _buildLikedSongsCard() {
    final theme = Theme.of(context);
    final playlistService = context.watch<PlaylistService>();
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/liked_songs'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: Card(
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.2),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.favorite, color: Colors.white, size: 60),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Liked Songs',
            style: TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${playlistService.likedSongs.length} songs',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikedSongsTile() {
    final playlistService = context.watch<PlaylistService>();
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.favorite, color: Colors.white),
        ),
      ),
      title: const Text(
        'Liked Songs',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('${playlistService.likedSongs.length} songs'),
      onTap: () => Navigator.pushNamed(context, '/liked_songs'),
    );
  }

  Widget _buildPlaylistCard(Playlist playlist) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistDetailScreen(playlist: playlist),
          ),
        );
      },
      onLongPress: () => _showPlaylistOptions(playlist),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: Card(
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.2),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildPlaylistArt(playlist, isGrid: true),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            playlist.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${playlist.songTitles.length} songs',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistTile(Playlist playlist) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 56,
          height: 56,
          child: _buildPlaylistArt(playlist, isGrid: false),
        ),
      ),
      title: Text(
        playlist.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('${playlist.songTitles.length} songs'),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistDetailScreen(playlist: playlist),
          ),
        );
      },
      trailing: IconButton(
        icon: Icon(Icons.more_vert, color: theme.unselectedWidgetColor),
        onPressed: () => _showPlaylistOptions(playlist),
      ),
    );
  }

  Widget _buildPlaylistArt(Playlist playlist, {required bool isGrid}) {
    final playlistService = Provider.of<PlaylistService>(
      context,
      listen: false,
    );
    final songs = playlistService.getSongsForPlaylist(playlist);

    if (songs.isEmpty) {
      return Container(
        color: veryLightOrange.withOpacity(0.5),
        child: Icon(
          Icons.music_note,
          size: isGrid ? 50 : 30,
          color: primaryOrange,
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemCount: songs.length > 4 ? 4 : songs.length,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Image.network(
          songs[index]['image']!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: veryLightOrange.withOpacity(0.5),
            child: const Center(
              child: Icon(Icons.error_outline, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  void _showCreatePlaylistDialog() {
    final TextEditingController nameController = TextEditingController();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    height: 5,
                    width: 40,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.unselectedWidgetColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  "Create New Playlist",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryOrange,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: "Enter a playlist name",
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.onSurface.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      Provider.of<PlaylistService>(
                        context,
                        listen: false,
                      ).createPlaylist(nameController.text);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Playlist '${nameController.text}' created!",
                          ),
                          backgroundColor: primaryOrange,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please enter a playlist name."),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Create",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPlaylistOptions(Playlist playlist) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red[400]),
              title: Text(
                'Delete Playlist',
                style: TextStyle(color: Colors.red[400]),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeletePlaylist(playlist);
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmDeletePlaylist(Playlist playlist) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Playlist'),
          content: Text('Are you sure you want to delete "${playlist.name}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red[400])),
              onPressed: () {
                Provider.of<PlaylistService>(
                  context,
                  listen: false,
                ).deletePlaylist(playlist.id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
