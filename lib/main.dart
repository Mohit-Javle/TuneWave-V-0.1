// main.dart
// ignore_for_file: deprecated_member_use, unused_element

import 'package:clone_mp/services/music_service.dart';
import 'package:clone_mp/services/theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:clone_mp/screen/home_screen.dart';
import 'package:clone_mp/screen/library_screen.dart';
import 'package:clone_mp/screen/login_screen.dart';
import 'package:clone_mp/screen/music_screen.dart';
import 'package:clone_mp/screen/search_screen.dart';
import 'package:provider/provider.dart';
import 'package:clone_mp/screen/change_password_screen.dart';
import 'package:clone_mp/screen/about_screen.dart';
import 'package:clone_mp/screen/artist_detail_screen.dart';
import 'package:clone_mp/screen/album_detail_screen.dart';
import 'package:clone_mp/models/album_model.dart';
import 'package:clone_mp/screen/invite_friends_screen.dart';
import 'package:clone_mp/screen/splash_screen.dart';

import 'package:clone_mp/screen/profile_screen.dart';
import 'package:clone_mp/screen/liked_songs_screen.dart';
import 'package:clone_mp/screen/notification_screen.dart';
import 'package:clone_mp/screen/setting_screen.dart';
import 'package:clone_mp/services/playlist_service.dart';
import 'package:clone_mp/services/ui_state_service.dart';
import 'package:clone_mp/services/follow_service.dart';
import 'package:clone_mp/services/auth_service.dart';


void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => MusicService()),
        ChangeNotifierProvider(create: (_) => PlaylistService()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => FollowService()),
        ChangeNotifierProvider(create: (_) => UiStateService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryOrange = Color(0xFFFF6600);

    final lightTheme = ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryOrange,
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: primaryOrange,
        secondary: const Color(0xFFFF781F),
        background: Colors.white,
        surface: Colors.white,
        onBackground: Colors.black87,
        onSurface: Colors.black87,
      ),
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryOrange,
      colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
        primary: primaryOrange,
        secondary: const Color(0xFFFF781F),
        background: const Color(0xFF121212),
        surface: const Color(0xFF1E1E1E),
        onBackground: Colors.white,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Music App',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeNotifier.getThemeMode,
          home: const OnboardingPager(),
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/main': (context) => const MainScreen(),
            '/login': (context) => const OnboardingPager(),
            '/profile': (context) => const ProfileScreen(),
            '/liked_songs': (context) => const LikedSongsScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/notifications': (context) => const NotificationScreen(),
            '/change_password': (context) => const ChangePasswordScreen(),
            '/about': (context) => const AboutScreen(),
            '/invite_friends': (context) => const InviteFriendsScreen(),
            '/artist': (context) => ArtistDetailScreen(
              artist: ModalRoute.of(context)!.settings.arguments as Map<String, String>,
            ),
            '/album': (context) => AlbumDetailScreen(
              album: ModalRoute.of(context)!.settings.arguments as AlbumModel,
            ),
          },
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final MusicService _musicService;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _musicService = context.read<MusicService>();
    _musicService.init();

    _musicService.currentSongNotifier.addListener(() => setState(() {}));
    _musicService.isPlayingNotifier.addListener(() => setState(() {}));
    _musicService.currentDurationNotifier.addListener(() => setState(() {}));
    _musicService.totalDurationNotifier.addListener(() => setState(() {}));

    // Listen for Playback Errors
    _musicService.errorMessageNotifier.addListener(() {
      final error = _musicService.errorMessageNotifier.value;
      if (error != null) {
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                _musicService.play();
              },
            ),
          ),
        );
      }
    });

    _pages = [
      HomeScreen(
        onPlaySong: _playNewSong,
        currentSong: _musicService.currentSongNotifier.value,
        isPlaying: _musicService.isPlayingNotifier.value,
        onTogglePlayPause: _togglePlayPause,
      ),
      SearchScreen(onPlaySong: (song) {
        _playNewSong(song);
      }),
      const LibraryScreen(),
    ];

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _playNewSong(SongModel song) {
    // For V2, we just load this single song as a playlist for now
    // Ideally, we'd pass the whole list from HomeScreen
    _musicService.loadPlaylist([song], 0);
  }

  void _togglePlayPause() {
    if (_musicService.isPlayingNotifier.value) {
      _musicService.pause();
    } else {
      _musicService.play();
    }
  }

  void _navigateToMusicPlayer() {
    if (_musicService.currentSongNotifier.value != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MusicPlayerScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiStateService = Provider.of<UiStateService>(context);

    // Rebuild HomeScreen with current state
    _pages[0] = HomeScreen(
      onPlaySong: _playNewSong,
      onTogglePlayPause: _togglePlayPause,
      currentSong: _musicService.currentSongNotifier.value,
      isPlaying: _musicService.isPlayingNotifier.value,
    );

    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        key: _scaffoldKey,
        onDrawerChanged: (isOpened) {
          if (isOpened) {
            uiStateService.hideMiniPlayer();
          } else {
            uiStateService.showMiniPlayer();
          }
        },
        body: Stack(
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: _pages[_selectedIndex],
            ),
            if (uiStateService.isMiniPlayerVisible &&
                _musicService.currentSongNotifier.value != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildMiniPlayer(),
              ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 10,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFFF6600),
          unselectedItemColor: Theme.of(context).unselectedWidgetColor,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: "Home",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_music_sharp),
              label: "Library",
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniPlayerContent(
    SongModel song,
    BuildContext context,
    bool isPlaying,
    VoidCallback onTogglePlayPause,
  ) {
    final totalDuration = _musicService.totalDurationNotifier.value;
    final currentPosition = _musicService.currentDurationNotifier.value;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  song.imageUrl,
                  width: 45,
                  height: 45,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 45,
                    height: 45,
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    child: Icon(
                      Icons.music_note,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.name,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      song.artist,
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
              IconButton(
                onPressed: onTogglePlayPause,
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: const Color(0xFFFF6600),
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: (totalDuration.inMilliseconds > 0)
                ? currentPosition.inMilliseconds / totalDuration.inMilliseconds
                : 0.0,
            backgroundColor: theme.unselectedWidgetColor.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6600)),
            minHeight: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer() {
    final currentSong = _musicService.currentSongNotifier.value;
    final isPlaying = _musicService.isPlayingNotifier.value;

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _navigateToMusicPlayer,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity!;
        if (velocity < -500) {
          _musicService.playNext();
        } else if (velocity > 500) {
          _musicService.playPrevious();
        }
      },
      child: _miniPlayerContent(
        currentSong,
        context,
        isPlaying,
        _togglePlayPause,
      ),
    );
  }
}
