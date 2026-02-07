# Tunewave V2 Implementation Plan

## Goal Description
Upgrade Tunewave to Version 2.0 by replacing static data with a dynamic API source that provides Audio, Lyrics, and Metadata in a single request. We will use the **Unofficial JioSaavn API** as the primary data source. This will allow searching for songs, streaming high-quality audio, and displaying synchronized lyrics (where available).

## User Review Required
> [!IMPORTANT]
> **Legal Disclaimer**: This project uses an unofficial API for educational/portfolio purposes. If you plan to publish this app to the Play Store/App Store, you must secure official licensing rights or switch to an official API like Spotify/Apple Music SDKs.

## Proposed Changes

### Data Layer
#### [NEW] `lib/services/api_service.dart`
- Create a service to handle HTTP requests.
- Endpoints:
    - `searchSongs(String query)`: Returns a list of songs matching the query.
    - `getSongDetails(String id)`: Returns high-quality download links and lyrics.

#### [NEW] `lib/models/song_model.dart`
- Create a robust `SongModel` class to parse the JSON response from the API.
- Fields: `id`, `name`, `artist`, `album`, `imageUrl`, `downloadUrl` (320kbps), `lyrics`, `hasLyrics`.

### Service Layer
#### [MODIFY] `lib/services/music_service.dart`
- Remove static `Song` class.
- Update `_player` to stream from URL (`UrlSource`) instead of assets.
- Add `search(query)` method that calls `ApiService`.

### UI Layer
#### [MODIFY] `lib/screen/home_screen.dart`
- Replace the static list with a `FutureBuilder` or `StreamBuilder` connected to the API current trends or a default playlist.
- Update `SongItem` widgets to load images from Network (`Image.network`).

#### [MODIFY] `lib/screen/music_screen.dart` (Player)
- Add a "Lyrics" tab or button.
- If `song.hasLyrics` is true, fetch and display lyrics.

#### [NEW] `lib/screen/auth_screen.dart`
- Implement a basic login screen (Placeholder for now, or Firebase if requested immediately).

## Verification Plan

### Automated Tests
- Run `flutter test` to ensure no regressions in basic widgets.
- Write a new unit test for `ApiService` to verify it correctly parses a sample JSON response.

### Manual Verification
1.  **Search**: Type "Arijit Singh" in the search bar. Verify results appear with correct images.
2.  **Playback**: Tap a song. Verify audio starts playing within 2-3 seconds.
3.  **Lyrics**: Open the player. Check if Lyrics are available and display correctly.
4.  **MiniPlayer**: Verify mini-player updates with the network image and artist name.
