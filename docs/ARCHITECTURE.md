# Architecture

BacaKomik is a Flutter app for reading comics (manga, manhwa, manhua). Content comes from **sources**: JavaScript extensions that the app installs from extension repos and runs in an embedded JS engine (§8). It is built with **feature-first clean architecture** and **BLoC**.

Scope: **browse comics from the installed sources, read chapters, and keep a personal library** (bookmarks, categories, reading history, downloads, settings). The library lives on the device. The user can export it to backup files (§7.4) and, after signing in with Google, sync it through a private file in their own Google Drive (§7.6). There is no BacaKomik account and no server-side library.

This file covers how the app is built. Section numbers (§) refer to this file.

---

## 1. Goals and non-goals

### Goals
- **Never lose the user's library.** Bookmarks, categories, history and settings survive updates, and backup files (§7.4) and sync (§7.6) restore them. Storage starts fresh from the 2026 rewrite: data from the pre-2026 app is not migrated, and its backup files are not read.
- **Keep logic testable.** Domain code is plain Dart with no Flutter, Dio, Hive or file-picker imports. Repositories and blocs are tested without a device; sources are replaced by fakes (CONTRIBUTION §5).
- **Keep layers clear.** UI talks to blocs, blocs call use cases, use cases call repository interfaces. Only the data layer knows about sources, HTTP and storage.
- **Keep sources out of the app.** Site-specific code lives in extensions, so a site change ships as an extension update, not an app release.
- Work on phones and wide screens. A floating pill nav sits at the bottom on every width; cover grids add columns as the screen gets wider.

### Non-goals
- A BacaKomik account or a server-side library. Sync only uses the user's own Drive (`drive.appdata` scope).
- Hosting comics. Extensions read the sites and APIs of their sources; the app only offers them host functions (§8.4).
- iOS. Releases are Android APKs. The code mostly runs on iOS, but background downloads, hidden-WebView rendering (§8.5) and progress notifications are Android-only or untested there. Download tasks use absolute paths, which iOS can move between launches (§7.5).
- An app store listing. Releases are APKs on GitHub Releases; the app checks the latest release on start and from More, downloads the APK for the device's ABI and opens Android's installer (`features/update`, `ota_update`). Asset names and the `## Which APK?` heading are set by the release workflow (CONTRIBUTION §2).

---

## 2. Tech stack

| Concern | Choice | Notes |
|---|---|---|
| Language / UI | Dart 3.13, Flutter (stable) | Material 3 widgets themed with the Dotline design system (§5). Bundled Geist, Geist Mono and Doto fonts, Lucide icons via `lucide_icons_flutter`. |
| State | `flutter_bloc` (Bloc and Cubit) | States are freezed sealed unions or plain values (§4.3). |
| Dependency wiring | `get_it` + `injectable` | Generated in `lib/core/di/injection.config.dart` (§10). |
| Errors | `fpdart` `Either<Failure, T>` | Repositories never throw to callers (§9). |
| Models | `freezed` + `json_serializable` | Entities, states and source DTOs use freezed; stored models use `@JsonSerializable` (§7.2). |
| Sources | `flutter_js` | One QuickJS engine per source (JavaScriptCore on iOS) runs the extension script (§8.3). `crypto` checks downloaded scripts against their `sha256`. |
| Source HTTP | `dio` + `native_dio_adapter`, `cookie_jar` + `dio_cookie_manager`, `html` | Requests go through Cronet on Android with one persistent cookie jar per source. `html.select` parses with `package:html` (§8.4). |
| WebViews | `flutter_inappwebview` | Hidden WebViews for `webview.run` and blocked image hosts (§8.5), and the visible WebView screen for Cloudflare checks. |
| Images | `cached_network_image`, `flutter_cache_manager`, `cronet_http` | One `comicImageCache` for covers, pages and downloads (§8.6). "Clear cache" in settings empties it. |
| Other HTTP | `dio` | `filesDio` (no base URL) for extension repos, script downloads, Drive and GitHub releases. `ApiClient` wraps it for GitHub's JSON. |
| Connectivity | `connectivity_plus` behind `NetworkInfo` | Checked before every source call (§8.7). |
| Local storage | `hive_ce` | Boxes of JSON strings, no type adapters (§7). |
| Downloads | `background_downloader` | Chapter pages download outside the Dart isolate (§7.5). |
| Notifications | `flutter_local_notifications` | Progress notification for bookmark refresh (`ProgressNotifier`, §6.1). Downloads use background_downloader's own notification. |
| Sync | `google_sign_in` + Drive REST over Dio | §7.6. |
| Backup files | `file_picker` + `dart:io` | Behind `BackupFileDataSource` (§7.4). |
| Links and sharing | `app_links`, `share_plus` | Shared comic links `https://bacakomik.kurodev.org/series/<slug>` open the app (`DeepLinks`; the host is served from `hosting/worker`). |
| Saving pages | `gal` | Saves a reader image to the gallery. |
| Tests | `flutter_test`, `bloc_test`, `mocktail` | Hive tests use a temp directory (CONTRIBUTION §5). |

Exact versions live in `pubspec.yaml` and `pubspec.lock`. Read §10.1 before you change `freezed` or the generators.

**Application id:** `org.kurodev.bacakomik`.

**SDK levels:** `minSdk` and `targetSdk` come from Flutter (currently 24 and 36), `compileSdk 37`, Java 17.

---

## 3. Project structure

```
lib/
├── main.dart                       # Hive.init → DI → bundled extensions → runApp
├── app/
│   ├── app.dart                    # BacaKomikApp: app-wide BlocProviders and listeners, MaterialApp, theme mode
│   ├── splash_screen.dart
│   ├── root_screen.dart            # tabs: Home, Explore, Bookmarks, History, More (floating nav); update check
│   └── root_tabs.dart              # RootTabs: lets pushed routes switch tabs
├── core/
│   ├── assets/                     # flutter_gen output
│   ├── constants/                  # texts (UI strings), variables
│   ├── theme/                      # Dotline tokens: colors, text styles, spacing, ThemeData
│   ├── di/                         # injection.dart, register_module.dart (filesDio, SourceRegistry, Connectivity, Hive)
│   ├── error/                      # exceptions.dart (data layer, Challenge), failures.dart (domain)
│   ├── network/                    # NetworkInfo, runRemote(), ApiClient (GitHub), image_cache.dart
│   ├── notifications/              # ProgressNotifier
│   ├── source/                     # extensions: manager, meta, runtime, bridge, hidden pages, ComicKey (§8)
│   ├── storage/                    # HiveBoxes + StorageModule, JsonBox<T>, runLocal(), LibraryJournal
│   ├── usecase/usecase.dart        # UseCase<T, Params>, NoParams
│   ├── domain/entities/            # Comic, ComicDetails, Genre, Chapter (shared by features)
│   ├── data/
│   │   ├── datasources/series_remote_data_source.dart  # calls source methods through SourceRegistry
│   │   └── models/                 # SeriesResponse… (source DTOs), ComicDetailsModel (stored)
│   ├── presentation/
│   │   ├── bloc/comic_list_state.dart  # paginated list state + ComicListLoader mixin
│   │   └── widgets/                # comic card + grid, dotline/ (Dotline component library)
│   └── utils/                      # ApiFormat, Clock, DeepLinks, version compare, snackbar/save-image helpers
└── features/
    ├── home/          # active source's featured + latest lists, last read comic
    ├── latest/        # "see all" latest, paginated
    ├── explore/       # search + the source's filter groups, paginated
    ├── comic_detail/  # comic info + chapter list, duplicate-source sheet
    ├── reader/        # chapter images, prev/next, reading position
    ├── bookmark/      # local: bookmarks, grouping, refresh, move between sources
    ├── category/      # local: custom bookmark categories
    ├── history/       # local: read chapters (History tab)
    ├── settings/      # local: theme, reader settings, grouping; the More tab
    ├── backup/        # export/import the library as a JSON file
    ├── sync/          # Google Drive sync of the library
    ├── download/      # local: chapters saved for offline reading, background download queue
    ├── migration/     # migrate bookmarks between sources; import from Mihon/Tachiyomi and Comix.to
    ├── source/        # Extensions screen, source picker, WebView screen, source error states
    └── update/        # in-app updates from GitHub Releases
```

Every feature uses the same layout. A layer folder exists only if the feature needs it (`source` has only `presentation/`; its logic is in `core/source/`):

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

- **domain** imports nothing from `data`, `presentation`, Flutter, Dio, Hive or file_picker. It may import `fpdart`, `freezed_annotation`, `injectable`, plain-Dart helpers in `core` (for example `ComicKey`) and other features' **domain** code.
- **data** implements domain interfaces. It may import other features' data models when a format is shared (for example `backup` and `sync` read `BookmarkModel`).
- **presentation** calls use cases through blocs. Widgets may read cubits from other features (for example `comic_detail` reads `BookmarkCubit` and `HistoryCubit`).
- **core** never imports from `features/` (the generated `injection.config.dart` is the exception). Code that has to know several features (the app shell, root tabs) lives in `lib/app/`.

Check the domain rule with:

```bash
grep -rn "^import" lib/core/domain lib/features/*/domain | grep -E "package:flutter|/data/|/presentation/|hive|dio|file_picker"
```

It must print nothing.

### Rules for adding code

1. **Group by feature, then by layer.** Only shared things go in `core/`.
2. **One main type per file, named after the file.** `bookmark_cubit.dart` → `BookmarkCubit`. Small groups of related use cases may share a file (`bookmark_usecases.dart`).
3. **Use cases are thin.** If a use case only forwards to the repository, keep it one line. Put real rules in the domain (`ReadHistoryQueries`, `RefreshBookmark`, `MigrateComic`) so they can be tested.
4. **Repositories return `Either`.** Wrap source calls in `runRemote` and local calls in `runLocal` (§9).
5. **Register with injectable.** Use cases, blocs and cubits use `@injectable`. Repositories and data sources use `@LazySingleton(as: Interface)`. Then run code generation (§10).
6. **Keep files under ~400 lines.** Split by responsibility past that.

### Where does my code go?

| I'm writing… | Put it in |
|---|---|
| A rule about comics, chapters, bookmarks or history | that feature's `domain/` + a test |
| Support for a new site | an extension in the `bacakomik-ext-source` repo, not this app (§8.2) |
| A new source method the app calls | the contract in `bacakomik-ext-source`, then `SeriesRemoteDataSource` + a DTO in `core/data/models/` |
| A new host function for extensions | `ExtensionBridge.handle` + the prelude in `ExtensionRuntime` (bump `supportedExtensionApi` if old apps cannot run the new scripts) |
| Data stored on the device | a feature `data/datasources/*_local_data_source.dart` over a `JsonBox` (§7) |
| A screen | `features/<name>/presentation/pages/` |
| A widget used by several features | `core/presentation/widgets/` |
| A UI string | `core/constants/texts.dart` (`AppText`) |
| Something that wires several features together | `lib/app/` |

---

## 4. Runtime model

```
   main() ── Hive.init(app documents dir)
          ── configureDependencies()          # opens the Hive boxes (preResolve)
          ── ExtensionManager.installBundled() # sources exist before the first screen
          ── runApp(BacaKomikApp)
          ── ExtensionManager.catalog()        # background: repo fetch, update badge

   BacaKomikApp ─ MultiBlocProvider (app scope)
   │   SourcesCubit · HomeBloc · ExploreBloc · FilterCubit · BookmarkCubit · CategoryCubit
   │   HistoryCubit · SettingsCubit · DownloadCubit · BackupCubit · UpdateCubit · SyncCubit
   └─ MaterialApp ─ SplashScreen ─▶ RootScreen (tabs)
                                      │ Navigator.push
                                      ▼
            route-scoped blocs: LatestBloc · ComicDetailsBloc · ReaderBloc · ExtensionsCubit

   Bloc/Cubit ─▶ UseCase ─▶ Repository (interface) ─▶ RepositoryImpl
                                                       ├─ SeriesRemoteDataSource ─▶ SourceRegistry (ExtensionManager)
                                                       │     └─ ExtensionRuntime (QuickJS) ─▶ ExtensionBridge
                                                       │           ├─ Dio (Cronet, cookie jar per source)
                                                       │           └─ HeadlessPages (hidden WebView)
                                                       └─ *LocalDataSource ─▶ JsonBox ─▶ Hive box
```

### 4.1 Startup

1. `Hive.init` points Hive at the application documents directory.
2. `configureDependencies()` registers everything and opens the fourteen Hive boxes (§7.1) before returning (`@preResolve` in `StorageModule`).
3. `ExtensionManager.installBundled()` installs or upgrades the extensions shipped in `assets/extensions/` (§8.2).
4. `runApp`. `BookmarkCubit`, `CategoryCubit`, `HistoryCubit`, `SettingsCubit` and `DownloadCubit` call `load()` when they are first created. `SourcesCubit` and `SyncCubit` are created eagerly (`lazy: false`); `SyncCubit.start()` restores the Google account and syncs (§7.6).
5. `ExtensionManager.catalog()` fetches every repo in the background to count extension updates.

### 4.2 Bloc scope

- **App scope** (`lib/app/app.dart`): the bottom-tab blocs (`HomeBloc`, `ExploreBloc`, `FilterCubit`), the active source (`SourcesCubit`), the library (`BookmarkCubit`, `CategoryCubit`, `HistoryCubit`, `SettingsCubit`, `DownloadCubit`, `BackupCubit`, `SyncCubit`) and `UpdateCubit`. Several screens read them, and they have to outlive navigation.
- Two app-level listeners connect them. When `SourcesCubit`'s active source changes, `FilterCubit.setSource` resets the filters and `HomeBloc` reloads. When `SyncCubit.libraryRevision` changes (a sync changed local data), the bookmark, category and history cubits reload.
- **Route scope:** `LatestChapterScreen`, `ComicDetailsScreen`, `ReadChapterScreen` and `ExtensionsScreen` each create their own bloc with `BlocProvider(create: (_) => getIt<…>())`. The public screen widget is a thin wrapper and the stateful view underneath is private (`_ComicDetailsView`). Opening a second comic or moving to the next chapter therefore always starts from a fresh state.

### 4.3 State shapes

- Remote screens use a freezed sealed state: `initial`, `loading`, `loaded(...)`, `error(message)`, `noInternet`. The generated classes are public (`HomeLoaded`, `ComicDetailsNoInternet`), so widgets use `state is HomeLoaded`. Error states render `SourceError` (§9).
- The paginated lists (latest, explore) share `ComicListState` and the `ComicListLoader` mixin: `loadFirstPage` and `loadNextPage`. A next-page event is ignored until the first page has loaded. While a page is loading, `ComicListLoaded.isLoadMore` is true.
- Library cubits hold plain lists (`List<Bookmark>`, `List<ReadHistory>`) or `AppSettings`. After every write they reload from the repository, so the state always matches storage.
- `SourcesState` mirrors `ExtensionManager` (a `ChangeNotifier`): installed sources, every known source (including languages turned off), the active source and its `SourceFeatures`, and the update count.
- Events are plain `final class`es named after what happened: `HomeStarted`, `HomeRefreshed`, `ExploreRequested`, `ChapterRequested`.

### 4.4 Settings

`AppSettings` holds `themeMode` (`AppThemeMode.system | light | dark`, mapped to Flutter's `ThemeMode` in `BacaKomikApp`), the reader settings (`readingDirection`, `pageFit`, `keepScreenOn`, `pageGap`, `autoScrollSpeed`) and `bookmarkGrouping` (`status | source | category`). `SettingsModel` gives every field a default and falls back on unknown enum values, so a field added later never breaks loading.

Source settings (repos, active source, enabled languages) are not part of `AppSettings`; `ExtensionManager` keeps them in the `source_settings` box (§7.1).

---

## 5. Theme and UI

The UI uses **Dotline**, a monochrome, dark-first design system: pure black background in dark mode (`#F2F2F2` in light), flat surfaces with hairlines, pills and dot motifs. Rules worth keeping:

- **Red is a signal, not a colour.** `accent` appears at most once or twice per screen (NEW dot, `+N` badge, delete actions). Selected chips, switches and segments use `ink`.
- **Doto only for screen titles** (`HOME`, `EXPLORE`) and the app name, never below 24 px. Numbers use `DotlineText.stat` / `statS` (Geist 600). Labels and overlines use Geist Mono, uppercase.
- **No gradients or glass.** The one exception is the bottom fade behind the nav. Depth comes from `bg` → `surface` → `surfaceRaised`; `shadowFloat` is only for menus and the reader's chapter pill (the main nav has none).
- **Comic types are labels, not colours.** Manga, manhwa and manhua get the same black label pill.
- Motion: 140 ms presses (scale to 0.97, no ripple), about 320 ms sliding selection indicators. Respect `MediaQuery.disableAnimationsOf`.

- `core/theme/` holds the tokens: `DotlineColors` (a `ThemeExtension`, read with `Dotline.of(context)`), `DotlineText`, `DotSpace` / `DotRadius` / `DotSize` / `DotMotion`, and `dotlineTheme()` for light and dark.
- Build screens from `core/presentation/widgets/dotline/` (`ScreenHeader`, `ListGroup` + `ListRow`, `SegmentedControl`, `ScrollableTabs`, `DotButton`, `DotChip`, `DotSwitch`, `showDotSheet`, `DotMeter`, `ComicCover`, `EmptyState`…) instead of raw Material widgets. There is no ripple; taps scale through `Pressable`.
- Icons are Lucide from `lucide_icons_flutter`, weight 300 only (`LucideIcons300`, stroke ≈ 1.5). Do not use Material `Icons`.
- All user-facing text is English and lives in `AppText` (`core/constants/texts.dart`). No inline strings in widgets. The library is called "Bookmarks" in the UI, never "Favorites". Text that comes from a source (titles, synopses, genre and filter labels) is shown as the source sends it.
- `RootScreen` stacks the five tabs under a floating pill nav and a bottom fade. Tabs get the nav height as bottom `MediaQuery` padding; scrollables add `MediaQuery.paddingOf(context).bottom`.
- Cover grids (`CoverGridSliver`) use 3 columns on phones and more on wide screens (cells about 150 dp).
- Pull-to-refresh on Home plays the "kuru kururin" animation and sound (`assets/images`, `assets/sounds`).
- Assets are typed through `flutter_gen` (`Assets.images.…`).

---

## 6. Features

| Feature | Screens / entry | Bloc | Notes |
|---|---|---|---|
| home | Home tab | `HomeBloc` | Two `browse` calls on the active source, in parallel: the slider with the extension's `home.featured` filters (10 items) and the list with `home.latest` (20). Also shows the last read comic. The header opens the source picker. |
| latest | "See all" | `LatestBloc` | Infinite scroll, up to 10 pages. |
| explore | Explore tab: title search + filter sheet | `ExploreBloc`, `FilterCubit` | `ExploreFilter` holds the source, the search `query` and the picked values per filter group; it goes to the source's `browse` in one call. The filter sheet is built from the source's `filters()` groups, and a group marked `quick` shows above the grid. Changing source resets the filter. Home's search button and the genre chips on a comic page switch to this tab through `RootTabs`; a genre chip replaces the filter with that genre alone (`FilterCubit.showGenre`). Requests run in order so an older search cannot overwrite a newer one. |
| comic_detail | Comic card tap, shared link | `ComicDetailsBloc` | Series and chapters fetched in parallel. Bookmark toggle (then the category picker, §6.2), continue reading, open in WebView, share, and multi-select of chapters to download or mark read/unread. When the request fails, a comic in the library opens from its stored details (downloads, then bookmarks, then history). A comic whose source is not installed shows `MissingSource`, which offers to install it from the repos. |
| reader | Chapter tap | `ReaderBloc` | Chapter slug is `<comicKey>/<number>`. Prev/next replace the route. Writes history (with the page reached) when a chapter loads and while reading. Pages are requested with the chapter's `imageHeaders`. A downloaded chapter is read from files, online or not. |
| bookmark | Bookmarks tab | `BookmarkCubit` | Search by title. Tabs group by status, source or category (`ScrollableTabs`, "Group by" sheet). Pull-to-refresh checks the comics on screen (§6.1). |
| category | More → Categories; after bookmarking | `CategoryCubit` | §6.2. |
| history | History tab | `HistoryCubit` | Newest chapter per comic, grouped by day. Remove one chapter, one comic, or everything. |
| source | Home/Explore header; More → Extensions | `SourcesCubit`, `ExtensionsCubit` | Source picker, Extensions screen (installed, updates, available by language, repos sheet, languages sheet), WebView screen. §8. |
| settings | More tab | `SettingsCubit` | Theme, clear image cache, bug report link, app info, entry points for the other features. |
| backup | More → Backup / Restore | `BackupCubit` | §7.4. |
| sync | More → sync section | `SyncCubit` | §7.6. |
| download | More → Downloads; detail selection bar | `DownloadCubit` | §7.5. |
| update | On start; More → Check for updates | `UpdateCubit` | §1. |
| migration | More → Backup & sync → Migration; Bookmarks selection bar; comic page | `MatchCubit`, `MihonImportCubit` | §6.4. |

### 6.1 Checking bookmarks for new chapters

Pull-to-refresh on the Bookmarks tab calls `BookmarkCubit.updateBookmarkList` with the slugs on screen: the open group, narrowed by the title search when one is typed. Bookmarks are checked one at a time by `RefreshBookmark`, which loads the comic again. When the chapter count changed, it saves the new details with `updatedDate = now`, which moves the bookmark to the top. A comic that fails to load is left unchanged.

While the run lasts, `ProgressNotifier` (`core/notifications`, Android only) shows an ongoing notification with `done / total`. Refreshing another group during a run adds its bookmarks to the queue and raises the total. At the end the notification is replaced by "Bookmarks updated" with the number of comics that have new chapters, or removed when none have.

The notification has a Cancel button: the tap reaches a background isolate (`progressActionInBackground`), which passes it to the app's isolate through `IsolateNameServer`; `BookmarkCubit.cancelRefresh` abandons the comic being checked and drops the queue. A comic that takes longer than `BookmarkCubit.refreshTimeout` (90 s) is skipped, so one stuck site cannot hold up the run. A notification the user swipes away stays away until the run ends; the run goes on, and the stop button in the Bookmarks header (shown while `BookmarkCubit.refreshing`) cancels it the same way. When a refresh writes imported reading progress (§6.4), `BookmarkCubit.historyChanges` reloads the history right away.

### 6.2 Categories and grouping

Categories are user-made (`LibraryCategory`: id, name, order, `updatedDate`) and managed in More → Categories (create, rename, delete, reorder). A comic can be in any number of categories (`ComicCategories`: comic key → category ids). Bookmarking a comic opens `SetCategoriesSheet` with a Skip button; the sheet also works on several comics at once, where a category only some of them are in starts half-checked and is left alone unless tapped.

The Bookmarks tab groups by `AppSettings.bookmarkGrouping`: status (All / Updated / Completed), source (one tab per source), or category (one tab per category, plus Uncategorized).

### 6.3 One series in two sources

The same title from two sources is two separate comics, because the key includes the source (§8.1). When the user bookmarks a series whose title matches a bookmark from another source (case, spacing and punctuation ignored), `DuplicateSheet` asks whether to move the old bookmark here or keep both. Moving runs `MigrateComic`: the bookmark is replaced, each read chapter moves to the chapter with the same number in the new source (chapters the new source lacks are dropped), and the comic keeps its categories.

### 6.4 Migration

More → Migration has three entries. All of them write through the normal repositories, so sync and the deletion journal see the changes.

- **Migrate source** (`SourceMigrationScreen`): pick the bookmarks (every bookmark of one source, a selection from the Bookmarks tab, or the open comic from its page) and a target source. `MatchScreen` then searches each title in the target, one request at a time and `MatchCubit.gap` (3 s) apart, so sites do not block the user; manual searches from the pick sheet join the same queue. A result whose title equals the bookmark's (`exactMatch`: case, spacing and punctuation ignored, exactly one such result) is picked automatically. The user picks or skips the rest. `MigrateToSource` loads each picked comic and runs `MigrateComic` (§6.3).
- **Import from Mihon / Tachiyomi** (`MihonImportScreen`): reads a `.tachibk` backup (gzipped protobuf, `parseMihonBackup` reads only the fields it needs) and imports the comics in the library (`favorite`), with their category names and the highest chapter number marked read, which waits as a pending read like a Comix row's. Importing the same backup again adds no bookmarks but brings the read chapters to comics imported before. Mihon sources match extensions by name (case, spacing and punctuation ignored); for a multi-language extension the language comes from the Mihon source id, the MD5 of `<name>/<lang>/<versionId>` (`mihonSourceId`). The link becomes a slug through the extension's `urlPatterns` (§8.2), so no script runs and no request is made. Sources without a match are listed as skipped. A matched extension that is not installed can be installed from the screen; its language is turned on.
- **Import from Comix.to** (`MigrationScreen._importComix`): reads the site's CSV export (`parseComixCsv`). It has no Comix links, so `MatchScreen` searches each title in the `comix` source as above (offering `MissingSource` when it is not installed).

Imports run `ImportLibrary`: comics already bookmarked are left alone; new ones are bookmarked with `placeholderDetails` (title only, no cover or chapters, `source` set so the legacy migration (§7.7) leaves them alone), in file order; missing categories are created by name. The last read chapter of a Comix row waits in the `pending_reads` box (local, not synced).

An imported comic gets its details the first time they load from its source: pull-to-refresh in Bookmarks (`RefreshBookmark`, whose chapter count differs from the placeholder's zero) or opening its page (`BookmarkCubit.comicLoaded` → `CompleteImportedComic`, which keeps the bookmark's place). Either way `ApplyPendingReads` then marks every chapter numbered up to the pending one as read (chapters already in the history keep their entry) and removes it.

---

## 7. Storage

### 7.1 Boxes

| Box | Key | Value |
|---|---|---|
| `bookmarks` | comic key | `BookmarkModel` JSON (includes the comic's details) |
| `history_entries` | chapter slug (`<comicKey>/<number>`) | `ReadHistoryModel` JSON |
| `history_comics` | comic key | `HistoryComicModel` JSON (the comic's details) |
| `downloads` | chapter slug | `DownloadedChapterModel` JSON (status, planned and saved page paths, size) |
| `download_comics` | comic key | `DownloadComicModel` JSON (the comic's details, saved cover path) |
| `categories` | category id | `CategoryModel` JSON |
| `comic_categories` | comic key | `ComicCategoriesModel` JSON (category ids of one comic) |
| `library_deletions` | `<kind>:<slug or id>` (`bookmark:`, `history:`, `category:`) | deletion time, epoch ms as a string (`LibraryJournal`, for sync) |
| `sync` | `account`, `lastSyncedAt` | signed-in email; last successful sync in epoch ms |
| `extensions` | extension id | `ExtensionMeta` JSON of the installed extension (§8.2) |
| `extension_storage` | `<sourceId>:<key>` | string an extension saved with `storage.set` |
| `source_settings` | `repos`, `active`, `langs:<extensionId>` | JSON list of repo URLs; active source id; JSON list of enabled languages |
| `pending_reads` | comic key | last read chapter number from an import, until the chapter list loads (§6.4); not synced |
| `settings` | `settings` | `SettingsModel` JSON |

Every box is a `Box<String>` that holds JSON or a plain string. There are no Hive type adapters, so stored data never depends on adapter type ids, and the backup and sync formats can reuse the same JSON. `JsonBox<T>` (`core/storage/json_box.dart`) gives typed `values()`, `get`, `put`, `putAll`, `deleteAll` and `clear`. An entry that fails to parse is skipped and logged, so one bad record cannot hide the rest.

Hive keys must be ASCII and at most 255 characters. Comic keys are `sourceId:slug`, so extensions must return short, URL-safe slugs. Hive stores a key's length in one byte and release builds skip its length check, so a longer key corrupts the whole box file: `JsonBox`, `LibraryJournal` and pending reads skip keys that fail `isValidHiveKey`, and imports skip comic keys longer than `ComicKey.maxLength` (240, room for `/<number>`). Boxes open through `openStringBox`: when Hive cannot read a file, it keeps a copy (`<name>.corrupt-<ms>.hive.bak`), salvages the entries frame by frame (keying a value whose key overflowed by its JSON `slug` or `id`) and writes them to a fresh box, so the app still starts.

Extension scripts are not in Hive: they are files in `<app support>/extensions/<id>.js`. Each source's cookies are in `<app support>/cookies/<sourceId>/`.

### 7.2 Stored JSON shape

```jsonc
// bookmark
{ "slug": "voratoon:solo-leveling", "updatedDate": 1700000000000,   // ms since epoch
  "comicDetails": { "title", "coverImg", "alternativeTitle", "released", "status",
                    "totalChapter", "author", "type", "rating", "synopsis",
                    "genres": [{ "name", "slug" }],
                    "chapters": [{ "number", "slug", "date" }],
                    "source": "voratoon" } }       // absent in data stored before sources
// history entry (one per read chapter)
{ "slug": "voratoon:solo-leveling/2", "chapterNumber": "2", "readDate": 1700000100000,
  "comicSlug": "voratoon:solo-leveling",
  "page": 12, "pageCount": 40 }                    // absent once the chapter is finished
// history comic (one per comic that has history entries)
{ "slug": "voratoon:solo-leveling", "comicDetails": { … } }
// category
{ "id": "…", "name": "Reading", "order": 0, "updatedDate": "2026-10-20T10:00:00.000" }
// comic categories
{ "slug": "voratoon:solo-leveling", "categoryIds": ["…"], "updatedDate": "2026-10-20T10:00:00.000" }
// settings
{ "themeMode": "system", "readingDirection": "vertical", "pageFit": "width",
  "keepScreenOn": true, "pageGap": false, "autoScrollSpeed": 3, "bookmarkGrouping": "status" }
```

Categories store `updatedDate` as an ISO 8601 string; bookmarks and history store epoch milliseconds (`EpochMillisConverter`).

A history entry does not carry the comic's details: they are stored once per comic in `history_comics`, so marking a whole comic as read writes one copy of its chapter list instead of one per chapter. `HistoryRepositoryImpl` joins the two when it reads (entries whose comic record is missing are skipped), writes the latest details it is given, and deletes a comic record once its last entry is removed.

Stored models (`ComicDetailsModel`, `BookmarkModel`, `ReadHistoryModel`, `HistoryComicModel`, `CategoryModel`, `ComicCategoriesModel`, `SettingsModel`) map to and from entities with `fromEntity` and `toEntity`. Entities never carry JSON code. The `ReadHistory` entity still includes `comicDetails`, so the UI does not know about the split.

Library writes made by the user go through `LibraryJournal`, which records deletion times and fires a change event for sync. Sync's own writes go straight to the data sources and are not journaled.

### 7.3 Ordering

Boxes have no order. Repositories sort when they read: bookmarks by `updatedDate` and history by `readDate`, newest first; categories by `order`. Because writes are keyed by slug or id, saving an entry that already exists replaces it.

### 7.4 Backup files

`bacakomik-backup-<y>-<m>-<d>-<h><min><s>.json`, written to a folder the user picks:

```jsonc
{ "version": 2,
  "bookmarks":       [ <bookmark JSON>, … ],
  "history":         [ <history entry JSON>, … ],
  "historyComics":   [ <history comic JSON>, … ],
  "categories":      [ <category JSON>, … ],
  "comicCategories": [ <comic categories JSON>, … ] }
```

Entries are plain JSON objects, in the same shapes as §7.2. The category fields were added without a new version: older app versions ignore them, and a file without them restores with no categories. A file with another `version` (including files from the pre-2026 app, which had none) is rejected with a `FileFailure`. When you change the format, bump `BackupRepositoryImpl.formatVersion` and decide whether to keep reading the previous version.

- **Backup:** if the library is empty, nothing happens and the folder picker does not open. Cancelling the picker does nothing.
- **Restore:** merges into the library. Entries with the same slug (categories: the same id) are replaced. After a restore, the More screen reloads `BookmarkCubit` and `HistoryCubit`.
- Downloads, extensions and source settings are not part of backups.

### 7.5 Downloads

- **Files:** `<root>/<comicKey>/<chapterNumber>/000.<ext>` and `<root>/<comicKey>/cover.<ext>`. Each path segment is made filesystem-safe (characters outside `A-Za-z0-9._-` become `_`, so `voratoon:slug` becomes `voratoon_slug`). The root is `getExternalStorageDirectory()/downloads` on Android (app-specific, no permission, removed on uninstall) and `getApplicationSupportDirectory()/downloads` elsewhere or when external storage is missing. Records store paths relative to the root.
- **Background:** pages are downloaded by `background_downloader` (`PageDownloadQueue`), outside the Dart isolate, so they continue while the app is in the background, the phone is locked, or the process is gone. A native holding queue runs three pages at a time in enqueue order. Each page request carries the chapter's `imageHeaders`. One grouped notification shows `x/y pages`, then done or failed. Notification permission (`POST_NOTIFICATIONS`) is asked on the first download. Each page gets 10 retries with backoff, so short connection drops do not fail a chapter.
- **Blocked image hosts:** some hosts turn the native downloader away the way Cloudflare does. On a page's first retry the queue checks its host once with `imageHostBlocks` (§8.6). If the host blocks, the queue cancels that page's task and saves it, and every later page from that host, through `comicImageCache`, which can fetch from inside the site. This path only runs while the app runs.
- **Preparing:** `DownloadRepositoryImpl` takes queued chapters one at a time, fetches fresh page URLs through `ReaderRepository` (needs a connection), records the planned page paths, and hands the missing pages to the queue. Covers are copied from `comicImageCache` (downloaded first when missing) through a `.part` file. A missing cover does not fail the chapter.
- **Progress:** page events update the record while the app runs. Pages finished while the app was suspended or closed are found on disk: on start and whenever the app resumes (`DownloadCubit` calls `sync()`), downloading chapters are checked against their planned paths. A chapter with no pages left in the queue and pages missing becomes failed. Chapters still waiting for their page list after a restart are prepared again.
- **Status:** `queued → downloading → completed`, or `failed`. Retry keeps saved pages and fetches the rest.
- **Reading:** `GetChapterContent` asks `DownloadRepository.getOfflineChapter` first; a completed chapter with all its files returns `ChapterContent(isOffline: true)` with file paths, and `ChapterImg` shows them with `Image.file`. `GetComicDetails` falls back to `getOfflineComic` when the request fails.
- **Clearing the image cache** does not touch downloads.

### 7.6 Sync

`features/sync` keeps the library in step across devices through one file, `bacakomik-sync.json.gz`, in the app's Drive `appDataFolder` (scope `drive.appdata`; the user cannot see or edit it in Drive). Sign-in uses `google_sign_in`; Drive calls use `filesDio` with the access token.

- **When:** once signed in, `SyncCubit` syncs on start, when the app returns to the foreground (if the last sync is older than a minute), and 5 seconds after the last library edit (`LibraryJournal.changes`).
- **What:** bookmarks, history and categories. Downloads, settings and extensions are not synced.
- **Format:** gzipped JSON, `version: 1` (`SyncRepositoryImpl.formatVersion`): the backup file's library fields (§7.4) plus `deletedBookmarks`, `deletedHistory` and `deletedCategories` (slug or id → epoch ms).
- **Merge** (`SyncSnapshot.merge`): per slug or id the newest version wins (bookmarks by `updatedDate`, history by `readDate`, categories by `updatedDate`). An entry deleted at or after that time is dropped. Deletions older than 180 days are forgotten, so a device offline for longer may bring deleted entries back. A side without the category fields (an older app) keeps the other side's.
- **Flow** (`SyncLibrary`): download, merge with the local library, migrate legacy entries (§7.7), write the result locally, and upload only when the Drive copy differs. A sync that changed local data bumps `SyncState.libraryRevision`, which reloads the library cubits (§4.2).
- Sign-in, Drive 401/403 and token errors become `AuthFailure`.

### 7.7 Library keys and legacy data

Library keys are comic keys (§8.1). Keys without a prefix belong to `ComicKey.defaultSource` (`bacakomik`), which is what every key stored before sources existed looks like.

Those older entries came from the previous API, whose comics now live in the `voratoon` source (`ComicSource.legacy`). `MigrateSnapshot` moves every default-source entry whose details have no `source` (or `source: "voratoon"`) to `voratoon:<slug>` keys, rewrites its chapter slugs, and records deletions for the old keys so un-migrated devices drop them on the next sync merge. It runs inside sync when signed in, and through `MigrateLocalLibrary` on start and resume when signed out. No request is made.

---

## 8. Sources and networking

### 8.1 Sources and comic keys

A **source** is one site the app reads comics from. Each source is backed by an installed **extension**: a JavaScript file that implements the extension contract. A multi-language extension (for example MangaDex) is one source per enabled language.

Comics are addressed by a **comic key** (`ComicKey`, `core/source/comic_key.dart`): `sourceId:slug`, or the bare slug for the default `bacakomik` source. The app stores and passes keys wherever it used to pass a series slug (library, history, downloads, routes), so the same title from two sources stays two separate entries. Chapter slugs are `<comicKey>/<number>`.

`SourceRegistry` (implemented by `ExtensionManager`) is what the data layer sees: `activeSource` (the one Home and Explore show) and `backend(sourceId)`, which returns a `SourceBackend` with `features()` and `call(method, args)`. `SeriesRemoteDataSource` is the only class that calls source methods:

| Method | Source call | Returns |
|---|---|---|
| `getSeriesList` | `browse({page, limit, query, filters})` | `{ items: [series] }` |
| `getSeries` | `series(slug)` | series details |
| `getChapters` | `chapters(slug)` | `[{ number, createdAt }]` |
| `getChapter` | `chapter(slug, number)` | `{ number, title, prev, next, images, headers }` |

Extensions may also define `filters()` (filter groups for Explore), a `home` object (`featured` and `latest` filter values for Home) and `webUrl(slug)` (the series page on the site). The full contract lives in the private `bacakomik-ext-source` repo (`types/bridge.d.ts`). DTOs (`SeriesResponse`, `SeriesDetailResponse`, `ChapterResponse`, `ChapterDetailResponse`) convert to entities with `ApiFormat`. Examples: `rating 9.25` becomes `"9.3"`, `number 1.5` becomes `"1.5"`, a missing format becomes `"-"`, and `createdAt` becomes "3 h ago". `getSeriesList` and `getSeries` turn the slugs a source returns into comic keys, so callers never see bare source slugs.

The active source is picked in the source picker on Home and Explore. Without a saved pick it is `bacakomik` when installed, else the first installed source. With no source installed, Home and Explore fail with `noSourceMessage`, and `SourceError` leads to Extensions.

### 8.2 Extensions and repos

`ExtensionManager` (`core/source/extension_manager.dart`) owns installed extensions, the repos they come from, and their loaded runtimes.

- **Repos** are `index.json` URLs: `{ name, extensions: [ExtensionMeta…] }`. The list is in `source_settings` → `repos`; without a saved list it is `ExtensionManager.defaultRepo`, `https://bacakomik-ext.kurodev.org/index.json`. That is the built `dist/` of the private `bacakomik-ext-source` repo, served by a Cloudflare Worker. Users can add and remove repos in the repos sheet; `addRepo` fetches the URL first and rejects anything that is not a repo index.
- **`ExtensionMeta`** (`extension_meta.dart`) fields: `id` (lowercase, `[a-z0-9_-]`; becomes the file name and the key prefix), `name`, `lang` (ISO 639-1, or `all`), `version` (semver `major.minor.patch`; an integer from older builds reads as `N.0.0`), `apiVersion`, `baseUrl` (shown as the domain), `file` (relative to `index.json`), `sha256`, `nsfw`, `languages` for multi-language extensions, and optional `urlPatterns`: regexes whose one capture group is the slug in a series URL path (`ExtensionMeta.slugFromUrl`), used to import Mihon backups without running the script (§6.4). The app implements `supportedExtensionApi = 1`; an extension with a higher `apiVersion` is listed but cannot be installed.
- **Install / update:** `install` downloads `file`, checks it against `sha256`, loads it once in a throwaway runtime (a script that does not load is not installed), then writes `<app support>/extensions/<id>.js` and the meta to the `extensions` box. Updating is installing the newer version. `catalog()` fetches all repos in parallel; a failing repo is returned as an error entry so the others still show. It also refreshes `updateCount` (badge on More → Extensions).
- **Uninstall** deletes the script and meta, the enabled-languages setting, and for every source of the extension its cookies, stored values and hidden page.
- **Bundled extensions:** `assets/extensions/index.json` and `assets/extensions/extensions/*.js` (currently `bacakomik` and `voratoon`) are installed on first run, and again whenever the app bundles a newer version, so the app works before any repo is reachable. They are produced by `bun scripts/bundle.ts` in the extension repo (CONTRIBUTION §2).
- **Multi-language extensions:** each enabled language is its own source with id `<extensionId>-<lang>` and name `<Name> (<LANG>)`, so its comics, bookmarks and history are separate. Enabled languages are stored as a JSON list in `source_settings` → `langs:<extensionId>`; the default is English, else the first language. Comics of a language that was turned off still open (`ExtensionManager.meta` resolves every known source).

The `bacakomik` extension is a thin wrapper over the project's own bacakomik-api (`https://api-bacakomik.kurodev.org`, which serves bacakomik.my). The app no longer calls that API directly.

### 8.3 Extension runtime

`ExtensionRuntime` (`extension_runtime.dart`) runs one source in its own `flutter_js` engine (QuickJS on Android). Loading evaluates:

1. a prelude that defines the host globals: `http.fetch(req)`, `html.select(source, selector)`, `storage.get(key)` / `storage.set(key, value)`, `webview.run(url, script, ...args)`, `log(...)`, `qs(params)` and `defineExtension(ext)`;
2. `var source = { id, lang }`, so a multi-language script knows which language it runs as;
3. the extension script, which must call `defineExtension` once.

Calls are asynchronous in both directions. A host call from JS returns a promise kept by id; Dart runs the call and settles it with `__bkSettle`. A method call from Dart runs `__bkInvoke`, and the result comes back on the `bk_result` channel. Host calls run outside the JS call that sent them, because the engine is not re-entrant.

A method call fails with "did not respond" after **45 seconds without progress**: no host function running and none starting or finishing. A long run of host calls (a chapter list read page by page in a WebView) is not cut off. Script errors whose message starts with `404` become a `ServerException` with status 404.

`features()` calls `filters()` once (when defined) and combines it with `home` into `SourceFeatures`; a failed load is retried next time.

### 8.4 Host side

`ExtensionBridge` (`extension_bridge.dart`) handles the host functions. Everything is per source id.

- **`http.fetch`:** one Dio per source with a persistent cookie jar (`PersistCookieJar` in `<app support>/cookies/<sourceId>/`). On Android and iOS it uses `NativeAdapter` from `native_dio_adapter` (Cronet on Android, NSURLSession on iOS), because Cloudflare turns away the TLS fingerprint of `dart:io` even with a valid `cf_clearance`. Requests send a Chrome-on-Android User-Agent unless the script overrides it. Any status is returned to the script (`{status, url, headers, body}`); the script decides what is an error.
- **Connection retries:** connection errors (TLS handshake, reset, refused, Cronet `net::ERR_*`) are retried up to three attempts with a short backoff, then fail with `AppText.connectionFailed` ("Couldn't connect to <host>…"). Some networks intercept connections now and then; a later attempt often goes through.
- **Cloudflare challenges:** a response with `cf-mitigated: challenge`, or a 403/503 from a Cloudflare server whose body is a challenge page, throws `ServerException("challenge: <url>")` (`Challenge.message`). `SourceError` sees the prefix and offers "Verify in WebView" (§8.5).
- **`html.select`** parses the HTML with `package:html` and returns `{text, html, outerHtml, attrs}` for every match.
- **`storage.get` / `storage.set`** read and write strings in `extension_storage` under `<sourceId>:<key>`.
- **`webview.run`** goes to `HeadlessPages` (§8.5).

### 8.5 WebViews

**Hidden pages** (`HeadlessPages`, `headless_pages.dart`) serve `webview.run`, for sites that only answer a real browser. Each source gets one hidden `HeadlessInAppWebView`, kept for 3 minutes after its last run so the site does not load again each time. Runs of one source go one at a time.

- The page loads the URL (25 s timeout) unless it already shows it. While its title contains "Just a moment", it waits up to 20 s for Cloudflare's check to solve itself; a check that needs the user becomes a `Challenge` error.
- The script runs as the body of an async function in the page (`callAsyncJavaScript`) with a **3-minute timeout**, long enough for a script that walks a long chapter in the site's reader. After a run the page's cookies are copied into the source's cookie jar.
- A run that fails (a check that needs the user, a page that did not load, a script error) closes the page, so the next run loads a fresh one with the cookies the user got in the visible WebView instead of reusing a page still on the check. A kept page that shows "Just a moment" is reloaded too. Runs queue per source, and each takes the page that exists when it starts.
- Popups are refused, and main-frame navigation to another host is cancelled (subdomains and `challenges.cloudflare.com` are allowed), so ads cannot take the page away.
- **Rendering:** a hidden WebView inside the Flutter view runs no rendering steps, so `requestAnimationFrame`, `IntersectionObserver` and scrolling never fire and lazy-loading pages load nothing. After creating a page, Dart calls `render` on the `bacakomik/hidden_webviews` method channel. `MainActivity.kt` then finds invisible views that hold a `WebView`, moves each into an `Untouchable` frame (which passes every touch through), sets alpha 0 and makes it visible. Chromium then renders the page like one on screen, and the user cannot see or touch it.

**WebView screen** (`features/source/presentation/pages/web_view_screen.dart`) shows a source's site to the user, with the extension's User-Agent. `SourceError` opens it on a challenge URL; the comic page opens it on the series (`webUrl`). After every page load it copies the WebView's cookies (for example `cf_clearance`) into the source's cookie jar, and the failed screen retries when it closes. It can also clear the source's cookies.

### 8.6 Images

`comicImageCache` (`core/network/image_cache.dart`) is the one `CacheManager` for covers, reader pages, the reader's prefetch, download covers and blocked-host pages. It keeps `DefaultCacheManager`'s key, so images cached by older versions stay.

- On Android its file service downloads through Cronet (`cronet_http`; plain `dart:io` when no Cronet provider exists) with the headers Chrome sends for an `<img>` request, plus the cookies the WebViews hold for that host. The reader passes the chapter's `imageHeaders` (for example a `Referer`) with every page request.
- A host that answers 403 or 503 is fetched inside a hidden page for that host (`fetch` with `credentials: 'include'`, bytes returned as base64) for the next 30 minutes, without trying the direct request first.
- `imageHostBlocks(url, headers:)` runs the same check for other downloaders; the download queue uses it (§7.5).

### 8.7 `runRemote`

```dart
runRemote(networkInfo, () async { … })
```

1. Without a connection, returns `NetworkFailure` and makes no request.
2. Otherwise runs the call. `ServerException` becomes `ServerFailure(message)`, and any other error becomes `ServerFailure(e.toString())`.

When one call makes several requests in parallel, use `Future.wait` so the first error fails the whole call. Do not use the record `.wait` extension: it wraps errors in `ParallelWaitError`.

### 8.8 Other HTTP

`filesDio` (`register_module.dart`: no base URL, 15 s connect, 2 min receive) fetches repo indexes and extension scripts, talks to the Drive REST API (§7.6), and backs `ApiClient`, which reads the latest GitHub release for in-app updates.

---

## 9. Errors and logging

- **Data layer** throws `ServerException` (optionally with a `statusCode`) or `CacheException`, or lets library errors through. Source errors arrive as `ServerException`: a script error, "did not respond", a challenge (`challenge: <url>`), or a missing source.
- **Repositories** catch everything and return `Left(Failure)`: `ServerFailure`, `NetworkFailure`, `CacheFailure`, `FileFailure` or `AuthFailure` (sync sign-in).
- **Blocs** map `NetworkFailure` to a `noInternet` state, which shows `EmptyState.offline`. Other failures become `error(message)`, shown by `SourceError`: a challenge offers "Verify in WebView" and retries when the WebView closes; no installed source leads to Extensions; anything else shows the message with a retry button. Library cubits log failures with `debugPrint` and reload. Backup failures show a snackbar.
- Use `debugPrint` for logging, never `print`. Extension `log()` calls print as `[<sourceId>] …`. Never log full backup or sync contents.

---

## 10. Code generation

`build_runner` generates:

- `*.freezed.dart` (freezed) and `*.g.dart` (json_serializable) next to their sources.
- `lib/core/di/injection.config.dart` (injectable).
- `lib/core/assets/assets.gen.dart` and `fonts.gen.dart` (flutter_gen).

Generated files are committed and excluded from analysis (`analysis_options.yaml`). `build.yaml` turns on `explicit_to_json` so nested models are written as maps.

### 10.1 Version pins

- `freezed: ">=4.0.0 <4.0.2"`. freezed 3.x generates `final` constructor parameters, which Dart 3.13 rejects. 4.0.2 and later need a newer `test` than the one `flutter_test` pins.
- `hive_ce_generator` is intentionally **not** a dependency. Boxes store JSON strings (§7.1), and the generator's analyzer range conflicts with freezed.

Upgrade these together, in their own PR, and run the full test suite after code generation.

---

## 11. Feature summary

| Area | Status |
|---|---|
| Sources as installable JS extensions, multiple repos, updates | Done |
| Multi-language extensions (one source per language) | Done |
| Cloudflare: WebView verification, hidden WebViews, browser-like images | Done (Android) |
| Home (featured, latest, last read) per source | Done |
| Latest, search, explore with the source's filters | Done (10-page cap on Latest) |
| Comic detail, mark chapters read/unread, open in WebView, share links | Done |
| Reader (prev/next, zoom, auto-scroll, resume position, save image) | Done |
| Bookmarks: grouping by status/source/category, "new chapters" refresh | Done |
| Custom categories | Done |
| Move a comic between sources | Done |
| History | Done |
| Theme setting (system/light/dark) | Done |
| Backup / restore | Done |
| Google Drive sync | Done |
| Offline reading (chapter downloads) | Done (background downloads on Android) |
| In-app updates from GitHub Releases | Done |
| Migrate source (one or many), import from Mihon/Tachiyomi and Comix.to | Done |

---

## 12. Open questions

- **Formatting:** the code base predates the current `dart format` style. Reformatting everything in one commit would be a large, noisy diff. Decide whether to do it once.
