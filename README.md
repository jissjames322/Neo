<div align="center">

<img src="https://img.shields.io/badge/NEO-YouTube%20Music%20Player-9D4EDD?style=for-the-badge&logo=youtube&logoColor=white" alt="NEO"/>

# NEO — YouTube Music Player

**Stream any song from YouTube, ad-free, no API key, no sign-in.**  
Built with Flutter · Powered by [yt-dlp](https://github.com/yt-dlp/yt-dlp) · Windows desktop app

[![Build & Release](https://github.com/jissjames322/Neo/actions/workflows/windows_release.yml/badge.svg)](https://github.com/jissjames322/Neo/actions/workflows/windows_release.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Platform](https://img.shields.io/badge/Platform-Windows-0078D6?logo=windows)
![License](https://img.shields.io/badge/License-MIT-green)
![yt-dlp](https://img.shields.io/badge/Powered%20by-yt--dlp-FF0000?logo=youtube&logoColor=white)

</div>

---

## ✨ Features

| Feature | Details |
|---------|---------|
| 🎵 **YouTube Search & Stream** | Search any song by name — results from YouTube, streamed instantly |
| 🚫 **Ad-Free** | yt-dlp extracts the raw audio CDN URL — ads never reach the player |
| ⚡ **Streaming (not downloading)** | Audio plays immediately without saving a file |
| ⬇️ **Optional Download** | Download any track as MP3 to your Downloads folder |
| 📚 **Local Library** | SQLite-backed library for your favorite and recently played tracks |
| 🎨 **Premium Dark UI** | Glassmorphism, Google Fonts (Outfit), animated waveforms, glow effects |
| 🔄 **Auto yt-dlp Setup** | Downloads the yt-dlp binary automatically on first launch — no setup needed |
| 🛡️ **Privacy First** | No login, no tracking, no hardcoded API keys, no third-party proxies |

---

## 🖥️ Screenshots

> _Search YouTube, tap a song, and it streams immediately._

| Home — Search | Now Playing | Library |
|---|---|---|
| YouTube search with live results | Rotating album art + lyrics | SQLite local library |

---

## 🚀 Getting Started

### Download (Windows)

1. Go to [**Releases**](https://github.com/jissjames322/Neo/releases)
2. Download `neo-windows-release.zip`
3. Extract and run `neo.exe`
4. On first launch, NEO automatically downloads `yt-dlp.exe` into its app data folder
5. Search for a song and enjoy!

> **No Python, no pip, no manual yt-dlp install required.**

---

## 🏗️ Architecture

```
Flutter App
│
├── UI Layer
│   ├── HomeScreen      — YouTube search + local library
│   ├── PlayerScreen    — Full-screen player with lyrics, queue, analysis
│   ├── LibraryScreen   — SQLite-backed local library
│   └── SettingsScreen  — Theme, EQ, playback options
│
├── State (Riverpod)
│   ├── audioProvider   — Playback state (just_audio)
│   └── themeProvider   — Theme switching
│
└── Services
    ├── YtDlpService    — yt-dlp subprocess backend (search + stream + download)
    ├── ApiService      — Facade over YtDlpService
    ├── DbHelper        — SQLite via sqflite_common_ffi
    └── SettingsService — SharedPreferences
```

### How yt-dlp powers NEO

```
User types "Blinding Lights"
        │
        ▼
YtDlpService.searchSongs()
  └─► yt-dlp "ytsearch10:Blinding Lights" --dump-json
        │
        ▼
List of Song objects with title, artist, duration, thumbnail
        │
User taps a song
        │
        ▼
YtDlpService.getStreamUrl(videoId)
  └─► yt-dlp -f "bestaudio[ext=m4a]/bestaudio" --get-url VIDEO_URL
        │
        ▼
Direct HTTPS CDN URL (no ads, no tracking)
        │
        ▼
just_audio streams the URL → music plays!
```

---

## 🔒 Security

NEO was built with security as a first-class concern:

| # | Issue | Fix |
|---|-------|-----|
| ✅ | No hardcoded API keys | yt-dlp requires no keys |
| ✅ | No third-party proxy servers | Audio served directly from YouTube CDN |
| ✅ | Shell injection prevention | All subprocess calls use argument lists (`runInShell: false`) |
| ✅ | Video ID validation | Strict regex `^[a-zA-Z0-9_-]{11}$` before any subprocess call |
| ✅ | HTTPS enforcement | Stream URLs rejected if they don't start with `https://` |
| ✅ | No login or tracking | Fully local, no network calls except to YouTube CDN |

---

## 🛠️ Building from Source

### Prerequisites
- [Flutter SDK](https://flutter.dev) (stable channel, 3.x+)
- Windows 10/11 with Visual Studio 2022 (Desktop development with C++ workload)

### Steps

```powershell
git clone https://github.com/jissjames322/Neo.git
cd Neo
flutter pub get
flutter run -d windows
```

To build a release binary:
```powershell
flutter build windows --release
# Output: build\windows\x64\runner\Release\neo.exe
```

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `just_audio` + `just_audio_media_kit` | Audio playback engine |
| `flutter_riverpod` | State management |
| `go_router` | Navigation |
| `sqflite_common_ffi` | SQLite local database |
| `google_fonts` | Outfit typeface |
| `cached_network_image` | YouTube thumbnail caching |
| `http` | yt-dlp binary auto-download |
| `shared_preferences` | Settings persistence |

---

## 🙏 Credits & Attribution

### yt-dlp

This project is made possible by the incredible **[yt-dlp](https://github.com/yt-dlp/yt-dlp)** project.

> **yt-dlp** is a feature-rich command-line audio/video downloader with support for thousands of sites. It is a fork of youtube-dl with additional features and fixes.
>
> — [github.com/yt-dlp/yt-dlp](https://github.com/yt-dlp/yt-dlp)

NEO uses yt-dlp as a local subprocess to:
- Search YouTube without an API key
- Extract direct audio stream URLs (ad-free)
- Download tracks as MP3

A huge thank you to all **yt-dlp contributors** for maintaining such a robust and well-documented tool. Please consider starring their repository: ⭐ [yt-dlp/yt-dlp](https://github.com/yt-dlp/yt-dlp)

---

### Other Open Source Projects

- [Flutter](https://flutter.dev) — UI framework by Google
- [just_audio](https://pub.dev/packages/just_audio) — Audio playback by Ryan Heise
- [Riverpod](https://riverpod.dev) — State management by Remi Rousselet
- [google_fonts](https://pub.dev/packages/google_fonts) — Google Fonts for Flutter

---

## ⚠️ Disclaimer

NEO is intended for personal, non-commercial use. Streaming from YouTube is subject to [YouTube's Terms of Service](https://www.youtube.com/t/terms). This tool does not circumvent DRM or distribute copyrighted content — it only accesses freely available public streams in the same way a browser would.

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

<div align="center">

Made with ❤️ and Flutter · Powered by yt-dlp

**[⬇️ Download Latest Release](https://github.com/jissjames322/Neo/releases/latest)**

</div>