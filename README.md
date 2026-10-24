# BacaKomik

An Android reader for manga, manhwa and manhua, backed by [bacakomik-api](https://api-bacakomik.kurodev.org/docs). Browse and search comics, read chapters online or download them to read offline, and keep a personal library of bookmarks and reading history. The library lives on the device; you can export it to a backup file or, optionally, sync it across devices through your own Google Drive.

Built with **Flutter** (feature-first clean architecture, BLoC), styled with the **Dotline** design system: monochrome, dark first, one red signal colour, dot-matrix display type.

## Download

Get the APK from the [Releases](https://github.com/sofyan-rs/bacakomik-app-flutter/releases) page; `arm64-v8a` fits almost every phone. Android 7.0 or newer. The app checks for new releases and updates itself. More on the [website](https://bacakomik.kurodev.org).

## Screenshots

| Splash | Beranda | Jelajah | Filter |
|---|---|---|---|
| <img src="screenshot/splash.png" width="200" alt="Splash screen"> | <img src="screenshot/home.png" width="200" alt="Home: continue reading, new series, latest chapters"> | <img src="screenshot/explore.png" width="200" alt="Jelajah: title search, type and cover grid"> | <img src="screenshot/filter.png" width="200" alt="Filter sheet: type, status, sort and genres"> |

| Detail | Pembaca | Bookmark | Riwayat |
|---|---|---|---|
| <img src="screenshot/detail.png" width="200" alt="Comic details with stats, synopsis and genres"> | <img src="screenshot/reader.png" width="200" alt="Reader with chapter bar and page meter"> | <img src="screenshot/bookmark.png" width="200" alt="Bookmarks with new chapter badge and read meter"> | <img src="screenshot/history.png" width="200" alt="Reading history grouped by day"> |

| Lainnya | Unduh chapter | Unduhan | Light theme |
|---|---|---|---|
| <img src="screenshot/more.png" width="200" alt="Stats, downloads, backup, Google Drive sync and theme"> | <img src="screenshot/download-select.png" width="200" alt="Selecting chapters to download for offline reading"> | <img src="screenshot/downloads.png" width="200" alt="Downloads grouped by comic with storage used"> | <img src="screenshot/home-light.png" width="200" alt="Home in the light theme"> |

Screenshots were taken on a real device (iQOO I2218, Android 16) running v1.5.0.

## Features

- **Beranda:** continue reading with chapter progress, ranked hot comics and the latest chapters. Pull to refresh for a small easter egg.
- **Jelajah:** title search combined with type, status, sort (latest, new series, bookmarks, popular, rating, A–Z) and genre filters in one request, with infinite scroll.
- **Comic details:** rating, chapter count, release year, synopsis and genres; tap a genre to browse it in Jelajah. The chapter list can be searched and sorted, marks new, read, partly read (`5 / 24`) and downloaded chapters, and supports selecting chapters to download them or mark them read or unread. Share a comic as a link that opens the app, save its cover, or long-press the title to copy it. Without a connection, comics you downloaded, bookmarked or read still open from the details saved on the phone.
- **Reader:** vertical strip or page by page (right-to-left or left-to-right), fit to width or height, keep the screen on, optional gap between pages. Double-tap to zoom, page meter, previous/next chapter, and a "chapter finished" card. Reopens a chapter at the page you stopped at. Auto-scroll with adjustable speed in the vertical reader. Pages load in order, five at a time; downloaded chapters open from the phone. Long press a page to save it.
- **Bookmark:** unread-chapter badge (`+N`, also on comics not started yet), read progress, filters for all / has update / finished, and search by title.
- **Riwayat:** last read chapter per comic, grouped by day; swipe to delete.
- **Unduhan:** download chapters for offline reading. Downloads keep going in the background and while the phone is locked, with a progress notification. Lainnya → Unduhan shows the storage used, the queue with retry and cancel, and downloads grouped per comic (swipe a chapter to delete it). Files stay in the app's own storage and are removed when the app is uninstalled.
- **Sinkron:** sign in with Google in Lainnya → Sinkron to sync bookmarks and reading history across devices. The library is kept as one file in the app's hidden Drive folder (`drive.appdata`), so the app cannot see your other Drive files. Sync runs when the app opens, when you return to it and a few seconds after each change, or on demand; removing a bookmark or chapter on one device removes it on the others. Nothing goes through our servers.
- **Data:** back up and restore bookmarks and history to a file, clear the image cache (downloads are kept), and choose the system, light or dark theme.

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
- [Link hosting](hosting/README.md): Cloudflare Worker for shared links, the website and the privacy policy

Found a bug or have an idea? [Open an issue](https://github.com/sofyan-rs/bacakomik-app-flutter/issues/new).
