# Architecture

BacaKomik is a Flutter app for reading comics (manga, manhwa, manhua) from **bacakomik-api**. It is built with **feature-first clean architecture** and **BLoC**.

Scope: **browse comics, read chapters, and keep a personal library** (bookmarks, reading history, settings, backup files). There are no accounts and no cloud sync. Library data lives only on the device and in backup files the user exports.

This file covers how the app is built. Section numbers (§) refer to this file.

---

## 1. Goals and non-goals

### Goals
- **Never lose the user's library.** Bookmarks, history and settings survive updates, and backup files (§7.4) restore them. Storage starts fresh from this version: data from the pre-2026 app is not migrated, and its backup files are not read.
- **Keep logic testable.** Domain code is plain Dart with no Flutter, Dio, Hive or file-picker imports. Repositories and blocs are tested without a device.
- **Keep layers clear.** UI talks to blocs, blocs call use cases, use cases call repository interfaces. Only the data layer knows about HTTP and storage.
- Work on phones and wide screens. A floating pill nav sits at the bottom on every width; cover grids add columns as the screen gets wider.

### Non-goals
- User accounts, cloud sync, or a server-side library.
- iOS background downloads are untested (releases are Android APKs). Download tasks use absolute paths, which iOS can move between launches (§7.5).
- Hosting or scraping comics. All content comes from bacakomik-api.
- An app store listing. Releases are APKs on GitHub Releases; the app checks the latest release on start and from Lainnya, downloads the APK for the device's ABI and opens Android's installer (`features/update`, `ota_update`). Asset names and the `## Which APK?` heading are set by the release workflow (CONTRIBUTION §2).

---

## 2. Tech stack

| Concern | Choice | Notes |
|---|---|---|
| Language / UI | Dart 3.13, Flutter (stable) | Material 3 widgets themed with the Dotline design system (§5). Bundled Geist, Geist Mono and Doto fonts, Lucide icons via `lucide_icons_flutter`. |
| State | `flutter_bloc` (Bloc and Cubit) | States are freezed sealed unions (§4.3). |
| Dependency wiring | `get_it` + `injectable` | Generated in `lib/core/di/injection.config.dart` (§10). |
| Errors | `fpdart` `Either<Failure, T>` | Repositories never throw to callers (§9). |
| Models | `freezed` + `json_serializable` | Entities, states and API DTOs use freezed; stored models use `@JsonSerializable` (§7.2). |
| HTTP | `dio` behind `ApiClient` | Base URL from `--dart-define=API_BASE_URL`, default `https://api-bacakomik.kurodev.org`. |
| Connectivity | `connectivity_plus` behind `NetworkInfo` | Checked before every remote call (§8.2). |
| Local storage | `hive_ce` | Boxes of JSON strings, no type adapters (§7). |
| Images | `cached_network_image`, `flutter_cache_manager` | "Clear cache" in settings empties the image cache. |
| Backup files | `file_picker` + `dart:io` | Behind `BackupFileDataSource` (§7.4). |
| Saving pages | `gal` | Saves a reader image to the gallery. |
| Tests | `flutter_test`, `bloc_test`, `mocktail` | Hive tests use a temp directory (CONTRIBUTION §5). |

Exact versions live in `pubspec.yaml` and `pubspec.lock`. Read §10.1 before you change `freezed` or the generators.

**Application id:** `org.kurodev.bacakomik`.

**SDK levels:** `minSdk` and `targetSdk` come from Flutter (currently 24 and 36), `compileSdk 37`, Java 17.

---

## 3. Project structure

```
lib/
├── main.dart                       # Hive.init → DI → runApp
├── app/
│   ├── app.dart                    # BacaKomikApp: app-wide BlocProviders, MaterialApp, theme mode
│   ├── splash_screen.dart
│   ├── root_screen.dart            # tabs: Home, Explore, Bookmark, History, More (floating nav)
├── core/
│   ├── assets/assets.gen.dart      # flutter_gen output
│   ├── constants/                  # texts (UI strings), filters, variables
│   ├── theme/                      # Dotline tokens: colors, text styles, spacing, ThemeData
│   ├── di/                         # injection.dart, register_module.dart (Dio, Connectivity, Hive)
│   ├── error/                      # exceptions.dart (data layer), failures.dart (domain)
│   ├── network/                    # ApiClient, NetworkInfo, runRemote()
│   ├── storage/                    # HiveBoxes + StorageModule, JsonBox<T>, runLocal()
│   ├── usecase/usecase.dart        # UseCase<T, Params>, NoParams
│   ├── domain/entities/            # Comic, ComicDetails, Genre, Chapter (shared by features)
│   ├── data/
│   │   ├── datasources/series_remote_data_source.dart  # every bacakomik-api endpoint
│   │   └── models/                 # SeriesResponse… (API DTOs), ComicDetailsModel (stored)
│   ├── presentation/
│   │   ├── bloc/comic_list_state.dart  # paginated list state + ComicListLoader mixin
│   │   └── widgets/                # comic card + grid, dotline/ (Dotline component library)
│   └── utils/                      # ApiFormat, Clock, snackbar/save-image helpers
└── features/
    ├── home/          # trending + latest on the home tab
    ├── latest/        # "see all" latest chapters, paginated
    ├── explore/       # filter by sort/type/status/genre, paginated
    ├── comic_detail/  # comic info + chapter list
    ├── reader/        # chapter images, prev/next
    ├── bookmark/      # local: bookmarked comics, "check for new chapters"
    ├── history/       # local: read chapters
    ├── settings/      # local: theme; the More tab
    ├── backup/        # export/import the library as a JSON file
    ├── download/      # local: chapters saved for offline reading, background download queue
    └── update/        # in-app updates from GitHub Releases
```

Every feature uses the same layout. A layer folder exists only if the feature needs it:

```
features/<name>/
├── domain/
│   ├── entities/        # freezed, plain Dart
│   ├── repositories/    # abstract interface class
│   └── usecases/        # one call() per use case
├── data/
│   ├── datasources/     # remote or local (Hive, files)
│   ├── models/          # JSON shape on disk or on the wire
│   └── repositories/    # *RepositoryImpl, registered with @LazySingleton(as: …)
└── presentation/
    ├── bloc/            # Bloc/Cubit + freezed state
    ├── pages/           # screens pushed by Navigator
    └── widgets/         # widgets used only by this feature
```

### Dependency rules

```
presentation ──▶ domain ◀── data
```

- **domain** imports nothing from `data`, `presentation`, Flutter, Dio, Hive or file_picker. It may import `fpdart`, `freezed_annotation`, `injectable` and other features' **domain** code.
- **data** implements domain interfaces. It may import other features' data models when a format is shared (for example `backup` reads `BookmarkModel`).
- **presentation** calls use cases through blocs. Widgets may read cubits from other features (for example `comic_detail` reads `BookmarkCubit` and `HistoryCubit`).
- **core** never imports from `features/`. Code that has to know several features (the app shell, root tabs) lives in `lib/app/`.

Check the domain rule with:

```bash
grep -rn "^import" lib/core/domain lib/features/*/domain | grep -E "package:flutter|/data/|/presentation/|hive|dio|file_picker"
```

It must print nothing.

### Rules for adding code

1. **Group by feature, then by layer.** Only shared things go in `core/`.
2. **One main type per file, named after the file.** `bookmark_cubit.dart` → `BookmarkCubit`. Small groups of related use cases may share a file (`bookmark_usecases.dart`).
3. **Use cases are thin.** If a use case only forwards to the repository, keep it one line. Put real rules in the domain (`ReadHistoryQueries`, `RefreshBookmarks`) so they can be tested.
4. **Repositories return `Either`.** Wrap remote calls in `runRemote` and local calls in `runLocal` (§9).
5. **Register with injectable.** Use cases, blocs and cubits use `@injectable`. Repositories and data sources use `@LazySingleton(as: Interface)`. Then run code generation (§10).
6. **Keep files under ~400 lines.** Split by responsibility past that.

### Where does my code go?

| I'm writing… | Put it in |
|---|---|
| A rule about comics, chapters, bookmarks or history | that feature's `domain/` + a test |
| A new bacakomik-api call | `core/data/datasources/series_remote_data_source.dart` + a DTO in `core/data/models/` |
| Data stored on the device | a feature `data/datasources/*_local_data_source.dart` over a `JsonBox` (§7) |
| A screen | `features/<name>/presentation/pages/` |
| A widget used by several features | `core/presentation/widgets/` |
| A UI string | `core/constants/texts.dart` (`AppText`) |
| Something that wires several features together | `lib/app/` |

---

## 4. Runtime model

```
   main() ── Hive.init(app documents dir)
          ── configureDependencies()      # opens Hive boxes (preResolve)
          ── runApp(BacaKomikApp)

   BacaKomikApp ─ MultiBlocProvider (app scope)
   │   HomeBloc · ExploreBloc · FilterCubit · BookmarkCubit · HistoryCubit · SettingsCubit · DownloadCubit · BackupCubit
   └─ MaterialApp ─ SplashScreen ─▶ RootScreen (tabs)
                                      │ Navigator.push
                                      ▼
            route-scoped blocs: LatestBloc · ComicDetailsBloc · ReaderBloc

   Bloc/Cubit ─▶ UseCase ─▶ Repository (interface) ─▶ RepositoryImpl
                                                       ├─ SeriesRemoteDataSource ─▶ ApiClient (Dio)
                                                       └─ *LocalDataSource ─▶ JsonBox ─▶ Hive box
```

### 4.1 Startup

1. `Hive.init` points Hive at the application documents directory.
2. `configureDependencies()` registers everything and opens the six Hive boxes before returning (`@preResolve` in `StorageModule`).
3. `runApp`. `BookmarkCubit`, `HistoryCubit` and `SettingsCubit` call `load()` when they are first created.

### 4.2 Bloc scope

- **App scope** (`lib/app/app.dart`): the bottom-tab blocs (`HomeBloc`, `ExploreBloc`, `FilterCubit`) and the library (`BookmarkCubit`, `HistoryCubit`, `SettingsCubit`, `DownloadCubit`, `BackupCubit`). Several screens read them, and they have to outlive navigation.
- **Route scope:** `LatestChapterScreen`, `ComicDetailsScreen` and `ReadChapterScreen` each create their own bloc with `BlocProvider(create: (_) => getIt<…>())`. The public screen widget is a thin wrapper and the stateful view underneath is private (`_ComicDetailsView`). Opening a second comic or moving to the next chapter therefore always starts from a fresh state.

### 4.3 State shapes

- Remote screens use a freezed sealed state: `initial`, `loading`, `loaded(...)`, `error(message)`, `noInternet`. The generated classes are public (`HomeLoaded`, `ComicDetailsNoInternet`), so widgets use `state is HomeLoaded`.
- The paginated lists (latest, search, explore) share `ComicListState` and the `ComicListLoader` mixin: `loadFirstPage` and `loadNextPage`. A next-page event is ignored until the first page has loaded. While a page is loading, `ComicListLoaded.isLoadMore` is true.
- Library cubits hold plain lists (`List<Bookmark>`, `List<ReadHistory>`) or `AppSettings`. After every write they reload from the repository, so the state always matches storage.
- Events are plain `final class`es named after what happened: `HomeStarted`, `HomeRefreshed`, `ExploreRequested`, `ChapterRequested`.

### 4.4 Settings

`AppSettings` holds `themeMode` (`AppThemeMode.system | light | dark`, mapped to Flutter's `ThemeMode` in `BacaKomikApp`) and the reader settings (`readingDirection`, `pageFit`, `keepScreenOn`, `pageGap`). `SettingsModel` gives every field a default and falls back on unknown enum values, so a field added later never breaks loading.

---

## 5. Theme and UI

The UI uses **Dotline**, a monochrome, dark-first design system: pure black background in dark mode (`#F2F2F2` in light), flat surfaces with hairlines, pills and dot motifs. Rules worth keeping:

- **Red is a signal, not a colour.** `accent` appears at most once or twice per screen (NEW dot, `+N` badge, delete actions). Selected chips, switches and segments use `ink`.
- **Doto only for screen titles** (`BERANDA`, `JELAJAH`) and the app name, never below 24 px. Numbers use `DotlineText.stat` / `statS` (Geist 600). Labels and overlines use Geist Mono, uppercase.
- **No gradients or glass.** The one exception is the bottom fade behind the nav. Depth comes from `bg` → `surface` → `surfaceRaised`; `shadowFloat` is only for menus and the reader's chapter pill (the main nav has none).
- **Comic types are labels, not colours.** Manga, manhwa and manhua get the same black label pill.
- Motion: 140 ms presses (scale to 0.97, no ripple), about 320 ms sliding selection indicators. Respect `MediaQuery.disableAnimationsOf`.

- `core/theme/` holds the tokens: `DotlineColors` (a `ThemeExtension`, read with `Dotline.of(context)`), `DotlineText`, `DotSpace` / `DotRadius` / `DotSize` / `DotMotion`, and `dotlineTheme()` for light and dark.
- Build screens from `core/presentation/widgets/dotline/` (`ScreenHeader`, `ListGroup` + `ListRow`, `SegmentedControl`, `DotButton`, `DotChip`, `DotSwitch`, `showDotSheet`, `DotMeter`, `ComicCover`, `EmptyState`…) instead of raw Material widgets. There is no ripple; taps scale through `Pressable`.
- Icons are Lucide from `lucide_icons_flutter`, weight 300 only (`LucideIcons300`, stroke ≈ 1.5). Do not use Material `Icons`.
- All user-facing text is Indonesian and lives in `AppText` (`core/constants/texts.dart`). No inline strings in widgets. The library is called "Bookmark" in the UI, never "Favorit".
- `RootScreen` stacks the five tabs under a floating pill nav and a bottom fade. Tabs get the nav height as bottom `MediaQuery` padding; scrollables add `MediaQuery.paddingOf(context).bottom`.
- Cover grids (`CoverGridSliver`) use 3 columns on phones and more on wide screens (cells about 150 dp).
- Pull-to-refresh on Home plays the "kuru kururin" animation and sound (`assets/images`, `assets/sounds`).
- Assets are typed through `flutter_gen` (`Assets.images.…`).

---

## 6. Features

| Feature | Screens / entry | Bloc | Notes |
|---|---|---|---|
| home | Home tab | `HomeBloc` | Trending (`/lists/trending`, 10) + latest (`/series?sort=latest`, 20), loaded in parallel. Also shows the last read comic. |
| latest | "Lihat Semua" | `LatestBloc` | Infinite scroll, up to 10 pages. |
| explore | Jelajah tab: title search + filter sheet | `ExploreBloc`, `FilterCubit` | `ExploreFilter` (search `query` + filters) goes to `/series` in one request; the API applies them together. `default` sort, `all` type/status and an empty query are sent as "no filter". Beranda's search button and the genre chips on a comic page switch to this tab through `RootTabs`, which `BacaKomikApp` provides above the navigator so pushed routes can use it. A genre chip replaces the filter with that genre alone (`FilterCubit.showGenre`). Requests run in order so an older search cannot overwrite a newer one. |
| comic_detail | Comic card tap | `ComicDetailsBloc` | Series and chapters fetched in parallel. Bookmark toggle, continue reading, and multi-select of chapters to download or mark read/unread. When the request fails, a comic in the library opens from its stored details (downloads, then bookmarks, then history). Genre chips open Jelajah filtered by that genre. |
| reader | Chapter tap | `ReaderBloc` | Chapter slug is `seriesSlug/number`. Prev/next replace the route. Writes history when a chapter loads. A downloaded chapter is read from files, online or not. |
| bookmark | Bookmark tab | `BookmarkCubit` | Search by title. Pull-to-refresh runs `RefreshBookmarks` (§6.1). |
| history | More → History | `HistoryCubit` | Shows the newest chapter per comic. Remove one chapter, one comic, or everything. |
| settings | More tab | `SettingsCubit` | Theme, clear image cache, bug report link, app info. |
| backup | Lainnya → Cadangkan / Pulihkan | `BackupCubit` | §7.4. |
| download | Lainnya → Unduhan; detail selection bar | `DownloadCubit` | §7.5. |

### 6.1 Checking bookmarks for new chapters

`RefreshBookmarks` loads every bookmarked comic again, one at a time so the API load stays the same as before. When the chapter count changed, it saves the new details with `updatedDate = now`, which moves the bookmark to the top. A comic that fails to load is left unchanged.

---

## 7. Storage

### 7.1 Boxes

| Box | Key | Value |
|---|---|---|
| `bookmarks` | series slug | `BookmarkModel` JSON (includes the comic's details) |
| `history_entries` | chapter slug (`series/number`) | `ReadHistoryModel` JSON |
| `history_comics` | series slug | `HistoryComicModel` JSON (the comic's details) |
| `downloads` | chapter slug | `DownloadedChapterModel` JSON (status, saved page paths, size) |
| `download_comics` | series slug | `DownloadComicModel` JSON (the comic's details, saved cover path) |
| `settings` | `settings` | `SettingsModel` JSON |

Every box is a `Box<String>` that holds JSON. There are no Hive type adapters, so stored data never depends on adapter type ids, and the backup format can reuse the same JSON. `JsonBox<T>` (`core/storage/json_box.dart`) gives typed `values()`, `get`, `put`, `putAll`, `deleteAll` and `clear`. An entry that fails to parse is skipped and logged, so one bad record cannot hide the rest.

Hive keys must be ASCII and at most 255 characters. API slugs meet this.

### 7.2 Stored JSON shape

```jsonc
// bookmark
{ "slug": "solo-leveling", "updatedDate": 1700000000000,   // ms since epoch
  "comicDetails": { "title", "coverImg", "alternativeTitle", "released", "status",
                    "totalChapter", "author", "type", "rating", "synopsis",
                    "genres": [{ "name", "slug" }],
                    "chapters": [{ "number", "slug", "date" }] } }
// history entry (one per read chapter)
{ "slug": "solo-leveling/2", "chapterNumber": "2", "readDate": 1700000100000,
  "comicSlug": "solo-leveling" }
// history comic (one per comic that has history entries)
{ "slug": "solo-leveling", "comicDetails": { … } }
// settings
{ "themeMode": "system", "readingDirection": "vertical", "pageFit": "width",
  "keepScreenOn": true, "pageGap": false }
```

A history entry does not carry the comic's details: they are stored once per comic in `history_comics`, so marking a whole comic as read writes one copy of its chapter list instead of one per chapter. `HistoryRepositoryImpl` joins the two when it reads (entries whose comic record is missing are skipped), writes the latest details it is given, and deletes a comic record once its last entry is removed.

Stored models (`ComicDetailsModel`, `BookmarkModel`, `ReadHistoryModel`, `HistoryComicModel`, `SettingsModel`) map to and from entities with `fromEntity` and `toEntity`. Entities never carry JSON code. The `ReadHistory` entity still includes `comicDetails`, so the UI does not know about the split.

### 7.3 Ordering

Boxes have no order. Repositories sort when they read: bookmarks by `updatedDate` and history by `readDate`, newest first. Because writes are keyed by slug, saving an entry that already exists replaces it.

### 7.4 Backup files

`bacakomik-backup-<y>-<m>-<d>-<h><min><s>.json`, written to a folder the user picks:

```jsonc
{ "version": 2,
  "bookmarks":     [ <bookmark JSON>, … ],
  "history":       [ <history entry JSON>, … ],
  "historyComics": [ <history comic JSON>, … ] }
```

Entries are plain JSON objects, in the same shapes as §7.2. A file with another `version` (including files from the pre-2026 app, which had none) is rejected with a `FileFailure`. When you change the format, bump `BackupRepositoryImpl.formatVersion` and decide whether to keep reading the previous version.

- **Backup:** if the library is empty, nothing happens and the folder picker does not open. Cancelling the picker does nothing.
- **Restore:** merges into the library. Entries with the same slug are replaced. After a restore, the Lainnya screen reloads `BookmarkCubit` and `HistoryCubit`.
- Downloads are not part of backups.

### 7.5 Downloads

Plan and reasoning: `docs/implementation/OFFLINE_DOWNLOAD_PLAN.md`.

- **Files:** `<root>/<seriesSlug>/<chapterNumber>/000.<ext>` and `<root>/<seriesSlug>/cover.<ext>`. The root is `getExternalStorageDirectory()/downloads` on Android (app-specific, no permission, removed on uninstall) and `getApplicationSupportDirectory()/downloads` elsewhere or when external storage is missing. Records store paths relative to the root.
- **Background:** pages are downloaded by `background_downloader` (`PageDownloadQueue`), outside the Dart isolate, so they continue while the app is in the background, the phone is locked, or the process is gone. A native holding queue runs three pages at a time in enqueue order. One grouped notification shows `x/y halaman`, then done or failed. Notification permission (`POST_NOTIFICATIONS`) is asked on the first download. Each page gets 10 retries with backoff, so short connection drops do not fail a chapter.
- **Preparing:** `DownloadRepositoryImpl` takes queued chapters one at a time, fetches fresh page URLs through `ReaderRepository` (needs a connection), records the planned page paths, and hands the missing pages to the queue. Covers are fetched directly with Dio.
- **Progress:** page events update the record while the app runs. Pages finished while the app was suspended or closed are found on disk: on start and whenever the app resumes (`DownloadCubit` calls `sync()`), downloading chapters are checked against their planned paths. A chapter with no pages left in the queue and pages missing becomes failed. Chapters still waiting for their page list after a restart are prepared again.
- **Status:** `queued → downloading → completed`, or `failed`. Retry keeps saved pages and fetches the rest.
- **Reading:** `GetChapterContent` asks `DownloadRepository.getOfflineChapter` first; a completed chapter with all its files returns `ChapterContent(isOffline: true)` with file paths, and `ChapterImg` shows them with `Image.file`. `GetComicDetails` falls back to `getOfflineComic` when the request fails.
- **Clearing the image cache** does not touch downloads.

---

## 8. Networking

### 8.1 API

`SeriesRemoteDataSource` is the only class that knows the endpoints:

| Method | Endpoint |
|---|---|
| `getSeriesList` | `GET /series?page&limit&q&genre&status&format&sort` |
| `getCuratedList` | `GET /lists/{kind}?page&limit` |
| `getSeries` | `GET /series/{slug}` |
| `getChapters` | `GET /series/{slug}/chapters` |
| `getChapter` | `GET /series/{slug}/chapters/{number}` |

Responses are `{ "data": … }`. `ApiClient` drops null and empty query values and turns `DioException` into `ServerException`, using the API's `error` message when there is one. DTOs (`SeriesResponse`, `SeriesDetailResponse`, `ChapterResponse`, `ChapterDetailResponse`) convert to entities with `ApiFormat`. Examples: `rating 9.25` becomes `"9.3"`, `number 1.5` becomes `"1.5"`, a missing format becomes `"-"`, and `createdAt` becomes "3 jam lalu".

### 8.2 `runRemote`

```dart
runRemote(networkInfo, () async { … })
```

1. Without a connection, returns `NetworkFailure` and makes no request.
2. Otherwise runs the call. `ServerException` becomes `ServerFailure(message)`, and any other error becomes `ServerFailure(e.toString())`.

When one call makes several requests in parallel, use `Future.wait` so the first error fails the whole call. Do not use the record `.wait` extension: it wraps errors in `ParallelWaitError`.

---

## 9. Errors and logging

- **Data layer** throws `ServerException` or `CacheException`, or lets library errors through.
- **Repositories** catch everything and return `Left(Failure)`: `ServerFailure`, `NetworkFailure`, `CacheFailure` or `FileFailure`.
- **Blocs** map `NetworkFailure` to a `noInternet` state, which shows `ErrNoInternet`. Other failures become `error(message)`. Library cubits log failures with `debugPrint` and reload. Backup failures show a snackbar.
- Use `debugPrint` for logging, never `print`. Never log full backup contents.

---

## 10. Code generation

`build_runner` generates:

- `*.freezed.dart` (freezed) and `*.g.dart` (json_serializable) next to their sources.
- `lib/core/di/injection.config.dart` (injectable).
- `lib/core/assets/assets.gen.dart` (flutter_gen).

Generated files are committed and excluded from analysis (`analysis_options.yaml`). `build.yaml` turns on `explicit_to_json` so nested models are written as maps.

### 10.1 Version pins

- `freezed: ">=4.0.0 <4.0.2"`. freezed 3.x generates `final` constructor parameters, which Dart 3.13 rejects. 4.0.2 and later need a newer `test` than the one `flutter_test` pins.
- `hive_ce_generator` is intentionally **not** a dependency. Boxes store JSON strings (§7.1), and the generator's analyzer range conflicts with freezed.

Upgrade these together, in their own PR, and run the full test suite after code generation.

---

## 11. Feature summary

| Area | Status |
|---|---|
| Home (trending, latest, last read) | Done |
| Latest, search, explore with filters | Done (10-page cap) |
| Comic detail, mark chapters read/unread | Done |
| Reader (prev/next, zoom, save image) | Done |
| Bookmarks with "new chapters" refresh | Done |
| History | Done |
| Theme setting (system/light/dark) | Done |
| Backup / restore | Done |
| Offline reading (chapter downloads) | Done (background downloads on Android) |

---

## 12. Open questions

- **Formatting:** the code base predates the current `dart format` style. Reformatting everything in one commit would be a large, noisy diff. Decide whether to do it once.
