// screen/search_screen.dart
// ignore_for_file: prefer_final_fields, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:clone_mp/data/updated_music_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clone_mp/services/playlist_service.dart';
import 'package:provider/provider.dart';
import 'package:clone_mp/services/music_service.dart';

class SearchScreen extends StatefulWidget {
  final Function(Map<String, String> song) onPlaySong;

  const SearchScreen({super.key, required this.onPlaySong});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String _searchQuery = "";
  bool _isSearching = false;
  List<Map<String, String>> _searchResults = [];
  List<String> _recentSearches = [];

  final List<Map<String, String>> _allSongs = allSongs;

  static const Color primaryOrange = Color(0xFFFF6600);
  static const Color mediumOrange = Color(0xFFFF781F);
  static const Color lightestOrange = Color(0xFFFFAF7A);
  static const Color veryLightOrange = Color(0xFFFF9D5C);

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  void _addToRecentSearches(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _recentSearches.removeWhere(
        (term) => term.toLowerCase() == query.trim().toLowerCase(),
      );
      _recentSearches.insert(0, query.trim());
      if (_recentSearches.length > 10) {
        _recentSearches.removeLast();
      }
    });
    _saveRecentSearches();
  }

  void _removeFromRecentSearches(String query) {
    setState(() {
      _recentSearches.remove(query);
    });
    _saveRecentSearches();
  }

  void _clearRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
    _saveRecentSearches();
  }

  void _performSearch(String query) {
    _searchQuery = query;
    _isSearching = query.isNotEmpty;
    setState(() {});

    if (query.isEmpty) {
      _searchResults.clear();
      return;
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && query == _searchQuery) {
        setState(() {
          _searchResults = _filterResults(query);
          _isSearching = false;
        });
      }
    });
  }

  List<Map<String, String>> _filterResults(String query) {
    final lowerQuery = query.toLowerCase();
    return _allSongs
        .where(
          (song) =>
              (song["title"] ?? "").toLowerCase().contains(lowerQuery) ||
              (song["artist"] ?? "").toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  void _showSongOptions(BuildContext context, Map<String, String> song) {
    final playlistService = context.read<PlaylistService>();
    final isLiked = playlistService.isLiked(
      Song(
        title: song['title']!,
        artist: song['artist']!,
        assetPath: '',
        imageUrl: song['image']!,
      ),
    );

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked
                    ? Colors.red
                    : Theme.of(context).unselectedWidgetColor,
              ),
              title: Text(isLiked ? 'Unlike this song' : 'Like this song'),
              onTap: () {
                final songObj = Song(
                  title: song['title']!,
                  artist: song['artist']!,
                  assetPath: '',
                  imageUrl: song['image']!,
                );
                playlistService.toggleLike(songObj);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isLiked
                          ? "Removed from Liked Songs."
                          : "Added to Liked Songs.",
                    ),
                    backgroundColor: primaryOrange,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Add to a Playlist'),
              onTap: () {
                Navigator.pop(context); // Close the current bottom sheet
                _showAddToPlaylistOptions(context, song);
              },
            ),
          ],
        );
      },
    );
  }

  // The code for this part should be replaced with the updated version below
  void _showAddToPlaylistOptions(
    BuildContext context,
    Map<String, String> song,
  ) {
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
                      _showCreatePlaylistDialog(context, playlistService, song);
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
                                        [song],
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

  // New, more attractive create playlist dialog
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

  // Helper method for building playlist art
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          child: Column(
            children: [
              _buildSearchHeader(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildSearchContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    final theme = Theme.of(context);
    final iconColor = theme.unselectedWidgetColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: TextStyle(color: theme.colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: "What do you want to listen to?",
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          prefixIcon: Icon(Icons.search, color: iconColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: iconColor),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                )
              : null,
          filled: true,
          fillColor: theme.brightness == Brightness.light
              ? lightestOrange.withOpacity(0.4)
              : theme.colorScheme.onSurface.withOpacity(0.1),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: _performSearch,
        onSubmitted: _addToRecentSearches,
      ),
    );
  }

  Widget _buildSearchContent() {
    if (_searchQuery.isEmpty) {
      return _buildInitialState();
    } else if (_isSearching) {
      return _buildLoadingState();
    } else if (_searchResults.isEmpty) {
      return _buildEmptyState();
    } else {
      return _buildSearchResults();
    }
  }

  Widget _buildInitialState() {
    final theme = Theme.of(context);

    if (_recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: theme.unselectedWidgetColor),
            const SizedBox(height: 16),
            Text(
              "Find your favorite music",
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      return _buildRecentSearchesList();
    }
  }

  Widget _buildRecentSearchesList() {
    final theme = Theme.of(context);
    final textDark = theme.colorScheme.onSurface;
    final iconColor = theme.unselectedWidgetColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Searches",
                style: TextStyle(
                  color: textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _clearRecentSearches,
                child: const Text(
                  "Clear All",
                  style: TextStyle(color: mediumOrange),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final term = _recentSearches[index];
              return ListTile(
                leading: Icon(Icons.history, color: iconColor),
                title: Text(term, style: TextStyle(color: textDark)),
                trailing: IconButton(
                  icon: Icon(Icons.close, size: 20, color: iconColor),
                  onPressed: () => _removeFromRecentSearches(term),
                ),
                onTap: () {
                  _searchController.text = term;
                  _searchController.selection = TextSelection.fromPosition(
                    TextPosition(offset: term.length),
                  );
                  _performSearch(term);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator(color: primaryOrange));
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: theme.unselectedWidgetColor),
          const SizedBox(height: 16),
          Text(
            "No results found for \"$_searchQuery\"",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final theme = Theme.of(context);
    final textDark = theme.colorScheme.onSurface;
    final textLight = theme.colorScheme.onSurface.withOpacity(0.7);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final song = _searchResults[index];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              song["image"] ?? "",
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: lightestOrange.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.music_note, color: textDark),
                );
              },
            ),
          ),
          title: Text(
            song["title"] ?? "Unknown",
            style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            song["artist"] ?? "Unknown",
            style: TextStyle(color: textLight),
          ),
          onTap: () {
            _addToRecentSearches(_searchController.text);
            widget.onPlaySong(song);
          },
          trailing: IconButton(
            icon: Icon(Icons.more_vert, color: theme.unselectedWidgetColor),
            onPressed: () => _showSongOptions(context, song),
          ),
        );
      },
    );
  }
}
