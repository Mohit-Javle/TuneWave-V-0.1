
import 'package:clone_mp/models/album_model.dart';
import 'package:clone_mp/services/api_service.dart';
import 'package:clone_mp/services/music_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ArtistDetailScreen extends StatefulWidget {
  final Map<String, String> artist;

  const ArtistDetailScreen({super.key, required this.artist});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  List<SongModel> topSongs = [];
  List<AlbumModel> albums = [];
  bool isLoading = true;
  bool _showAllSongs = false; // State for "See More"

  @override
  void initState() {
    super.initState();
    _loadArtistDetails();
  }

  Future<void> _loadArtistDetails() async {
    try {
      final api = ApiService();
      // Use ID if available, otherwise search (fallback)
      final artistId = widget.artist['id'];
      
      if (artistId != null && artistId.isNotEmpty) {
        final details = await api.getArtistDetails(artistId);
        
        List<AlbumModel> fetchedAlbums = details['albums'] ?? [];
        List<SongModel> fetchedSongs = details['topSongs'] ?? [];

        // FALLBACK: If albums are empty, search by name
        if (fetchedAlbums.isEmpty) {
           fetchedAlbums = await api.searchAlbums(widget.artist['name']!);
        }
        
        // Filter: Check if artist is present in the comma-separated list
        // And Sort: Newest first
        final artistName = widget.artist['name']!.toLowerCase().trim();
        
        fetchedAlbums = fetchedAlbums.where((album) {
           final albumArtists = album.artist.toLowerCase();
           // Strict check: Artist name MUST be the start. 
           // This handles "Seedhe Maut" vs "KR$NA, Seedhe Maut" (which should be excluded).
           return albumArtists.startsWith(artistName); 
        }).toList();

        // Sort by year descending (parse year to int safely)
        fetchedAlbums.sort((a, b) {
           int yearA = int.tryParse(a.year) ?? 0;
           int yearB = int.tryParse(b.year) ?? 0;
           return yearB.compareTo(yearA); // Descending
        });

        if (mounted) {
          setState(() {
            topSongs = fetchedSongs;
            albums = fetchedAlbums;
            isLoading = false;
          });
        }
      } else {
        // Fallback to name search if ID is missing (legacy support)
        final songs = await api.searchSongs(widget.artist['name']!);
        var searchedAlbums = await api.searchAlbums(widget.artist['name']!);
        
        // Filter and Sort for fallback as well
        final artistName = widget.artist['name']!.toLowerCase().trim();
        searchedAlbums = searchedAlbums.where((album) {
           final albumArtists = album.artist.toLowerCase();
           return albumArtists.startsWith(artistName);
        }).toList();
        
        searchedAlbums.sort((a, b) {
           int yearA = int.tryParse(a.year) ?? 0;
           int yearB = int.tryParse(b.year) ?? 0;
           return yearB.compareTo(yearA);
        });
        
        if (mounted) {
          setState(() {
            topSongs = songs.take(10).toList(); // Ensure we have enough for see more if available
            albums = searchedAlbums;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading artist details: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final musicService = Provider.of<MusicService>(context, listen: false);

    // Determine how many songs to show
    final visibleSongs = _showAllSongs ? topSongs : topSongs.take(5).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.artist['name']!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(offset: Offset(0, 1), blurRadius: 3.0, color: Colors.black),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.artist['image']!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[900],
                      child: const Center(child: Icon(Icons.person, size: 80, color: Colors.white54)),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                        stops: [0.6, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: theme.colorScheme.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          if (isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFFFF6600))),
            )
          else ...[
            if (topSongs.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    "Most Popular",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = visibleSongs[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Text(
                        "${index + 1}",
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      title: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              song.imageUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(width: 40, height: 40, color: Colors.grey),
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
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  song.artist,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.more_vert, color: Colors.grey),
                      onTap: () {
                        musicService.loadPlaylist(topSongs, index);
                      },
                    );
                  },
                  childCount: visibleSongs.length,
                ),
              ),
              if (topSongs.length > 5)
                  SliverToBoxAdapter(
                     child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: TextButton(
                           onPressed: () {
                              setState(() {
                                 _showAllSongs = !_showAllSongs;
                              });
                           },
                           child: Text(
                              _showAllSongs ? "See Less" : "See More",
                              style: TextStyle(color: theme.colorScheme.primary),
                           ),
                        ),
                     ),
                  ),
            ],
            if (albums.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Text(
                    "Discography",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: albums.length,
                    itemBuilder: (context, index) {
                      final album = albums[index];
                      return GestureDetector(
                        onTap: () {
                           Navigator.pushNamed(context, '/album', arguments: album);
                        },
                        child: Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  album.imageUrl,
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 140, 
                                    height: 140, 
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.album, color: Colors.white54, size: 40),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                album.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                album.year, // Assuming year or artist
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ],
      ),
    );
  }
}
