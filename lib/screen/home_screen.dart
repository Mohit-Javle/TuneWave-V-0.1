// home_screen.dart
// ignore_for_file: prefer_final_fields, deprecated_member_use, use_build_context_synchronously

import 'package:clone_mp/screen/artist_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:clone_mp/data/updated_music_data.dart';
import 'package:clone_mp/services/auth_service.dart';
import 'package:clone_mp/models/user_model.dart';
import 'package:clone_mp/services/ui_state_service.dart';

class HomeScreen extends StatefulWidget {
  final Function(Map<String, String> song) onPlaySong;
  final Map<String, String>? currentSong;
  final bool isPlaying;
  final VoidCallback onTogglePlayPause;

  const HomeScreen({
    super.key,
    required this.onPlaySong,
    this.currentSong,
    this.isPlaying = false,
    required this.onTogglePlayPause,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFilter = "All";
  int _topChartsCount = 5;
  int _topArtistsCount = 5;
  bool _isPlaylistsExpanded = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const Color primaryOrange = Color.fromRGBO(255, 102, 0, 1);
  static const Color mediumOrange = Color(0xFFFF781F);
  static const Color veryLightOrange = Color(0xFFFF9D5C);

  final List<Map<String, String>> featuredPlaylists = [
    {
      "title": "Today's Top Hits",
      "subtitle": "The biggest songs right now",
      "image": "https://i.ibb.co/B2kSS9B1/download-4.jpg",
      "songCount": "50",
    },
    {
      "title": "Sem Bihari",
      "subtitle": "New music from hip-hop's heavy-hitters",
      "image":
          "https://i.ibb.co/TDx4fd0B/Whats-App-Image-2025-09-02-at-10-25-07-PM.jpg",
      "songCount": "65",
    },
    {
      "title": "All Out 2010s",
      "subtitle": "The biggest songs of the 2010s",
      "image": "https://i.ibb.co/fJZxpQZ/download-3.jpg",
      "songCount": "75",
    },
    {
      "title": "Chill Pop",
      "subtitle": "Chill out with these pop gems",
      "image": "https://i.ibb.co/fdBHDjMJ/download-2.jpg",
      "songCount": "45",
    },
    {
      "title": "Rock Classics",
      "subtitle": "Legendary rock anthems",
      "image": "https://i.ibb.co/pr9MsT0t/download-1.jpg",
      "songCount": "100",
    },
    {
      "title": "Acoustic Hits",
      "subtitle": "Unplugged and beautiful",
      "image": "https://i.ibb.co/2TcFcBt/download.jpg",
      "songCount": "40",
    },
  ];

  final List<String> genres = [
    "All",
    "Pop",
    "Hip-Hop",
    "Desi Hip-Hop",
    "Rock",
    "Bollywood",
    "R&B",
    "Punjabi Pop",
    "Dance-Pop",
    "Country",
  ];

  Future<void> _showImprovedLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 10),
              const Icon(Icons.logout_rounded, color: primaryOrange, size: 50),
              const SizedBox(height: 20),
              Text(
                'Confirm Sign Out',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to sign out?',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: theme.colorScheme.onSurface,
                        side: BorderSide(
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color.fromRGBO(255, 102, 0, 1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text('Sign Out'),
                      onPressed: () {
                        AuthService.instance.logout();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uiStateService = Provider.of<UiStateService>(context);

    final List<Map<String, String>> recentlyPlayed = allSongs.take(4).toList();
    final List<Map<String, String>> filteredSongs = (selectedFilter == "All")
        ? allSongs
        : allSongs.where((song) => song['genre'] == selectedFilter).toList();
    final List<Map<String, String>> topCharts = filteredSongs
        .skip(4)
        .take(_topChartsCount)
        .toList();
    final List<Map<String, dynamic>> topArtists = allArtists
        .take(_topArtistsCount)
        .toList();
    final bool canExpandPlaylists = featuredPlaylists.length > 2;
    final String playlistButtonText = _isPlaylistsExpanded
        ? "Show Less"
        : "See All";
    final bool canExpandArtists = allArtists.length > 5;
    final bool isArtistsExpanded = _topArtistsCount > 5;
    final String artistButtonText = isArtistsExpanded ? "Show Less" : "See All";
    final int totalAvailableChartSongs = (filteredSongs.length - 4)
        .clamp(0, double.infinity)
        .toInt();
    final bool canExpandCharts = totalAvailableChartSongs > 5;
    final bool isChartsExpanded = _topChartsCount > 5;
    final String chartButtonText = isChartsExpanded ? "Show Less" : "See All";

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildAppDrawer(),
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          uiStateService.hideMiniPlayer();
        } else {
          uiStateService.showMiniPlayer();
        }
      },
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
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: theme.colorScheme.surface,
                surfaceTintColor: theme.colorScheme.surface,
                scrolledUnderElevation: 4.0,
                shadowColor: Colors.black26,
                elevation: 0,
                pinned: true,
                floating: false,
                toolbarHeight: 80,
                expandedHeight: 150,
                leading: Builder(
                  builder: (context) => GestureDetector(
                    onTap: () {
                      Scaffold.of(context).openDrawer();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: StreamBuilder<UserModel?>(
                        stream: AuthService.instance.userStream,
                        initialData: AuthService.instance.currentUser,
                        builder: (context, snapshot) {
                          final user = snapshot.data;

                          final String firstLetter =
                              user != null && user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'G'; // G for Guest
                          final String placeholderUrl =
                              'https://placehold.co/100x100/FF9D5C/ffffff.png?text=$firstLetter';

                          return CircleAvatar(
                            radius: 60,
                            backgroundImage: NetworkImage(
                              user?.imageUrl ?? placeholderUrl,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    _getGreeting(),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 72.0,
                    bottom: 20.0,
                  ),
                  centerTitle: false,
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: genres.length,
                    itemBuilder: (context, index) {
                      final genre = genres[index];
                      final isSelected = selectedFilter == genre;
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: FilterChip(
                          label: Text(genre),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              selectedFilter = genre;
                              _topChartsCount = 5;
                            });
                          },
                          selectedColor: primaryOrange,
                          backgroundColor: theme.colorScheme.surface
                              .withOpacity(0.5),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          side: BorderSide.none,
                          showCheckmark: false,
                        ),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  "Recently Played",
                  showSeeAll: false,
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: recentlyPlayed.length,
                    itemBuilder: (context, index) {
                      final song = recentlyPlayed[index];
                      return _buildSongCard(song);
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  "Top Charts",
                  showSeeAll: canExpandCharts,
                  seeAllText: chartButtonText,
                  onSeeAll: () {
                    setState(() {
                      if (isChartsExpanded) {
                        _topChartsCount = 5;
                      } else {
                        _topChartsCount = 15;
                      }
                    });
                  },
                ),
              ),
              topCharts.isEmpty
                  ? SliverToBoxAdapter(
                      child: Container(
                        height: 100,
                        alignment: Alignment.center,
                        child: Text(
                          'No songs found for "$selectedFilter"',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final song = topCharts[index];
                        return _buildSongListTile(song, index + 1);
                      }, childCount: topCharts.length),
                    ),
              _buildArtistSection(
                artists: topArtists,
                showSeeAll: canExpandArtists,
                seeAllText: artistButtonText,
                onSeeAll: () {
                  setState(() {
                    if (isArtistsExpanded) {
                      _topArtistsCount = 5;
                    } else {
                      _topArtistsCount = allArtists.length;
                    }
                  });
                },
              ),
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  "Featured Playlists",
                  showSeeAll: canExpandPlaylists,
                  seeAllText: playlistButtonText,
                  onSeeAll: () {
                    setState(() {
                      _isPlaylistsExpanded = !_isPlaylistsExpanded;
                    });
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: featuredPlaylists.length.clamp(0, 2),
                    itemBuilder: (context, index) {
                      final playlist = featuredPlaylists[index];
                      return _buildPlaylistCard(playlist);
                    },
                  ),
                ),
              ),
              if (_isPlaylistsExpanded)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 160 / 200,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final playlist = featuredPlaylists[index + 2];
                        return _buildPlaylistCard(playlist, useMargin: false);
                      },
                      childCount: (featuredPlaylists.length - 2).clamp(0, 100),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtistSection({
    required List<Map<String, dynamic>> artists,
    required bool showSeeAll,
    required String seeAllText,
    required VoidCallback onSeeAll,
  }) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            "Top Artists",
            showSeeAll: showSeeAll,
            seeAllText: seeAllText,
            onSeeAll: onSeeAll,
          ),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: artists.length,
              itemBuilder: (context, index) {
                final artist = artists[index];
                return _buildArtistCard(artist);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistCard(Map<String, dynamic> artist) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ArtistScreen(artist: artist)),
        );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(artist['image']!),
              backgroundColor: veryLightOrange.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              artist['name']!,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppDrawer() {
    final String? currentRoute = ModalRoute.of(context)?.settings.name;
    final theme = Theme.of(context);
    final uiStateService = Provider.of<UiStateService>(context, listen: false);

    final Color drawerBackgroundColor = theme.brightness == Brightness.light
        ? const Color(0xFFF1F4F8)
        : const Color(0xFF1E1E1E);
    final Color textColor = theme.colorScheme.onSurface;
    final Color iconColor = theme.unselectedWidgetColor;
    final Color selectedColor = primaryOrange;
    final Color selectedTileColor = primaryOrange.withOpacity(0.1);

    return Drawer(
      backgroundColor: drawerBackgroundColor,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                StreamBuilder<UserModel?>(
                  stream: AuthService.instance.userStream,
                  initialData: AuthService.instance.currentUser,
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    if (user == null) {
                      return UserAccountsDrawerHeader(
                        accountName: const Text(
                          'Guest User',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        accountEmail: const Text(
                          'Not logged in',
                          style: TextStyle(color: Colors.white70),
                        ),
                        currentAccountPicture: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 32,
                          child: CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(
                              'https://placehold.co/100x100/FF9D5C/ffffff.png?text=G',
                            ),
                          ),
                        ),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryOrange, veryLightOrange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      );
                    }

                    final String firstLetter = user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : '?';
                    final String placeholderUrl =
                        'https://placehold.co/100x100/FF9D5C/ffffff.png?text=$firstLetter';

                    return UserAccountsDrawerHeader(
                      accountName: Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      accountEmail: Text(
                        user.email,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      currentAccountPicture: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(
                            user.imageUrl ?? placeholderUrl,
                          ),
                        ),
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryOrange, veryLightOrange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.person_outline,
                  text: 'Profile',
                  isSelected: currentRoute == '/profile',
                  onTap: () {
                    Navigator.pop(context);
                    if (currentRoute != '/profile') {
                      uiStateService.hideMiniPlayer();
                      Navigator.pushNamed(context, '/profile').then((_) {
                        uiStateService.showMiniPlayer();
                      });
                    }
                  },
                  selectedColor: selectedColor,
                  iconColor: iconColor,
                  textColor: textColor,
                  selectedTileColor: selectedTileColor,
                ),
                _buildDrawerItem(
                  icon: Icons.favorite_border,
                  text: 'Liked Songs',
                  isSelected: currentRoute == '/liked_songs',
                  onTap: () {
                    Navigator.pop(context);
                    if (currentRoute != '/liked_songs') {
                      uiStateService.hideMiniPlayer();
                      Navigator.pushNamed(context, '/liked_songs').then((_) {
                        uiStateService.showMiniPlayer();
                      });
                    }
                  },
                  selectedColor: selectedColor,
                  iconColor: iconColor,
                  textColor: textColor,
                  selectedTileColor: selectedTileColor,
                ),
                _buildDrawerItem(
                  icon: Icons.notifications_outlined,
                  text: 'Notifications',
                  isSelected: currentRoute == '/notifications',
                  onTap: () {
                    Navigator.pop(context);
                    if (currentRoute != '/notifications') {
                      uiStateService.hideMiniPlayer();
                      Navigator.pushNamed(context, '/notifications').then((_) {
                        uiStateService.showMiniPlayer();
                      });
                    }
                  },
                  selectedColor: selectedColor,
                  iconColor: iconColor,
                  textColor: textColor,
                  selectedTileColor: selectedTileColor,
                ),
                _buildDrawerItem(
                  icon: Icons.person_add_alt_outlined,
                  text: 'Invite Friends',
                  isSelected: currentRoute == '/invite_friends',
                  onTap: () {
                    Navigator.pop(context);
                    if (currentRoute != '/invite_friends') {
                      uiStateService.hideMiniPlayer();
                      Navigator.pushNamed(context, '/invite_friends').then((_) {
                        uiStateService.showMiniPlayer();
                      });
                    }
                  },
                  selectedColor: selectedColor,
                  iconColor: iconColor,
                  textColor: textColor,
                  selectedTileColor: selectedTileColor,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Divider(height: 1, color: Colors.grey),
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  text: 'Settings',
                  isSelected: currentRoute == '/settings',
                  onTap: () {
                    Navigator.pop(context);
                    if (currentRoute != '/settings') {
                      uiStateService.hideMiniPlayer();
                      Navigator.pushNamed(context, '/settings').then((_) {
                        uiStateService.showMiniPlayer();
                      });
                    }
                  },
                  selectedColor: selectedColor,
                  iconColor: iconColor,
                  textColor: textColor,
                  selectedTileColor: selectedTileColor,
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  text: 'About',
                  isSelected: currentRoute == '/about',
                  onTap: () {
                    Navigator.pop(context);
                    if (currentRoute != '/about') {
                      uiStateService.hideMiniPlayer();
                      Navigator.pushNamed(context, '/about').then((_) {
                        uiStateService.showMiniPlayer();
                      });
                    }
                  },
                  selectedColor: selectedColor,
                  iconColor: iconColor,
                  textColor: textColor,
                  selectedTileColor: selectedTileColor,
                ),
                _buildDrawerItem(
                  icon: Icons.logout,
                  text: 'Sign Out',
                  onTap: () async {
                    uiStateService.hideMiniPlayer();
                    await _showImprovedLogoutDialog();
                    uiStateService.showMiniPlayer();
                  },
                  selectedColor: selectedColor,
                  iconColor: iconColor,
                  textColor: textColor,
                  selectedTileColor: selectedTileColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isSelected = false,
    required Color selectedColor,
    required Color iconColor,
    required Color textColor,
    required Color selectedTileColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? selectedTileColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          ListTile(
            leading: Icon(icon, color: isSelected ? selectedColor : iconColor),
            title: Text(
              text,
              style: TextStyle(
                color: isSelected ? selectedColor : textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            onTap: onTap,
          ),
          if (isSelected)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: selectedColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  Widget _buildSectionHeader(
    String title, {
    VoidCallback? onSeeAll,
    bool showSeeAll = true,
    String seeAllText = "See All",
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (showSeeAll)
            TextButton(
              onPressed:
                  onSeeAll ??
                  () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Show all $title")));
                  },
              child: Text(
                seeAllText,
                style: const TextStyle(color: mediumOrange),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSongCard(Map<String, String> song) {
    final theme = Theme.of(context);
    final bool isThisSongPlaying =
        widget.currentSong != null &&
        widget.currentSong!['title'] == song['title'] &&
        widget.isPlaying;

    return GestureDetector(
      onTap: () => widget.onPlaySong(song),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    song["image"]!,
                    height: 120,
                    width: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        width: 150,
                        decoration: BoxDecoration(
                          color: veryLightOrange.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.music_note,
                          color: theme.colorScheme.onSurface,
                        ),
                      );
                    },
                  ),
                ),
                if (isThisSongPlaying)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: primaryOrange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pause,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              song["title"]!,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              song["artist"]!,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongListTile(Map<String, String> song, int rank) {
    final theme = Theme.of(context);
    final bool isThisSongPlaying =
        widget.currentSong != null &&
        widget.currentSong!['title'] == song['title'] &&
        widget.isPlaying;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              child: Text(
                "$rank",
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                song["image"]!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: veryLightOrange.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.music_note,
                      color: theme.colorScheme.onSurface,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        title: Text(
          song["title"]!,
          style: TextStyle(
            color: isThisSongPlaying
                ? primaryOrange
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          song["artist"]!,
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
        trailing: Icon(
          isThisSongPlaying
              ? Icons.pause_circle_filled
              : Icons.play_circle_filled,
          color: isThisSongPlaying
              ? primaryOrange
              : theme.unselectedWidgetColor,
        ),
        onTap: () => widget.onPlaySong(song),
      ),
    );
  }

  Widget _buildPlaylistCard(
    Map<String, String> playlist, {
    bool useMargin = true,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Opening ${playlist["title"]}")));
      },
      child: Container(
        width: 160,
        margin: useMargin ? const EdgeInsets.only(right: 16) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                playlist["image"]!,
                height: 120,
                width: 160,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    width: 160,
                    decoration: BoxDecoration(
                      color: veryLightOrange.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.playlist_play,
                      color: theme.colorScheme.onSurface,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              playlist["title"]!,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              "${playlist["songCount"]} songs",
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
