// services/music_service.dart

import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

// Represents a single song. (This part is correct)
class Song {
  final String title;
  final String artist;
  final String assetPath;
  final String imageUrl; // URL for the album art

  Song({
    required this.title,
    required this.artist,
    required this.assetPath,
    required this.imageUrl,
  });
}

// ### CHANGE 1: Add "with ChangeNotifier" ###
class MusicService with ChangeNotifier {
  // ### CHANGE 2: Remove the singleton pattern code ###
  // The following 3 lines are removed:
  // static final MusicService _instance = MusicService._internal();
  // factory MusicService() => _instance;
  // MusicService._internal();

  final AudioPlayer _player = AudioPlayer();
  List<Song> _playlist = [];
  int _currentIndex = -1;

  final ValueNotifier<Song?> currentSongNotifier = ValueNotifier(null);
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);
  final ValueNotifier<Duration> currentDurationNotifier = ValueNotifier(
    Duration.zero,
  );
  final ValueNotifier<Duration> totalDurationNotifier = ValueNotifier(
    Duration.zero,
  );
  final ValueNotifier<bool> isRepeatNotifier = ValueNotifier(false);

  void init() {
    _player.onDurationChanged.listen((d) => totalDurationNotifier.value = d);
    _player.onPositionChanged.listen((p) => currentDurationNotifier.value = p);
    _player.onPlayerComplete.listen((_) {
      if (isRepeatNotifier.value) {
        seek(Duration.zero);
        play();
      } else {
        playNext();
      }
    });
  }

  void loadPlaylist(List<Song> songs, int startIndex) {
    _playlist = songs;
    _currentIndex = startIndex;
    _playCurrentSong();
  }

  Future<void> _playCurrentSong() async {
    if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
      currentSongNotifier.value = _playlist[_currentIndex];
      await _player.stop();
      await _player.play(AssetSource(_playlist[_currentIndex].assetPath));
      isPlayingNotifier.value = true;
    }
  }

  Future<void> play() async {
    await _player.resume();
    isPlayingNotifier.value = true;
  }

  Future<void> pause() async {
    await _player.pause();
    isPlayingNotifier.value = false;
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> playNext() async {
    if (_playlist.isNotEmpty) {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
      await _playCurrentSong();
    }
  }

  Future<void> playPrevious() async {
    if (_playlist.isNotEmpty) {
      _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
      await _playCurrentSong();
    }
  }

  void toggleRepeat() {
    isRepeatNotifier.value = !isRepeatNotifier.value;
  }

  // ### CHANGE 3: Call super.dispose() for ChangeNotifier ###
  @override
  void dispose() {
    _player.dispose();
    super.dispose(); // Important for ChangeNotifier
  }
}
