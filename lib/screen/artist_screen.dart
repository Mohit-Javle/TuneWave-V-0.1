// ignore_for_file: deprecated_member_use

import 'package:clone_mp/data/updated_music_data.dart';
import 'package:clone_mp/services/music_service.dart';
import 'package:flutter/material.dart';

class ArtistScreen extends StatefulWidget {
  final Map<String, dynamic> artist;

  const ArtistScreen({super.key, required this.artist});

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final musicService = MusicService();

    final List<Map<String, String>> artistSongsMap = allSongs
        .where((song) => song['artist'] == widget.artist['name'])
        .toList();

    final List<Song> artistSongs = artistSongsMap
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
          _buildSliverAppBar(theme),
          _buildHeaderSection(theme),
          _buildPopularSongsSection(theme, artistSongs, musicService),
          if (widget.artist['albums'] != null) _buildAlbumsSection(theme),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
              child: Text(
                'All Songs',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          _buildAllSongsList(artistSongs, musicService),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.surface,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.artist['name']!,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.black.withOpacity(0.7),
                offset: const Offset(2.0, 2.0),
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(widget.artist['headerImage']!, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
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

  SliverToBoxAdapter _buildHeaderSection(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Text(
              '${widget.artist['followers']} Followers',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6600),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Follow'),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildPopularSongsSection(
    ThemeData theme,
    List<Song> artistSongs,
    MusicService musicService,
  ) {
    final popularSongCount = artistSongs.length > 5 ? 5 : artistSongs.length;
    final expandedSongCount = artistSongs.length > 10 ? 10 : artistSongs.length;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Popular',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Column(
                children: List.generate(
                  _isExpanded ? expandedSongCount : popularSongCount,
                  (index) {
                    return AnimatedSongTile(
                      animation: _animationController,
                      index: index,
                      song: artistSongs[index],
                      onTap: () {
                        musicService.loadPlaylist(artistSongs, index);
                      },
                    );
                  },
                ),
              ),
            ),
            if (artistSongs.length > 5)
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Text(_isExpanded ? 'SHOW LESS' : 'SEE MORE'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildAlbumsSection(ThemeData theme) {
    final List albums = widget.artist['albums'];
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
            child: Text(
              'Albums',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                return _buildAlbumCard(theme, album);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumCard(ThemeData theme, Map<String, dynamic> album) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.2),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.network(
              album['image'],
              height: 120,
              width: 140,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            album['title'],
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            album['year'],
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  SliverList _buildAllSongsList(
    List<Song> artistSongs,
    MusicService musicService,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final song = artistSongs[index];
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
          onTap: () {
            musicService.loadPlaylist(artistSongs, index);
          },
        );
      }, childCount: artistSongs.length),
    );
  }
}

// A helper widget for animating the song tiles
class AnimatedSongTile extends StatelessWidget {
  final Animation<double> animation;
  final int index;
  final Song song;
  final VoidCallback onTap;

  const AnimatedSongTile({
    super.key,
    required this.animation,
    required this.index,
    required this.song,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final animationOffset =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: animation,
            curve: Interval((1 / 10) * index, 1.0, curve: Curves.easeOut),
          ),
        );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: animationOffset,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${index + 1}',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  song.imageUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
          title: Text(
            song.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.more_vert, color: Colors.grey),
          onTap: onTap,
        ),
      ),
    );
  }
}
