# Neo Music Player 🎵

> **Your Music. Your Space.**
> A modern, premium, privacy-focused music player built with Flutter.

---

Neo is a distraction-free, privacy-first audio streaming and local playback application. Designed with modern dark futuristic aesthetics, glassmorphic UI components, and smooth transitions, Neo allows users to search, stream, and organize music without requiring user accounts, sign-ins, or subscriptions.

---

## 🛡️ Core Philosophy

* **Privacy First**: Zero user trackers, cookies, or telemetry.
* **No Accounts**: No mandatory login or sign-in walls.
* **Ad-Free Streaming**: Native ad-blocking by streaming direct, clean audio feeds.
* **Lightweight & High-Performance**: Minimal resource footprint with smooth 60 FPS animations.

---

## ✨ Features

### 🎧 Dynamic YouTube Audio Streaming
- Search songs, artists, or albums directly on YouTube.
- Stream high-quality audio manifest segments directly inside a native playlist queue without loading heavy web players.
- Fully supports playback controls, lock-screen notifications, volume, speed, seeking, and queue next/previous.

### 🛡️ Neo Privacy Shield & Dashboard
- **Active Tracker Blocking**: Intercepts and blocks tracking beacons, QoS watchdogs, and third-party advertising scripts (e.g. `doubleclick.net`, `google-analytics.com`).
- **Neo Shield Dashboard**: Visualizes blocked analytics requests and Megabytes of saved bandwidth in real time using a clean glassmorphic panel.
- **Privacy Scoring**: View your privacy status (A+ rating) and monitor live diagnostic log streams.

### 📊 Audio Analysis Panel
- Displays metadata features including **Danceability, Energy, Valence, Acousticness, Tempo (BPM), and Loudness (dB)**.
- **Deterministic Offline Fallback**: If a song doesn't have online metrics, Neo calculates realistic features based on song metadata to keep the visualizer functional and beautiful.

### 📂 Local & Offline Library
- Scan and import local MP3 music directories.
- Track play history, most-played listings, favorites, and custom playlists.
- Database synced locally using SQLite.

---

## 🛠️ Tech Stack

* **Framework**: [Flutter](https://flutter.dev/) (Windows Desktop, Android, iOS, macOS, Web)
* **State Management**: [Riverpod (v3)](https://riverpod.dev/)
* **Audio Engine**: [Just Audio](https://pub.dev/packages/just_audio)
* **YouTube Engine**: Native Verome-API port (replaced youtube_explode_dart)
* **Database**: [SQLite](https://pub.dev/packages/sqflite)
* **Routing**: [GoRouter](https://pub.dev/packages/go_router)
* **Storage**: [SharedPreferences](https://pub.dev/packages/shared_preferences)

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the Flutter SDK installed on your system.

```bash
flutter --version
```

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/jissjames322/Neo.git
   cd Neo
   ```

2. Retrieve dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application (Windows Desktop target):
   ```bash
   flutter run -d windows
   ```

4. Compile a release build:
   ```bash
   flutter build windows
   ```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## 📄 License

This project is open-source. See the repository license for details.

---

*Developed with ❤️ by Jiss James & Neo Music Player Contributors.*