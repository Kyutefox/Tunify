<div align="center">

<img src="assets/app-icon.svg" alt="Tunify Logo" width="120" height="120" />

# Tunify

**A beautiful, open-source YouTube Music client built with Flutter.**

Stream any song. Manage your library. Play offline. All in one app.

<br/>

[![Flutter](https://img.shields.io/badge/Flutter-3.6%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.6%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-brightgreen)](#platform-support)
[![License](https://img.shields.io/badge/License-MIT-purple)](LICENSE)
[![Organization](https://img.shields.io/badge/Org-Kyutefox-ff69b4)](https://github.com/Kyutefox)

<br/>

</div>

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Supabase Setup](#supabase-setup)
- [Building](#building)
- [Internal Packages](#internal-packages)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

Tunify is a **free, open-source music streaming app** powered by YouTube Music. It gives you a clean, Spotify-inspired interface to search, stream, download, and organize your music — without a subscription.

Built with Flutter for a seamless experience on both Android and iOS, Tunify uses a local-first architecture: all your library data lives on-device in SQLite and optionally syncs to the cloud via Supabase when you're signed in.

> **Note:** Tunify is an independent third-party client. It is not affiliated with, endorsed by, or connected to YouTube, Google, or Alphabet Inc.

---

## Features

### Streaming & Playback
- Stream any track from YouTube Music's full catalog
- Adaptive audio quality — Low / Medium / High / Auto
- Background playback with lock-screen media controls and notifications
- Seek, skip, repeat, and shuffle with a full-featured queue
- Volume normalization (LUFS-based) for consistent loudness across tracks
- Sleep timer that fades out and stops playback automatically

### Search & Discovery
- Full-text search across the entire YouTube Music catalog
- Search suggestions as you type
- Recent search history (locally stored, instantly accessible)
- Browse featured content, mood playlists, and curated collections

### Library Management
- **Liked Songs** — like any track with a single tap
- **Playlists** — create, edit, reorder, pin, and delete unlimited playlists
- **Folders** — group playlists into folders for clean organization
- **Downloaded Music** — manage all offline tracks in one place
- **Device Music** — access and play songs from your phone's local storage
- **Recently Played** — your listening history, always within reach
- Drag-and-drop track reordering inside playlists

### Offline Downloads
- Download any track for offline playback
- Visual download queue with real-time progress
- Downloaded tracks are automatically prioritized over streaming

### Lyrics
- In-player lyrics view with synced line highlighting

### Personalization & Settings
- Explicit content filter — hide explicit tracks globally
- Smart recommendation shuffle for a varied home feed
- Per-playlist shuffle toggle
- Custom Supabase backend support (self-host your own sync)

### Account & Sync
- Sign in with email/password via Supabase Auth
- Guest mode — full local experience with no account required
- Cross-device library sync for signed-in users
- On-login hydration — library syncs from cloud before the app opens

### Other
- Device casting via Chromecast / DLNA discovery
- Offline banner when no network is detected
- Smooth skeleton loading states throughout
- Dark theme with dynamic accent colors extracted from album art

---

## Screenshots

<div align="center">

<img src="https://cdn.kyutefox.com/Tunify/screenshots/MainScreen.jpg" alt="Main Screen" width="22%"> <img src="https://cdn.kyutefox.com/Tunify/screenshots/HomeScreen.jpg" alt="Home Screen" width="22%"> <img src="https://cdn.kyutefox.com/Tunify/screenshots/SearchScreen.jpg" alt="Search Screen" width="22%"> <img src="https://cdn.kyutefox.com/Tunify/screenshots/PlayerScreen.jpg" alt="Player Screen" width="22%">

<img src="https://cdn.kyutefox.com/Tunify/screenshots/LyricsScreen.jpg" alt="Lyrics Screen" width="22%"> <img src="https://cdn.kyutefox.com/Tunify/screenshots/LibraryScreen.jpg" alt="Library Screen" width="22%"> <img src="https://cdn.kyutefox.com/Tunify/screenshots/DownloadScreen.jpg" alt="Download Screen" width="22%">

</div>

---

## Tech Stack

| Category | Libraries |
|----------|-----------|
| **Framework** | Flutter 3.6+, Dart 3.6+ |
| **State Management** | [flutter_riverpod](https://riverpod.dev) 3.x |
| **Audio Engine** | [just_audio](https://pub.dev/packages/just_audio), [audio_service](https://pub.dev/packages/audio_service), [audio_session](https://pub.dev/packages/audio_session) |
| **YouTube** | Custom `scrapper` package (InnerTube), [youtube_explode_dart](https://pub.dev/packages/youtube_explode_dart) |
| **Backend** | [Supabase](https://supabase.com) (Auth + PostgreSQL) |
| **Local Database** | [sqflite](https://pub.dev/packages/sqflite) via custom `tunify_database` package |
| **Preferences** | [shared_preferences](https://pub.dev/packages/shared_preferences) |
| **Networking** | [http](https://pub.dev/packages/http), [connectivity_plus](https://pub.dev/packages/connectivity_plus) |
| **Images** | [cached_network_image](https://pub.dev/packages/cached_network_image), [palette_generator](https://pub.dev/packages/palette_generator) |
| **UI** | [google_fonts](https://pub.dev/packages/google_fonts), [flutter_animate](https://pub.dev/packages/flutter_animate), [shimmer](https://pub.dev/packages/shimmer), [flutter_svg](https://pub.dev/packages/flutter_svg), [hugeicons](https://pub.dev/packages/hugeicons) |
| **Code Generation** | [freezed](https://pub.dev/packages/freezed), [build_runner](https://pub.dev/packages/build_runner) |
| **Casting** | [chromecast_dlna_finder](https://pub.dev/packages/chromecast_dlna_finder) |
| **Device Music** | [on_audio_query_pluse](https://pub.dev/packages/on_audio_query_pluse) |

---

## Architecture

Tunify follows a **layered, local-first architecture** with a clear separation between data, business logic, and UI.

```
lib/
├── config/             # App-wide constants, keys, palette, Supabase config
├── models/             # Immutable data models (Freezed-generated)
├── shared/
│   ├── providers/      # Riverpod state layer — all app state lives here
│   └── services/       # Business logic: streaming, downloads, playback tracking
├── system/
│   ├── bridges/        # Repository layer bridging services ↔ database
│   └── databases/      # SQLite bridge + Supabase preferences
└── ui/
    ├── components/     # Reusable widgets and UI building blocks
    ├── screens/        # Full page screens (home, search, player, library, …)
    └── theme/          # Colors, typography, and theme configuration

pkg/
├── scrapper/           # YouTube InnerTube client (custom)
├── tunify_database/    # SQLite bridge and sync manager
└── logger/             # Structured logging wrapper
```

### Key Design Decisions

**Local-first data.** SQLite is the single source of truth. All reads and writes go through `DatabaseRepository`. Supabase sync is handled by a background `SyncManager` that runs after every write — the UI never waits for the network.

**Streaming with LRU cache.** `MusicStreamManager` wraps the YouTube InnerTube API and caches stream URLs in an in-memory LRU map (50 entries, 5.5 h TTL). On cache miss, the URL is fetched live and cached for subsequent plays.

**Audio pipeline.** `AudioPlayerService` wraps `just_audio`. `AudioRepository` resolves each song to its best available source in priority order: local file → stream cache file → live stream URL. Stream audio is downloaded to disk in the background (Spotify-style) so the next play is instant.

**Riverpod everywhere.** All state — player, library, home feed, downloads, auth — is managed through Riverpod providers. UI widgets use `ConsumerWidget` and `ref.watch` for reactive rebuilds.

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **^3.6.0**
- [Dart SDK](https://dart.dev/get-dart) **^3.6.0** (bundled with Flutter)
- [Android Studio](https://developer.android.com/studio) or [Xcode](https://developer.apple.com/xcode/) for device targets
- A [Supabase](https://supabase.com) project (free tier is sufficient)

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/Kyutefox/tunify.git
cd tunify

# 2. Install dependencies
flutter pub get

# 3. Generate Freezed models
dart run build_runner build --delete-conflicting-outputs
```

### Supabase Setup

Tunify requires a Supabase project for account sync. Guest mode works without it.

**1. Create a Supabase project** at [supabase.com](https://supabase.com).

**2. Run the migrations** in order from the `migrations/` directory using the Supabase SQL editor:

```
migrations/supabase_schema.sql           # Core schema
migrations/add_followed_artists_albums.sql  # Artist & album following
```

**3. Configure the app.** Open `lib/config/supabase_config.dart` and set your project credentials:

```dart
class SupabaseConfig {
  static const String url = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String anonKey = 'YOUR_ANON_KEY';
}
```

> Your Supabase URL and anon key are available in **Project Settings → API** inside the Supabase dashboard.

---

## Building

```bash
# Run in debug mode
flutter run

# Android — APK (sideload)
flutter build apk --release

# Android — App Bundle (Play Store)
flutter build appbundle --release

# iOS (requires Xcode and an Apple Developer account)
flutter build ipa --release
```

---

## Internal Packages

Tunify ships three private packages under `pkg/`:

| Package | Description |
|---------|-------------|
| `pkg/scrapper` | YouTube InnerTube client. Handles search, player, next-queue, home feed, lyrics, and stream URL extraction with visitor-data personalization. |
| `pkg/tunify_database` | SQLite bridge and background `SyncManager`. Exposes a typed `DatabaseBridge` API for all persistence operations and handles Supabase → SQLite hydration on login. |
| `pkg/logger` | Thin structured logging wrapper over the `logger` package, with per-tag filtering and consistent severity levels (`log`, `logWarning`, `logError`). |

---

## Contributing

Contributions are welcome and appreciated. Here's how to get started:

1. **Fork** the repository and create a feature branch:
   ```bash
   git checkout -b feat/your-feature-name
   ```

2. **Make your changes.** Keep PRs focused — one feature or fix per PR.

3. **Run the analyzer** before opening a PR:
   ```bash
   flutter analyze
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Open a Pull Request** against `main` with a clear description of what changed and why.

### Guidelines

- Follow existing code style (Dart analysis options are enforced via `flutter_lints`).
- Prefer editing existing files over creating new ones.
- Write self-documenting code; add comments only where the logic is non-obvious.
- Do not commit secrets, API keys, or personal Supabase credentials.

---

## License

Tunify is released under the [MIT License](LICENSE).

```
MIT License

Copyright (c) 2025 Kyutefox

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```

---

<div align="center">

Made with love by [Kyutefox](https://github.com/Kyutefox)

</div>
