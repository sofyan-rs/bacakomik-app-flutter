# BacaKomik

An Android reader for manga, manhwa and manhua from several sources. Each source is a small JavaScript extension the app installs from an extension repo, so new sites can be added without an app update. Browse and search comics, read chapters online or download them to read offline, and keep a personal library of bookmarks, categories and reading history. The library lives on the device; you can export it to a backup file or, optionally, sync it across devices through your own Google Drive.

## Download

Get the APK from the [Releases](https://github.com/sofyan-rs/bacakomik-app-flutter/releases) page; `arm64-v8a` fits almost every phone. Android 7.0 or newer. The app checks for new releases and updates itself. More on the [website](https://bacakomik.kurodev.org).

## Screenshots

| Splash | Home | Explore | Filter |
|---|---|---|---|
| <img src="screenshot/splash.png" width="200" alt="Splash screen"> | <img src="screenshot/home.png" width="200" alt="Home: continue reading, new series, latest chapters"> | <img src="screenshot/explore.png" width="200" alt="Explore: title search, type and cover grid"> | <img src="screenshot/filter.png" width="200" alt="Filter sheet: type, status, sort and genres"> |

| Detail | Reader | Bookmarks | History |
|---|---|---|---|
| <img src="screenshot/detail.png" width="200" alt="Comic details with stats, synopsis and genres"> | <img src="screenshot/reader.png" width="200" alt="Reader with chapter bar and page meter"> | <img src="screenshot/bookmark.png" width="200" alt="Bookmarks with new chapter badge and read meter"> | <img src="screenshot/history.png" width="200" alt="Reading history grouped by day"> |

| More | Download chapters | Downloads | Light theme |
|---|---|---|---|
| <img src="screenshot/more.png" width="200" alt="Stats, downloads, backup, Google Drive sync and theme"> | <img src="screenshot/download-select.png" width="200" alt="Selecting chapters to download for offline reading"> | <img src="screenshot/downloads.png" width="200" alt="Downloads grouped by comic with storage used"> | <img src="screenshot/home-light.png" width="200" alt="Home in the light theme"> |

Screenshots were taken on a real device (iQOO I2218, Android 16) running v1.5.0, before sources and extensions.

## Features

- **Sources:** pick the source in the header of Home or Explore. BacaKomik and VoraToon come bundled; more (MangaDex, MangaFire, ReiManga, WestManga, Comix) install from More → Extensions. Multi-language sources such as MangaDex become one source per enabled language (for example MangaDex (EN) and MangaDex (ID)), each with its own bookmarks and history. Installed extensions show an update badge when the repo has a newer version.
- **Home:** continue reading with chapter progress, new series and the latest chapters of the current source. Pull to refresh for a small easter egg.
- **Explore:** title search combined with the source's own filters (type, status, sort, genres…), with infinite scroll.
- **Comic details:** source and language, rating, chapter count, release year, synopsis and genres. The chapter list can be searched and sorted, marks new, read, partly read (`5 / 24`) and downloaded chapters, and supports selecting chapters to download them or mark them read or unread. Share a comic as a link that opens the app, save its cover, or long-press the title to copy it. Without a connection, comics you downloaded, bookmarked or read still open from the details saved on the phone.
- **Cloudflare checks:** when a site asks for a bot check, open it in the built-in WebView, pass it, and the app reuses its cookies. The WebView menu can refresh, share the link, open it in the browser and clear cookies. Sites that only answer a real browser are read through a hidden WebView, without any action.
- **Reader:** vertical strip or page by page (right-to-left or left-to-right), fit to width or height, keep the screen on, optional gap between pages. Double-tap to zoom, page meter, previous/next chapter, and a "chapter finished" card. Reopens a chapter at the page you stopped at. Auto-scroll with adjustable speed in the vertical reader. Downloaded chapters open from the phone. Long press a page to save it.
- **Bookmarks:** language badge and unread-chapter badge on each card, read progress and search by title. Group them by status, source or your own categories (a comic can be in several); pick a category when you bookmark, or skip. Refreshing checks the open group for new chapters, with a progress notification.
- **History:** last read chapter per comic, grouped by day; swipe to delete.
- **Downloads:** download chapters for offline reading. Downloads keep going in the background and while the phone is locked, with a progress notification. More → Downloads shows the storage used, the queue with retry and cancel, and downloads grouped per comic. Files stay in the app's own storage and are removed when the app is uninstalled.
- **Sync:** turn on Google Drive sync in More to sync bookmarks, categories and reading history across devices. The library is kept as one file in the app's hidden Drive folder (`drive.appdata`), so the app cannot see your other Drive files. Nothing goes through our servers.
- **Data:** back up and restore the library to a file, clear the image cache (downloads are kept), and choose the system, light or dark theme.

## Extensions

The app reads extensions from this repo by default:

```
https://bacakomik-ext.kurodev.org/index.json
```

Add more repos in More → Extensions → Extension repos. Extensions run code and access the internet, so only add repos you trust. Some extensions are reimplemented from the Tachiyomi / Mihon extensions in [keiyoushi/extensions-source](https://github.com/keiyoushi/extensions-source) (Apache License 2.0); each one credits its source in its file.

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

Release signing and testing extensions locally are described in [Contributing](docs/CONTRIBUTION.md).

## Docs

- [Architecture](docs/ARCHITECTURE.md): structure, layers, sources and extensions, storage, Dotline UI rules
- [Contributing](docs/CONTRIBUTION.md): setup, build, conventions, testing, PR checklist
- [Link hosting](hosting/README.md): Cloudflare Worker for shared links, the website and the privacy policy

Found a bug or have an idea? [Open an issue](https://github.com/sofyan-rs/bacakomik-app-flutter/issues/new).
