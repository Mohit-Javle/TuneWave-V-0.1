// ignore_for_file: deprecated_member_use

import 'package:clone_mp/data/updated_music_data.dart';
import 'package:clone_mp/services/playlist_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddSongsScreen extends StatefulWidget {
  final Playlist playlist;

  const AddSongsScreen({super.key, required this.playlist});

  @override
  State<AddSongsScreen> createState() => _AddSongsScreenState();
}

class _AddSongsScreenState extends State<AddSongsScreen> {
  final Set<String> _selectedSongTitles = {};
  List<Map<String, String>> _filteredSongs = allSongs;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initially, don't select songs that are already in the playlist
    _selectedSongTitles.clear();
    _searchController.addListener(_filterSongs);
  }

  void _filterSongs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSongs = allSongs.where((song) {
        final title = song['title']?.toLowerCase() ?? '';
        final artist = song['artist']?.toLowerCase() ?? '';
        return title.contains(query) || artist.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSongSelected(bool? isSelected, String songTitle) {
    setState(() {
      if (isSelected == true) {
        _selectedSongTitles.add(songTitle);
      } else {
        _selectedSongTitles.remove(songTitle);
      }
    });
  }

  void _addSelectedSongsToPlaylist() {
    if (_selectedSongTitles.isEmpty) return;

    final playlistService = Provider.of<PlaylistService>(
      context,
      listen: false,
    );

    // Find the full song maps for the selected titles
    final songsToAdd = allSongs
        .where((song) => _selectedSongTitles.contains(song['title']))
        .toList();

    // ### CHANGE: Use the new, more efficient method ###
    playlistService.addSongsToPlaylist(widget.playlist.id, songsToAdd);

    Navigator.pop(context); // Go back to the playlist detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${_selectedSongTitles.length} song(s) added."),
        backgroundColor: const Color(0xFFFF6600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool canAddSongs = _selectedSongTitles.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Songs'),
        actions: [
          TextButton(
            onPressed: canAddSongs ? _addSelectedSongsToPlaylist : null,
            child: Text(
              'Add',
              style: TextStyle(
                color: canAddSongs ? const Color(0xFFFF6600) : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a song...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredSongs.length,
              itemBuilder: (context, index) {
                final song = _filteredSongs[index];
                final songTitle = song['title']!;
                final isAlreadyInPlaylist = widget.playlist.songTitles.contains(
                  songTitle,
                );
                final isSelected = _selectedSongTitles.contains(songTitle);

                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      song['image']!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(songTitle),
                  subtitle: Text(song['artist']!),
                  trailing: Checkbox(
                    value: isSelected || isAlreadyInPlaylist,
                    onChanged: isAlreadyInPlaylist
                        ? null
                        : (bool? value) {
                            _onSongSelected(value, songTitle);
                          },
                    activeColor: const Color(0xFFFF6600),
                  ),
                  onTap: isAlreadyInPlaylist
                      ? null
                      : () {
                          _onSongSelected(!isSelected, songTitle);
                        },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
