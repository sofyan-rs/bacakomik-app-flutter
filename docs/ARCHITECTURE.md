# Architecture

BacaKomik is a Flutter app for reading comics (manga, manhwa, manhua) from **bacakomik-api**. It is built with **feature-first clean architecture** and **BLoC**.

Scope: **browse comics, read chapters, and keep a personal library** (bookmarks, reading history, settings, backup files). There are no accounts and no cloud sync. Library data lives only on the device and in backup files the user exports.

This file covers how the app is built. Section numbers (§) refer to this file.

---

## 1. Goals and non-goals

### Goals
- **Never lose the user's library.** Bookmarks, history and settings survive updates. Data from older app versions is migrated (§7.4), and backup files stay readable across versions (§7.5).
- **Keep logic testable.** Domain code is plain Dart with no Flutter, Dio, Hive or file-picker imports. Repositories and blocs are tested without a device.
- **Keep layers clear.** UI talks to blocs, blocs call use cases, use cases call repository interfaces. Only the data layer knows about HTTP and storage.
- Work on phones and wide screens. Root navigation switches from a bottom bar to a navigation rail at 640 dp.

### Non-goals
- User accounts, cloud sync, or a server-side library.
- Offline reading or chapter downloads. Reading needs a network connection.
- Hosting or scraping comics. All content comes from bacakomik-api.
- An in-app updater. Updates come through the release channel.

---

## 2. Tech stack

| Concern | Choice | Notes |
|---|---|---|
| Language / UI | Dart 3.13, Flutter (stable) | Material 3 widgets, Rubik font via `google_fonts`, Solar icons. |
| State | `flutter_bloc` (Bloc and Cubit) | States are freezed sealed unions (§4.3). |
| Dependency wiring | `get_it` + `injectable` | Generated in `lib/core/di/injection.config.dart` (§10). |
| Errors | `fpdart` `Either<Failure, T>` | Repositories never throw to callers (§9). |
| Models | `freezed` + `json_serializable` | Entities, states and API DTOs use freezed; stored models use `@JsonSerializable` (§7.2). |
| HTTP | `dio` behind `ApiClient` | Base URL from `--dart-define=API_BASE_URL`, default `https://api-bacakomik.kurodev.org`. |
| Connectivity | `connectivity_plus` behind `NetworkInfo` | Checked before every remote call (§8.2). |
| Local storage | `hive_ce` | Boxes of JSON strings, no type adapters (§7). |
| Images | `cached_network_image`, `flutter_cache_manager` | "Clear cache" in settings empties the image cache. |
| Backup files | `file_picker` + `dart:io` | Behind `BackupFileDataSource` (§7.5). |
| Saving pages | `gal` | Saves a reader image to the gallery. |
| Tests | `flutter_test`, `bloc_test`, `mocktail` | Hive tests use a temp directory (CONTRIBUTION §5). |

Exact versions live in `pubspec.yaml` and `pubspec.lock`. Read §10.1 before you change `freezed` or the generators.

**Application id:** `org.kurodev.bacakomik`.

**SDK levels:** `minSdk` and `targetSdk` come from Flutter (currently 24 and 36), `compileSdk 37`, Java 17.

---

## 3. Project structure

```
lib/
├── main.dart                       # Hive.init → DI → legacy migration → runApp
├── app/
│   ├── app.dart                    # BacaKomikApp: app-wide BlocProviders, MaterialApp, theme mode
│   ├── splash_screen.dart
│   ├── root_screen.dart            # tabs: Home, Explore, Bookmark, More
│   └── legacy_storage_migrator.dart  # hydrated_bloc → Hive, runs once (§7.4)
├── core/
│   ├── assets/assets.gen.dart      # flutter_gen output
│   ├── constants/                  # colors, texts (UI strings), theme, filters, variables
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
│   │   └── widgets/                # comic card, chips, placeholders
│   └── utils/                      # ApiFormat, Clock, snackbar/save-image helpers
└── features/
    ├── home/          # trending + latest on the home tab
    ├── latest/        # "see all" latest chapters, paginated
    ├── search/        # keyword search, paginated
    ├── explore/       # filter by sort/type/status/genre, paginated
    ├── comic_detail/  # comic info + chapter list
    ├── reader/        # chapter images, prev/next
    ├── bookmark/      # local: bookmarked comics, "check for new chapters"
    ├── history/       # local: read chapters
    ├── settings/      # local: theme; the More tab
    └── backup/        # export/import the library as a JSON file
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
- **core** never imports from `features/`. Code that has to know several features (the migrator, the app shell) lives in `lib/app/`.

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
          ── LegacyStorageMigrator.migrate()
          ── runApp(BacaKomikApp)

   BacaKomikApp ─ MultiBlocProvider (app scope)
   │   HomeBloc · ExploreBloc · FilterCubit · BookmarkCubit · HistoryCubit · SettingsCubit · BackupCubit
   └─ MaterialApp ─ SplashScreen ─▶ RootScreen (tabs)
                                      │ Navigator.push
                                      ▼
            route-scoped blocs: SearchBloc · LatestBloc · ComicDetailsBloc · ReaderBloc

   Bloc/Cubit ─▶ UseCase ─▶ Repository (interface) ─▶ RepositoryImpl
                                                       ├─ SeriesRemoteDataSource ─▶ ApiClient (Dio)
                                                       └─ *LocalDataSource ─▶ JsonBox ─▶ Hive box
```

### 4.1 Startup

1. `Hive.init` points Hive at the application documents directory. hydrated_bloc used the same directory, which is what makes §7.4 work.
2. `configureDependencies()` registers everything and opens the four Hive boxes before returning (`@preResolve` in `StorageModule`).
3. `LegacyStorageMigrator.migrate()` copies old hydrated_bloc data once.
4. `runApp`. `BookmarkCubit`, `HistoryCubit` and `SettingsCubit` call `load()` when they are first created.

### 4.2 Bloc scope

- **App scope** (`lib/app/app.dart`): the bottom-tab blocs (`HomeBloc`, `ExploreBloc`, `FilterCubit`) and the library (`BookmarkCubit`, `HistoryCubit`, `SettingsCubit`, `BackupCubit`). Several screens read them, and they have to outlive navigation.
- **Route scope:** `SearchScreen`, `LatestChapterScreen`, `ComicDetailsScreen` and `ReadChapterScreen` each create their own bloc with `BlocProvider(create: (_) => getIt<…>())`. The public screen widget is a thin wrapper and the stateful view underneath is private (`_ComicDetailsView`). Opening a second comic or moving to the next chapter therefore always starts from a fresh state.

### 4.3 State shapes

- Remote screens use a freezed sealed state: `initial`, `loading`, `loaded(...)`, `error(message)`, `noInternet`. The generated classes are public (`HomeLoaded`, `ComicDetailsNoInternet`), so widgets use `state is HomeLoaded`.
- The paginated lists (latest, search, explore) share `ComicListState` and the `ComicListLoader` mixin: `loadFirstPage` and `loadNextPage`. A next-page event is ignored until the first page has loaded. While a page is loading, `ComicListLoaded.isLoadMore` is true.
- Library cubits hold plain lists (`List<Bookmark>`, `List<ReadHistory>`) or `AppSettings`. After every write they reload from the repository, so the state always matches storage.
- Events are plain `final class`es named after what happened: `HomeStarted`, `HomeRefreshed`, `SearchRequested`, `ChapterRequested`.

### 4.4 Settings

`AppSettings` has one field today, `darkMode`, which holds one of `AppText.system`, `AppText.light` or `AppText.dark`. `BacaKomikApp` maps it to `ThemeMode`. The values are the UI strings because earlier versions stored them that way. Keep them unless you also migrate stored settings.

---

## 5. Theme and UI

- `core/constants/theme.dart` defines `AppThemes.lightTheme` and `AppThemes.darkTheme` with the Rubik font. `core/constants/colors.dart` holds the primary blue `0xFF2565c7` and the format colours (manga, manhwa, manhua).
- All user-facing text is Indonesian and lives in `AppText` (`core/constants/texts.dart`). No inline strings in widgets.
- Icons come from `solar_icons`.
- `RootScreen` shows a `NavigationBar` below 640 dp and a `NavigationRail` from 640 dp. Grids use 2 columns below 640 dp and 4 from 640 dp.
- Pull-to-refresh on Home plays the "kuru kururin" animation and sound (`assets/images`, `assets/sounds`).
- Assets are typed through `flutter_gen` (`Assets.images.…`).

---

## 6. Features

| Feature | Screens / entry | Bloc | Notes |
|---|---|---|---|
| home | Home tab | `HomeBloc` | Trending (`/lists/trending`, 10) + latest (`/series?sort=latest`, 20), loaded in parallel. Also shows the last read comic. |
| latest | "Lihat Semua" | `LatestBloc` | Infinite scroll, up to 10 pages. |
| search | Search button | `SearchBloc` | Searches `/series?q=`. |
| explore | Explore tab + filter screen | `ExploreBloc`, `FilterCubit` | `ExploreFilter`. `default` sort and `all` type/status are sent as "no filter". |
| comic_detail | Comic card tap | `ComicDetailsBloc` | Series and chapters fetched in parallel. Bookmark toggle, continue reading, and multi-select of chapters to mark read or unread. |
| reader | Chapter tap | `ReaderBloc` | Chapter slug is `seriesSlug/number`. Prev/next replace the route. Writes history when a chapter loads. |
| bookmark | Bookmark tab | `BookmarkCubit` | Search by title. Pull-to-refresh runs `RefreshBookmarks` (§6.1). |
| history | More → History | `HistoryCubit` | Shows the newest chapter per comic. Remove one chapter, one comic, or everything. |
| settings | More tab | `SettingsCubit` | Theme, clear image cache, bug report link, app info. |
| backup | More → Backup / Restore | `BackupCubit` | §7.5. |

### 6.1 Checking bookmarks for new chapters

`RefreshBookmarks` loads every bookmarked comic again, one at a time so the API load stays the same as before. When the chapter count changed, it saves the new details with `updatedDate = now`, which moves the bookmark to the top. A comic that fails to load is left unchanged.

---

## 7. Storage

### 7.1 Boxes

| Box | Key | Value |
|---|---|---|
| `bookmarks` | series slug | `BookmarkModel` JSON |
| `history` | chapter slug (`series/number`) | `ReadHistoryModel` JSON |
| `settings` | `settings` | `SettingsModel` JSON |
| `app_meta` | flags | e.g. `hydrated_migrated_v1 = "true"` |

Every box is a `Box<String>` that holds JSON. There are no Hive type adapters, so stored data never depends on adapter type ids, and the backup format can reuse the same JSON. `JsonBox<T>` (`core/storage/json_box.dart`) gives typed `values()`, `get`, `put`, `putAll`, `deleteAll` and `clear`. An entry that fails to parse is skipped and logged, so one bad record cannot hide the rest.

Hive keys must be ASCII and at most 255 characters. API slugs meet this.

### 7.2 Stored JSON shape (compatibility contract)

The field names are the ones earlier versions wrote. Do not rename them:

```jsonc
// bookmark
{ "slug": "solo-leveling", "updatedDate": 1700000000000,   // ms since epoch
  "comicDetails": { "title", "coverImg", "alternativeTitle", "released", "status",
                    "totalChapter", "author", "type", "rating", "synopsis",
                    "genres": [{ "name", "slug" }],
                    "chapters": [{ "number", "slug", "date" }] } }
// history
{ "slug": "solo-leveling/2", "chapterNumber": "2", "readDate": 1700000100000,
  "comicDetails": { … }, "comicSlug": "solo-leveling" }
// settings
{ "darkMode": "Sistem" }
```

Stored models (`ComicDetailsModel`, `BookmarkModel`, `ReadHistoryModel`, `SettingsModel`) map to and from entities with `fromEntity` and `toEntity`. Entities never carry JSON code.

### 7.3 Ordering

Boxes have no order. Repositories sort when they read: bookmarks by `updatedDate` and history by `readDate`, newest first. Because writes are keyed by slug, saving an entry that already exists replaces it.

### 7.4 Migration from hydrated_bloc

Up to v1.0.1 the library lived in hydrated_bloc's `hydrated_box` (`hive` v2 format, which `hive_ce` reads). On startup, `LegacyStorageMigrator` does this:

1. Return at once if `app_meta[hydrated_migrated_v1] == "true"`.
2. If `hydrated_box` exists, read these keys:
   - `FavoriteCubit` → `{ bookmarks_comic: [entry, …] }`
   - `HistoryCubit` → `{ history_read: [entry, …] }`
   - `SettingsCubit` → `{ value: entry }`

   An entry is an encoded JSON string. The migrator also accepts a map.
3. Write the entries to the new boxes, skipping any that fail to parse.
4. Set the flag. If something throws, the flag is not set and the next launch tries again.

The old box stays on disk. Deleting it is a possible clean-up for a later release (§12). The fixtures in `test/fixtures/legacy_storage_fixtures.dart` are hand-written copies of the old format. Do not regenerate them from current code.

### 7.5 Backup files

`bacakomik-backup-<y>-<m>-<d>-<h><min><s>.json`, written to a folder the user picks:

```jsonc
{ "bookmarks": ["<bookmark JSON as a string>", …],
  "history":   ["<history JSON as a string>", …] }
```

Each entry is an **encoded JSON string**, not an object. That is how older versions wrote it, and it lets older versions restore new backups. When reading a backup, the app also accepts plain objects, the old `favorites` key in place of `bookmarks`, and a missing `history`.

- **Backup:** if the library is empty, nothing happens and the folder picker does not open. Cancelling the picker does nothing.
- **Restore:** merges into the library. Entries with the same slug are replaced. After a restore, the More screen reloads `BookmarkCubit` and `HistoryCubit`.

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
| Migration from hydrated_bloc storage | Done (§7.4) |
| Offline reading | Not planned |

---

## 12. Open questions

- **Listeners added in `build()`:** the search, explore and latest lists add their `ScrollController` listener inside `build()`. Listeners pile up on every rebuild, which probably triggers load-more more than once. Comic detail (title on scroll) and bookmarks (search field) do the same, which causes extra `setState` calls. Move all of them to `initState`.
- **Old storage:** when should `hydrated_box.hive` be deleted? Not before most users run a version with the migrator.
- **Formatting:** the code base predates the current `dart format` style. Reformatting everything in one commit would be a large, noisy diff. Decide whether to do it once.
