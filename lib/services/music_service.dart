// services/music_service.dart

import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/song_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
export '../models/song_model.dart'; // Export SongModel

class MusicService with ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  List<SongModel> _playlist = [];
  List<SongModel> _listeningHistory = []; // History list

  List<SongModel> get listeningHistory => _listeningHistory;
  int _currentIndex = -1;

  final ValueNotifier<SongModel?> currentSongNotifier = ValueNotifier(null);
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);
  final ValueNotifier<Duration> currentDurationNotifier = ValueNotifier(
    Duration.zero,
  );
  final ValueNotifier<Duration> totalDurationNotifier = ValueNotifier(
    Duration.zero,
  );
  final ValueNotifier<bool> isRepeatNotifier = ValueNotifier(false);
  final ValueNotifier<String?> errorMessageNotifier = ValueNotifier(null);

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
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('listening_history') ?? [];
    _listeningHistory = historyJson
        .map((e) => SongModel.fromJson(json.decode(e)))
        .toList();
    notifyListeners();
  }

  Future<void> addToHistory(SongModel song) async {
    // Remove if existing
    _listeningHistory.removeWhere((s) => s.id == song.id);
    
    // Create copy with timestamp
    final historyEntry = SongModel(
      id: song.id,
      name: song.name,
      artist: song.artist,
      album: song.album,
      imageUrl: song.imageUrl,
      downloadUrl: song.downloadUrl,
      hasLyrics: song.hasLyrics,
      playedAt: DateTime.now(),
    );

    _listeningHistory.insert(0, historyEntry);
    
    // Limit to 50 songs
    if (_listeningHistory.length > 50) {
      _listeningHistory = _listeningHistory.sublist(0, 50);
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final historyJson = _listeningHistory
        .map((e) => json.encode(e.toJson()))
        .toList();
    await prefs.setStringList('listening_history', historyJson);
  }

  void loadPlaylist(List<SongModel> songs, int startIndex) {
    debugPrint("MusicService: loadPlaylist called. kIsWeb=$kIsWeb");
    _playlist = songs;
    _currentIndex = startIndex;
    _playCurrentSong();
  }

  Future<void> _playCurrentSong() async {
    if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
      final song = _playlist[_currentIndex];
      currentSongNotifier.value = song;
      addToHistory(song); // Add to history
      await _player.stop();
      
      if (song.downloadUrl.isNotEmpty) {
        try {
           String playbackUrl = song.downloadUrl;
           
           // Use Streaming Proxy for Web
           if (kIsWeb) {
              playbackUrl = "http://127.0.0.1:8082/stream?url=${Uri.encodeComponent(song.downloadUrl)}";
              debugPrint("MusicService: Proxying stream via $playbackUrl");
           }

           await _player.play(UrlSource(playbackUrl));
           isPlayingNotifier.value = true;
           errorMessageNotifier.value = null; // Clear previous errors
        } catch (e) {
           debugPrint("MusicService: Player Error: $e");
           errorMessageNotifier.value = "Playback Error: $e";
        }
      } else {
        debugPrint("MusicService Error: No download URL for song: ${song.name}");
        errorMessageNotifier.value = "Error: No URL for ${song.name}";
      }
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

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
