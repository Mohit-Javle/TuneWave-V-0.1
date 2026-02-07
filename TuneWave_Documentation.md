# TuneWave - Project Documentation

**TuneWave** is a feature-rich, cross-platform music streaming application built using **Flutter**. It mimics the functionality of premium music apps like Spotify or JioSaavn, providing a seamless listening experience with advanced features like user authentication, personalized playlists, and smart search.

---

## 🏗️ Technical Architecture

### 1. Technology Stack
*   **Framework**: Flutter (Dart)
*   **State Management**: `Provider` (for reactive UI updates)
*   **Audio Engine**: `audioplayers` (for robust playback control)
*   **Local Database**: `SharedPreferences` (for user sessions, playlists, and settings)
*   **Networking**: `http` (for API calls)

### 2. Architecture Pattern (Service-Oriented)
The app follows a clean **MVCS (Model-View-Controller-Service)** architecture:
*   **Models**: Define data structures (e.g., `SongModel`, `UserModel`, `ArtistModel`).
*   **Views (Screens)**: The UI components that the user interacts with.
*   **Services**: The "Brain" of the app. Classes that handle business logic and data fetching.
*   **Providers**: The bridge between Services and Views, notifying the UI when data changes.

---

## 🧩 Key Modules & Features

### 1. 🎵 Music Player Core (`MusicService`)
*   **Function**: Manages the global audio state.
*   **Capabilities**: Play, Pause, Seek, Next, Previous, Shuffle, and Repeat modes.
*   **Innovation**: Uses a `StreamProxy` for web compatibility (if applicable) and handles background playback logic.
*   **Persistence**: Automatically saves your `Listening History`.

### 2. 🔐 Authentication & User System (`AuthService`)
*   **Function**: Manages user login, registration, and sessions.
*   **Security**: Stores user credentials securely locally.
*   **Persistence**: Keeps you logged in across app restarts.
*   **Multi-User**: Supports multiple accounts on a single device, keeping data isolated.

### 3. 📂 Library & Playlists (`PlaylistService`)
*   **Function**: Manages user-specific data.
*   **Features**:
    *   **Liked Songs**: Heart a song to save it instantly.
    *   **Custom Playlists**: Create, rename, and add songs to custom collections.
    *   **Isolation**: User A’s playlists are hidden when User B logs in.

### 4. 🔍 Smart Search (`ApiService`)
*   **Debouncing**: Waits for you to stop typing before searching (saves data).
*   **Categories**: Results form Songs, Albums, and Artists.
*   **History**: Remembers past searches for quick access.

### 5. 🎨 Usage & Experience
*   **Themes**: Dark/Light mode support (`ThemeNotifier`).
*   **Artist Profiles**: Deep dive into an artist's discography and top tracks.
*   **Dynamic Home**: "Most Popular", "Top Charts" (Desi Hip Hop), and "Trending" sections.

---

## 🚀 Data Flow Explanation

1.  **App Launch (`SplashScreen`)**:
    *   Checks `AuthService` for an active session.
    *   If logged in -> Loads User Data (Theme, Playlists) -> Go to **Home**.
    *   If not logged in -> Go to **Login/Signup**.

2.  **Playing a Song**:
    *   User taps a song in `SearchScreen`.
    *   `MusicService` stops the current track.
    *   It adds the new song to the queue & `Listening History`.
    *   Calls `audioPlayer.play(url)`.
    *   Updates the "Mini Player" at the bottom of the screen.

3.  **Liking a Song**:
    *   User taps "Heart".
    *   `PlaylistService` toggles the status.
    *   Updates the local "Liked Songs" list for the *current user*.
    *   UI updates instantly via `Consumer<PlaylistService>`.

---

## 📂 Project Structure Guide

*   `lib/main.dart`: Entry point. Sets up Providers and Theme.
*   `lib/models/`: Data classes (`song_model.dart`, `user_model.dart`).
*   `lib/screens/`: UI pages (`home_screen.dart`, `player_screen.dart`, `profile_screen.dart`).
*   `lib/services/`: Logic classes (`music_service.dart`, `auth_service.dart`).
*   `lib/widgets/`: Reusable UI components (`song_tile.dart`, `mini_player.dart`).rr