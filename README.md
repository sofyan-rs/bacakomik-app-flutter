# BacaKomik

An Android reader for manga, manhwa and manhua, backed by [bacakomik-api](https://api-bacakomik.kurodev.org/docs). Browse and search comics, read chapters, and keep a personal library of bookmarks and reading history. There is no account: the library lives on the device and in backup files you export.

Built with **Flutter** (feature-first clean architecture, BLoC), styled with the **Dotline** design system: monochrome, dark first, one red signal colour, dot-matrix display type.

## Download

No release is published yet. Releases will appear on the [Releases](https://github.com/sofyan-rs/bacakomik-app-flutter/releases) page; until then, [build from source](#build). Android 7.0 or newer.

## Screenshots

| Beranda | Jelajah | Filter | Detail |
|---|---|---|---|
| <img src="screenshot/home.png" width="200" alt="Home: continue reading, hot comics, latest chapters"> | <img src="screenshot/explore.png" width="200" alt="Jelajah: title search, type and cover grid"> | <img src="screenshot/filter.png" width="200" alt="Filter sheet: type, status, sort and genres"> | <img src="screenshot/detail.png" width="200" alt="Comic details with stats, synopsis and genres"> |

| Pembaca | Bookmark | Riwayat | Lainnya |
|---|---|---|---|
| <img src="screenshot/reader.png" width="200" alt="Reader with chapter bar and page meter"> | <img src="screenshot/bookmark.png" width="200" alt="Bookmarks with new chapter badge and read meter"> | <img src="screenshot/history.png" width="200" alt="Reading history grouped by day"> | <img src="screenshot/more.png" width="200" alt="Stats, backup, cache and theme"> |

| Splash | Light theme |
|---|---|
| <img src="screenshot/splash.png" width="200" alt="Splash screen"> | <img src="screenshot/home-light.png" width="200" alt="Home in the light theme"> |

Screenshots were taken on a real device (Realme RMX5085, Android 16).

## Features

- **Beranda:** continue reading with chapter progress, ranked hot comics and the latest chapters. Pull to refresh for a small easter egg.
- **Jelajah:** title search combined with type, status, sort (latest, new series, bookmarks, popular, rating, A–Z) and genre filters in one request, with infinite scroll.
- **Comic details:** rating, chapter count, release year, synopsis and genres. The chapter list can be searched and sorted, marks new and read chapters, and supports selecting chapters to mark them read or unread. Share a comic or save its cover.
- **Reader:** vertical strip or page by page (right-to-left or left-to-right), fit to width or height, keep the screen on, optional gap between pages. Double-tap to zoom, page meter, previous/next chapter, and a "chapter finished" card. Pages load in order, five at a time. Long press a page to save it.
- **Bookmark:** new-chapter badge (`+N`), read progress, filters for all / has update / finished, and search by title.
- **Riwayat:** last read chapter per comic, grouped by day; swipe to delete.
- **Data:** back up and restore bookmarks and history to a file, clear the image cache, and choose the system, light or dark theme. Library data from older app versions is migrated on first launch.

## Requirements

- Android 7.0+ (API 24)
- To build: Flutter (stable, Dart 3.13), JDK 17, Android SDK 37

## Build

```bash
flutter pub get
dart run build_runner build -d   # regenerate freezed / json / injectable / assets code
flutter run                      # debug build on a connected device
flutter analyze
flutter test
```

Point the app at another API server with `--dart-define=API_BASE_URL=<url>`. Release signing is described in [Contributing](docs/CONTRIBUTION.md).

## Docs

- [Architecture](docs/ARCHITECTURE.md): structure, layers, storage and compatibility rules, Dotline UI rules
- [Contributing](docs/CONTRIBUTION.md): setup, build, conventions, testing, PR checklist

Found a bug or have an idea? [Open an issue](https://github.com/sofyan-rs/bacakomik-app-flutter/issues/new).
