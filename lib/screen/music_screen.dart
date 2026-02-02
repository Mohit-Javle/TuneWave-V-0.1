// ignore_for_file: deprecated_member_use

import 'package:clone_mp/services/genius_service.dart';
import 'package:clone_mp/services/music_service.dart';
import 'package:clone_mp/services/playlist_service.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';

// Import the ArtistScreen
import 'package:clone_mp/screen/artist_screen.dart';
// Import the music data to build a song map
import 'package:clone_mp/data/updated_music_data.dart';

// Define a custom PopupMenuEntry for better styling
class _CustomPopupMenuItem<T> extends PopupMenuEntry<T> {
  const _CustomPopupMenuItem({
    required this.value,
    required this.icon,
    required this.text,
    this.onTap,
    super.key,
  });

  final T value;
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  double get height => 48.0;

  @override
  bool represents(T? value) => this.value == value;

  @override
  State<_CustomPopupMenuItem<T>> createState() =>
      _CustomPopupMenuItemState<T>();
}

class _CustomPopupMenuItemState<T> extends State<_CustomPopupMenuItem<T>> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTextColor = theme.colorScheme.onSurface;
    const Color primaryOrange = Color(0xFFFF6600);

    return InkWell(
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
        }
        Navigator.pop(context, widget.value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Icon(widget.icon, color: primaryOrange),
            const SizedBox(width: 16),
            Text(
              widget.text,
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen>
    with TickerProviderStateMixin {
  bool isShuffle = false;
  late AnimationController _rotationController;
  Future<String?>? _lyricsFuture;

  late final MusicService _musicService;

  static const Color primaryOrange = Color(0xFFFF6600);
  static const Color lightestOrange = Color(0xFFFFAF7A);
  static const Color veryLightOrange = Color(0xFFFF9D5C);

  @override
  void initState() {
    super.initState();
    _musicService = context.read<MusicService>();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _musicService.isPlayingNotifier.addListener(_handlePlayerStateChange);
    _musicService.currentSongNotifier.addListener(_handleSongChange);

    if (_musicService.isPlayingNotifier.value) {
      _rotationController.repeat();
    }

    final currentSong = _musicService.currentSongNotifier.value;
    if (currentSong != null) {
      _fetchLyrics(currentSong);
    }
  }

  void _fetchLyrics(Song song) {
    setState(() {
      _lyricsFuture = GeniusService.getLyrics(song.title, song.artist);
    });
  }

  void _handleSongChange() {
    final newSong = _musicService.currentSongNotifier.value;
    if (newSong != null) {
      _fetchLyrics(newSong);
    }
    setState(() {});
  }

  void _handlePlayerStateChange() {
    if (mounted) {
      final isPlaying = _musicService.isPlayingNotifier.value;
      if (isPlaying) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _musicService.isPlayingNotifier.removeListener(_handlePlayerStateChange);
    _musicService.currentSongNotifier.removeListener(_handleSongChange);
    _rotationController.dispose();
    super.dispose();
  }

  Widget _buildTopBar(
    BuildContext context,
    Color textDark,
    Color iconColor,
    Song currentSong,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.keyboard_arrow_down, color: iconColor, size: 30),
          ),
          Text(
            "Now Playing",
            style: TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              cardColor: Theme.of(context).colorScheme.surface,
              popupMenuTheme: PopupMenuThemeData(
                color: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 8,
                textStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            child: PopupMenuButton<String>(
              onSelected: (String result) {
                if (result == 'about_artist') {
                  final artist = allArtists.firstWhere(
                    (a) => a['name'] == currentSong.artist,
                    orElse: () => {
                      'name': currentSong.artist,
                      'image': '',
                      'headerImage': '',
                      'followers': '0',
                      'albums': [],
                    },
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArtistScreen(artist: artist),
                    ),
                  );
                } else if (result == 'about_song') {
                  _showSongDetailsDialog(context, currentSong);
                } else if (result == 'add_to_playlist') {
                  _showAddToPlaylistOptions(context, currentSong);
                } else if (result == 'report') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Thank you for your report! We will investigate.',
                      ),
                      backgroundColor: primaryOrange,
                    ),
                  );
                }
              },
              icon: Icon(Icons.more_horiz, color: iconColor, size: 30),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                _CustomPopupMenuItem<String>(
                  value: 'add_to_playlist',
                  icon: Icons.playlist_add,
                  text: 'Add to a Playlist',
                ),
                _CustomPopupMenuItem<String>(
                  value: 'about_artist',
                  icon: Icons.person_outline,
                  text: 'About Artist',
                ),
                _CustomPopupMenuItem<String>(
                  value: 'about_song',
                  icon: Icons.info_outline,
                  text: 'About Song',
                ),
                const PopupMenuDivider(color: Colors.black),
                _CustomPopupMenuItem<String>(
                  value: 'report',
                  icon: Icons.flag_outlined,
                  text: 'Report Something',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final musicService = context.watch<MusicService>();
    final playlistService = context.watch<PlaylistService>();

    final theme = Theme.of(context);
    final textDark = theme.colorScheme.onSurface;
    final textLight = theme.colorScheme.onSurface.withOpacity(0.7);
    final iconColor = theme.unselectedWidgetColor;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: (() {
          final currentSong = musicService.currentSongNotifier.value;
          if (currentSong == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final isLiked = playlistService.isLiked(currentSong);

          return SafeArea(
            child: Column(
              children: [
                _buildTopBar(context, textDark, iconColor, currentSong),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(height: 20),
                        AnimatedBuilder(
                          animation: _rotationController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationController.value * 2 * math.pi,
                              child: Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.shadowColor.withOpacity(
                                        0.15,
                                      ),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    currentSong.imageUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentSong.title,
                                      style: TextStyle(
                                        color: textDark,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      currentSong.artist,
                                      style: TextStyle(
                                        color: textLight,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  playlistService.toggleLike(currentSong);
                                },
                                icon: Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isLiked ? Colors.red : iconColor,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildControls(
                          context,
                          theme,
                          textDark,
                          textLight,
                          iconColor,
                          musicService,
                        ),
                        const SizedBox(height: 40),
                        _buildLyricsSection(theme),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        })(),
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    ThemeData theme,
    Color textDark,
    Color textLight,
    Color iconColor,
    MusicService musicService,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              ValueListenableBuilder<Duration>(
                valueListenable: musicService.totalDurationNotifier,
                builder: (context, totalDuration, _) {
                  return ValueListenableBuilder<Duration>(
                    valueListenable: musicService.currentDurationNotifier,
                    builder: (context, currentDuration, _) {
                      double sliderValue = (totalDuration.inMilliseconds > 0)
                          ? (currentDuration.inMilliseconds /
                                totalDuration.inMilliseconds)
                          : 0.0;
                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: primaryOrange,
                              inactiveTrackColor:
                                  theme.brightness == Brightness.light
                                  ? lightestOrange
                                  : Colors.white30,
                              thumbColor: primaryOrange,
                              overlayColor: primaryOrange.withOpacity(0.2),
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                            ),
                            child: Slider(
                              value: sliderValue.clamp(0.0, 1.0),
                              onChanged: (value) {
                                final newPosition = Duration(
                                  seconds: (totalDuration.inSeconds * value)
                                      .round(),
                                );
                                musicService.seek(newPosition);
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(currentDuration),
                                style: TextStyle(
                                  color: textLight,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatDuration(totalDuration),
                                style: TextStyle(
                                  color: textLight,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () => setState(() => isShuffle = !isShuffle),
                icon: Icon(
                  Icons.shuffle,
                  color: isShuffle ? primaryOrange : iconColor,
                  size: 30,
                ),
              ),
              IconButton(
                onPressed: musicService.playPrevious,
                icon: Icon(Icons.skip_previous, color: textDark, size: 40),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: musicService.isPlayingNotifier,
                builder: (context, isPlaying, _) {
                  return Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryOrange,
                    ),
                    child: IconButton(
                      onPressed: () {
                        if (isPlaying) {
                          musicService.pause();
                        } else {
                          musicService.play();
                        }
                      },
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                onPressed: musicService.playNext,
                icon: Icon(Icons.skip_next, color: textDark, size: 40),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: musicService.isRepeatNotifier,
                builder: (context, isRepeat, _) {
                  return IconButton(
                    onPressed: musicService.toggleRepeat,
                    icon: Icon(
                      Icons.repeat,
                      color: isRepeat ? primaryOrange : iconColor,
                      size: 30,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLyricsSection(ThemeData theme) {
    Widget centeredMessage(String message) {
      return Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Lyrics",
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: FutureBuilder<String?>(
              future: _lyricsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryOrange),
                  );
                }

                if (snapshot.hasError) {
                  return centeredMessage("Error loading lyrics.");
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return centeredMessage("Lyrics not found for this song.");
                }

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      snapshot.data!,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.6,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _showSongDetailsDialog(BuildContext context, Song song) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            "About This Song",
            style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  "Title: ${song.title}",
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  "Artist: ${song.artist}",
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  "Genre: ${allSongs.firstWhere((s) => s['title'] == song.title)['genre']}",
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "Close",
                style: TextStyle(color: primaryOrange),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddToPlaylistOptions(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer<PlaylistService>(
          builder: (context, playlistService, child) {
            final playlists = playlistService.playlists;
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Add to Playlist',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: veryLightOrange.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add, color: primaryOrange),
                    ),
                    title: const Text('Create New Playlist'),
                    onTap: () {
                      Navigator.pop(context);
                      _showCreatePlaylistDialog(context, playlistService, {
                        'title': song.title,
                        'artist': song.artist,
                        'image': song.imageUrl,
                      });
                    },
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                      child: playlists.isEmpty
                          ? Center(
                              key: const ValueKey('empty_state'),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.playlist_add,
                                    size: 60,
                                    color: Theme.of(
                                      context,
                                    ).unselectedWidgetColor,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "You don't have any playlists yet.",
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              key: const ValueKey('playlist_list'),
                              itemCount: playlists.length,
                              itemBuilder: (context, index) {
                                final playlist = playlists[index];
                                final songCount = playlist.songTitles.length;
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    leading: _buildPlaylistArt(
                                      playlist,
                                      playlistService,
                                    ),
                                    title: Text(
                                      playlist.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text('$songCount songs'),
                                    onTap: () {
                                      playlistService.addSongsToPlaylist(
                                        playlist.id,
                                        [
                                          {
                                            'title': song.title,
                                            'artist': song.artist,
                                            'image': song.imageUrl,
                                          },
                                        ],
                                      );
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Added to '${playlist.name}'.",
                                          ),
                                          backgroundColor: primaryOrange,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlaylistArt(Playlist playlist, PlaylistService playlistService) {
    final songs = playlistService.getSongsForPlaylist(playlist);
    if (songs.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: veryLightOrange.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.music_note, color: primaryOrange, size: 30),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 50,
        height: 50,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
          itemCount: songs.length > 4 ? 4 : songs.length,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return Image.network(
              songs[index]['image']!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: veryLightOrange.withOpacity(0.5)),
            );
          },
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(
    BuildContext context,
    PlaylistService playlistService,
    Map<String, String> song,
  ) {
    final TextEditingController nameController = TextEditingController();
    final theme = Theme.of(context);
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
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
                AnimatedPadding(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.only(
                    bottom: isKeyboardVisible ? 16.0 : 0.0,
                  ),
                  child: TextField(
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
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      playlistService.createPlaylist(nameController.text);
                      playlistService.addSongsToPlaylist(
                        playlistService.playlists.last.id,
                        [song],
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Created playlist '${nameController.text}' and added the song.",
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
}
