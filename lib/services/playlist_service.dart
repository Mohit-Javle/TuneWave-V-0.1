// services/playlist_service.dart
import 'package:clone_mp/data/updated_music_data.dart';
import 'package:clone_mp/services/music_service.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Playlist {
  final String id;
  final String name;
  final List<String> songTitles;

  // This constructor is fine. The default is an unmodifiable list,
  // which is safe. We will handle creating new lists in the service.
  Playlist({required this.id, required this.name, this.songTitles = const []});
}

class PlaylistService with ChangeNotifier {
  // --- LIKED SONGS (No changes here) ---
  final List<Song> _likedSongs = [];
  List<Song> get likedSongs => _likedSongs;

  bool isLiked(Song song) {
    return _likedSongs.any(
      (s) => s.title == song.title && s.artist == song.artist,
    );
  }

  void toggleLike(Song song) {
    if (isLiked(song)) {
      _likedSongs.removeWhere(
        (s) => s.title == song.title && s.artist == song.artist,
      );
    } else {
      _likedSongs.add(song);
    }
    notifyListeners();
  }

  // --- USER-CREATED PLAYLISTS (Changes are below) ---
  final List<Playlist> _playlists = [];
  List<Playlist> get playlists => _playlists;
  final Uuid _uuid = const Uuid();

  void createPlaylist(String name) {
    final newPlaylist = Playlist(id: _uuid.v4(), name: name);
    _playlists.add(newPlaylist);
    notifyListeners();
  }

  void deletePlaylist(String playlistId) {
    _playlists.removeWhere((p) => p.id == playlistId);
    notifyListeners();
  }

  List<Map<String, String>> getSongsForPlaylist(Playlist playlist) {
    List<Map<String, String>> songsData = [];
    for (var title in playlist.songTitles) {
      try {
        final song = allSongs.firstWhere((s) => s['title'] == title);
        songsData.add(song);
      } catch (e) {
        // Song title not found, ignore it.
      }
    }
    return songsData;
  }

  // ### NEW: A better method to add multiple songs at once ###
  void addSongsToPlaylist(String playlistId, List<Map<String, String>> songs) {
    final playlistIndex = _playlists.indexWhere((p) => p.id == playlistId);
    if (playlistIndex == -1) return;

    final oldPlaylist = _playlists[playlistIndex];

    // Get the titles of the new songs, filtering out any that are already in the playlist
    final newTitlesToAdd = songs
        .map((s) => s['title'])
        .where(
          (title) => title != null && !oldPlaylist.songTitles.contains(title),
        )
        .cast<String>()
        .toList();

    // If there are actually new songs to add...
    if (newTitlesToAdd.isNotEmpty) {
      // Create a new, updated list of song titles
      final newSongTitles = List<String>.from(oldPlaylist.songTitles)
        ..addAll(newTitlesToAdd);

      // Create a new Playlist object and replace the old one in the list
      _playlists[playlistIndex] = Playlist(
        id: oldPlaylist.id,
        name: oldPlaylist.name,
        songTitles: newSongTitles,
      );
      notifyListeners();
    }
  }

  void renamePlaylist(String playlistId, String newName) {
    final playlistIndex = _playlists.indexWhere((p) => p.id == playlistId);
    if (playlistIndex != -1) {
      final oldPlaylist = _playlists[playlistIndex];
      _playlists[playlistIndex] = Playlist(
        id: oldPlaylist.id,
        name: newName,
        songTitles: oldPlaylist.songTitles,
      );
      notifyListeners();
    }
  }

  // ### FIX: Rewritten to handle unmodifiable lists correctly ###
  void removeSongFromPlaylist(String playlistId, String songTitle) {
    final playlistIndex = _playlists.indexWhere((p) => p.id == playlistId);
    if (playlistIndex != -1) {
      final oldPlaylist = _playlists[playlistIndex];

      // Create a new list of titles, excluding the one to remove
      final newSongTitles = List<String>.from(oldPlaylist.songTitles)
        ..remove(songTitle);

      // Replace the old playlist object with the new one
      _playlists[playlistIndex] = Playlist(
        id: oldPlaylist.id,
        name: oldPlaylist.name,
        songTitles: newSongTitles,
      );
      notifyListeners();
    }
  }
}
