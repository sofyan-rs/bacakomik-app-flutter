# Architecture

How the app is built. Read it once before a non-trivial change. For step-by-step tasks (add a screen, release, test on a phone), use [CONTRIBUTION.md](CONTRIBUTION.md).

§ numbers refer to this file; "CONTRIBUTION §n" to the other one.

## The big picture

```
  extension repo                    the app on the phone                       user's Drive
┌──────────────────┐  install  ┌───────────────────────────────────────────┐  sync  ┌──────────────┐
│ index.json       │ ────────► │ ExtensionManager ─► ExtensionRuntime (JS)  │ ◄────► │ appDataFolder │
│ <id>.v1.2.0.js   │           │                          │                 │        │ one .json.gz  │
└──────────────────┘           │ screens ─► blocs ─► use cases ─► repos     │        └──────────────┘
                               │                                  │         │
  comic sites  ◄── http.fetch / hidden WebView ──────────────────┘         │
                               │                  Hive boxes (library) ◄────│
                               └───────────────────────────────────────────┘
```

- The app has **no content of its own**. Each site is a **source**, backed by a small JavaScript **extension** downloaded from a repo (§8.2) and run in an embedded JS engine on the phone (§8.3), or, on Android 9+, by a **Mihon extension** APK run in Kotlin (§8.9).
- Screens talk to blocs, blocs call use cases, use cases call repositories. Only repositories know about sources, HTTP and storage (§3).
- The library (bookmarks, categories, history, downloads, settings) lives **on the phone** in Hive (§7). It can be exported to a backup file (§7.4) or synced through one private file in the user's own Google Drive (§7.6). There is no BacaKomik account or server.

---

## 1. Goals and non-goals

**Goals**
- **Never lose the user's library.** It survives updates; backups and sync restore it. Storage started fresh with the 2026 rewrite: pre-2026 data and backup files are not read.
- **Testable logic.** Domain code is plain Dart; repositories and blocs are tested without a device, with fake sources (CONTRIBUTION §5).
- **Clear layers** (§3) and **no site code in the app**: a site change ships as an extension update.
- Phones and wide screens: floating pill nav on every width, cover grids add columns.

**Non-goals**
- An account or server-side library. Sync only uses the user's Drive (`drive.appdata`).
- Hosting comics. Extensions read the sites; the app only gives them host functions (§8.4).
- iOS. The code mostly runs there (JS extensions only, §8.9), but background downloads, hidden-WebView rendering (§8.5) and notifications are Android-only or untested, and download paths are absolute (§7.5).
- An app store. Releases are APKs on GitHub Releases; the app checks for a newer one on start and in More, downloads the APK for its ABI and opens the installer (`features/update`, `ota_update`). Asset names and the `## Which APK?` heading come from the release workflow (CONTRIBUTION §2).

---

## 2. Tech stack

| Concern | Choice | Notes |
|---|---|---|
| UI | Dart 3.13, Flutter stable | Material 3 themed as Dotline (§5); Geist, Geist Mono, Doto fonts; Lucide icons |
| State / DI / errors | `flutter_bloc`, `get_it` + `injectable`, `fpdart` | `Either<Failure, T>` from repositories (§9) |
| Models | `freezed`, `json_serializable` | Stored models use `@JsonSerializable` (§7.2) |
| Sources | `flutter_js` | One QuickJS engine per source (§8.3); `crypto` checks script `sha256` |
| Mihon sources | `android/mihon` module (Kotlin) | Mihon's source API and SCANCORE's host, vendored; OkHttp 5, Jsoup, RxJava, Injekt, QuickJS (§8.9) |
| Source HTTP | `dio` + `native_dio_adapter` (Cronet), `cookie_jar`, `html` | One cookie jar per source (§8.4) |
| WebViews | `flutter_inappwebview` | Hidden pages and the visible WebView screen (§8.5) |
| Images | `cached_network_image`, `flutter_cache_manager`, `cronet_http` | `coverImageCache` + `comicImageCache` (§8.6) |
| Other HTTP | `dio` (`filesDio`) | Repos, scripts, Drive, GitHub releases (§8.8) |
| Storage | `hive_ce` | JSON strings, no adapters (§7) |
| Downloads | `background_downloader` | Outside the Dart isolate (§7.5) |
| Notifications | `flutter_local_notifications` | Bookmark refresh progress with Cancel (§6.1); needs `ActionBroadcastReceiver` in the manifest |
| Sync / backup | `google_sign_in` + Drive REST; `file_picker` | §7.6, §7.4 |
| Links, share, gallery | `app_links`, `share_plus`, `gal` | Links `https://bacakomik.kurodev.org/series/<slug>` open the app (`DeepLinks`, host in `hosting/worker`) |
| Tests | `flutter_test`, `bloc_test`, `mocktail` | CONTRIBUTION §5 |

Versions are in `pubspec.yaml`; read §10.1 before touching `freezed` or the generators. App id `org.kurodev.bacakomik`; `minSdk` 24, `targetSdk` 36 (from Flutter), `compileSdk 37`, Java 17.

---

## 3. Project structure

| Path | What it is | Do you edit it? |
|---|---|---|
| `lib/main.dart` | `Hive.init` → DI → bundled extensions → `runApp` | Rarely |
| `lib/app/` | `BacaKomikApp` (app-wide providers, listeners, theme), splash, `RootScreen` (5 tabs, update check), `RootTabs` | When wiring several features together |
| `lib/core/` | Shared code: `constants/` (`AppText`), `theme/`, `di/`, `error/`, `network/`, `notifications/`, `source/` (§8), `storage/` (§7), `usecase/`, shared `domain/`, `data/`, `presentation/` widgets, `utils/` | When something is shared |
| `lib/features/<name>/` | One folder per feature (table below) | Yes, most work |
| `*.freezed.dart`, `*.g.dart`, `injection.config.dart`, `core/assets/*.gen.dart` | Generated (§10) | No |
| `assets/extensions/` | Bundled extensions (§8.2) | Only via `bundle.ts` (CONTRIBUTION §2) |
| `android/…/MainActivity.kt` | `bacakomik/hidden_webviews` channel (§8.5); registers `MihonChannel` (`bacakomik/mihon`); asks for the display's fastest mode at its resolution (`preferredDisplayModeId`), as some phones keep apps at 60 Hz otherwise | Rarely |
| `android/mihon/` | Runs Mihon extension APKs (§8.9) | When Mihon's API or a host call changes |
| `android/app/src/main/AndroidManifest.xml` | Permissions, deep links, notification action receiver | Rarely |
| `hosting/` | Cloudflare Worker for `bacakomik.kurodev.org` | Rarely |
| `test/` | Mirrors `lib/` | Yes |

Features: `home`, `latest` ("See all"), `explore`, `comic_detail`, `reader`, `bookmark`, `category`, `history`, `settings` (More tab), `backup`, `sync`, `download`, `migration`, `source` (Extensions, source picker, WebView screen), `update`.

Each feature has up to three layers (only the ones it needs):

```
features/<name>/
├── domain/        entities (freezed) · repositories (interfaces) · usecases
├── data/          datasources · models (JSON on disk/wire) · repositories (*Impl, @LazySingleton(as: …))
└── presentation/  bloc · pages · widgets
```

**Dependency rules:** `presentation ──▶ domain ◀── data`.
- **domain** imports no `data`, `presentation`, Flutter, Dio, Hive or file_picker. It may use `fpdart`, `freezed_annotation`, `injectable`, plain-Dart `core` helpers (`ComicKey`) and other features' domain code.
- **data** may import other features' data models when a format is shared (`backup` and `sync` read `BookmarkModel`).
- **presentation** reaches use cases through blocs; widgets may read other features' cubits (`comic_detail` reads `BookmarkCubit`).
- **core** never imports `features/` (except generated DI). Cross-feature wiring lives in `lib/app/`.

Check the domain rule; **it must print nothing**:

```bash
grep -rn "^import" lib/core/domain lib/features/*/domain | grep -E "package:flutter|/data/|/presentation/|hive|dio|file_picker"
```

**Rules for adding code**
1. Group by feature, then layer. Only shared things go in `core/`.
2. One main type per file, named after it (`bookmark_cubit.dart` → `BookmarkCubit`); related use cases may share a file.
3. Use cases are thin; real rules live in the domain (`RefreshBookmark`, `MigrateComic`) so they can be tested.
4. Repositories return `Either`, via `runRemote` / `runLocal` (§8.7, §9).
5. Register with injectable: `@injectable` for use cases and blocs, `@LazySingleton(as: Interface)` for repositories and data sources.
6. Keep files under ~400 lines.

| I'm writing… | Put it in |
|---|---|
| A rule about comics, bookmarks, history | That feature's `domain/`, with a test |
| Support for a new site | An extension in `bacakomik-ext-source`, not here |
| A new source method | The contract in `bacakomik-ext-source`, then `SeriesRemoteDataSource` + a DTO in `core/data/models/` |
| A new host function | `ExtensionBridge.handle` + the prelude in `ExtensionRuntime` (bump `supportedExtensionApi` if old apps can't run it) |
| Data stored on the device | A feature `*_local_data_source.dart` over a `JsonBox` (§7) |
| A widget used by several features | `core/presentation/widgets/` |
| A UI string | `AppText` in `core/constants/texts.dart` |

---

## 4. Runtime model

```
main() ─ Hive.init ─ configureDependencies() (opens boxes) ─ installBundled() ─ runApp ─ catalog() (background)

Bloc/Cubit ─▶ UseCase ─▶ Repository ─▶ RepositoryImpl
                                        ├─ SeriesRemoteDataSource ─▶ SourceRegistry (ExtensionManager)
                                        │     └─ ExtensionRuntime (QuickJS) ─▶ ExtensionBridge ─▶ Dio (Cronet) / HeadlessPages
                                        └─ *LocalDataSource ─▶ JsonBox ─▶ Hive box
```

### 4.1 Startup
1. `Hive.init` uses the app documents directory.
2. `configureDependencies()` registers everything and opens the fourteen boxes (§7.1) before returning (`@preResolve` in `StorageModule`); the first box asked for opens all of them in parallel (`Future.wait`), so file reads overlap.
3. `ExtensionManager.installBundled()` installs or upgrades the bundled extensions (§8.2).
4. `runApp` shows `SplashScreen` for 2 s. Library cubits (`BookmarkCubit`, `CategoryCubit`, `HistoryCubit`, `SettingsCubit`, `DownloadCubit`) are non-lazy and `load()` when created, so the library loads during the splash. `SourcesCubit` and `SyncCubit` are eager too; `SyncCubit.start()` restores the Google account and syncs.
5. `RootScreen` holds the tabs in a `LazyIndexedStack` (`lib/app/lazy_indexed_stack.dart`): a tab is built on its first visit, then kept alive. Startup builds and loads only Home.
6. `ExtensionManager.catalog()` fetches the repos in the background for the update badge.

### 4.2 Bloc scope
- **App scope** (`lib/app/app.dart`): `HomeBloc`, `ExploreBloc`, `FilterCubit`, `SourcesCubit`, the library cubits, `BackupCubit`, `SyncCubit`, `UpdateCubit`. They outlive navigation.
- Two app-level listeners: a new active source resets `FilterCubit` and reloads `HomeBloc`; a new `SyncCubit.libraryRevision` reloads the bookmark, category and history cubits.
- **Route scope:** `LatestBloc`, `ComicDetailsBloc`, `ReaderBloc`, `ExtensionsCubit` are created by their screen (`BlocProvider(create: (_) => getIt<…>())`). The public screen is a thin wrapper over a private view (`_ComicDetailsView`), so each opening starts fresh.

### 4.3 State shapes
- Remote screens: freezed sealed `initial / loading / loaded / error / noInternet`; widgets test `state is HomeLoaded`; errors render `SourceError` (§9).
- Paginated lists share `ComicListState` and the `ComicListLoader` mixin (`loadFirstPage`, `loadNextPage`). Next page is ignored until the first loaded; `ComicListLoaded.isLoadMore` is true while loading.
- Library cubits hold plain lists or `AppSettings`. `HistoryCubit` and `BookmarkCubit` update their list in memory after their own writes, to exactly what a reload would read (dates to the millisecond, ties by slug; a failed write reloads); the other cubits reload after every write. `load()` is for changes made elsewhere (sync, import, restore, migration); a `load()` that read the boxes before an in-memory edit landed reads again. `HistoryCubit.index` (`HistoryIndex`) is built in full on first use and after `load()`; the cubit's own edits patch it in place (`applySaved`, `applyRemoved`, `applyRemovedComics`, `applyCleared`), touching only the edited comics.
- `SourcesState` mirrors `ExtensionManager`: installed and known sources (incl. languages turned off), active source and its `SourceFeatures`, update count.
- Events are `final class`es named after what happened (`HomeStarted`, `ChapterRequested`).

### 4.4 Settings
`AppSettings`: `themeMode` (`system | light | dark`), reader settings (`readingDirection`, `pageFit`, `keepScreenOn`, `pageGap`, `progressBar`, `infiniteScroll`, `autoScrollSpeed`), `incognito` (the reader saves no history while on; marking chapters read still does), `kururinSound` (Home's pull-to-refresh sound; the spin shows either way), `bookmarkGrouping` (`status | source | category`), `bookmarkSort` (`updated | title | chapters | latestChapter | added | lastRead`) and `bookmarkSortDirection` (`ascending | descending`; default `updated` descending = repository order). `SettingsModel` defaults every field and tolerates unknown enum values, so new fields never break loading. Source settings live in the `source_settings` box, not here.

---

## 5. Theme and UI

**Dotline** is a monochrome, dark-first design system: pure black (light: `#F2F2F2`), flat surfaces, hairlines, pills, dots.

- **Red is a signal, not a colour.** `accent` at most once or twice per screen (NEW dot, `+N` badge, delete). Selected chips and switches use `ink`.
- **Doto only for screen titles** and the app name, never under 24 px. Numbers use `DotlineText.stat` / `statS`; labels use uppercase Geist Mono.
- **No gradients or glass**, except the bottom fade behind the nav. Depth is `bg` → `surface` → `surfaceRaised`; `shadowFloat` only for menus and the reader's chapter pill.
- **Comic types are labels, not colours** (same black pill for all).
- **Motion:** 140 ms presses (scale 0.97, no ripple), ~320 ms sliding indicators; respect `MediaQuery.disableAnimationsOf`.
- Tokens in `core/theme/` (`Dotline.of(context)`, `DotlineText`, `DotSpace`/`DotRadius`/`DotSize`/`DotMotion`). Build screens from `core/presentation/widgets/dotline/` (`ScreenHeader`, `ListGroup`/`ListRow`, `DotButton`, `showDotSheet`, `ComicCover`, `EmptyState`…); taps scale through `Pressable`.
- Icons: `LucideIcons300` only, no Material `Icons`.
- Text: English, in `AppText`. The library is **"Bookmarks"**, never "Favorites". Home's second list (and its "See all" screen) is **"Latest updates"**. Source text is shown as sent.
- Tabs get the nav height as bottom padding; scrollables add `MediaQuery.paddingOf(context).bottom`. Cover grids: 3 columns on phones, more on wide screens (~150 dp cells). Home's pull-to-refresh plays "kuru kururin".

---

## 6. Features

| Feature | Entry | Bloc | Behaviour |
|---|---|---|---|
| home | Home tab | `HomeBloc` | Two parallel `browse` calls: slider with `home.featured` (10) and "Latest updates" with `home.latest` (20), titles and slider visibility from `SourceFeatures` (Mihon, §8.9); last read comic; cards leave out an unknown latest chapter (and the grid shrinks its cells when no comic has one); header opens the source picker |
| latest | "See all" | `LatestBloc` | Infinite scroll, up to 10 pages |
| explore | Explore tab | `ExploreBloc`, `FilterCubit` | `ExploreFilter` (source, query, values per group) goes to one `browse`. Sheet built from `filters()`; a `quick` group shows above the grid. Changing source resets it. Groups over 14 options show 12 (plus any picked) and "Show all"; a `sort` group (Mihon) is one chip per field, tapped again to turn the direction. Genre chips on a comic page open Explore with that genre alone (`FilterCubit.showGenre`) when the source has a matching filter (`SourceFeatures.genreFilter`: the `genre` group's id, else an option with that name); otherwise they are plain labels. Requests run in order. The tab is built (and first asks its source) on its first visit, which may be Home's search button (focuses the field) |
| comic_detail | Card tap, shared link | `ComicDetailsBloc` | Series and chapters in parallel; the details show as soon as they come (`loaded(chaptersLoading: true)`: count `…`, a loader for the list, no bottom bar) while a slow chapter list loads; bookmark (then categories, §6.2), continue, WebView, share, multi-select to download or mark read. Offline: opens from stored details (downloads, bookmarks, history). Missing source: `MissingSource` offers to install it. Stat tiles: chapters, release year and status, each only when known; the rating follows the source line |
| reader | Chapter tap | `ReaderBloc` | Chapter slug `<comicKey>/<number>`; prev/next replace the route; writes history with the page reached; uses `imageHeaders`; downloaded chapters read from files. With `infiniteScroll` (vertical only) the list holds several chapters (`_Segment`s): the next joins the end when the last 3 pages are reached, the previous joins the top when scrolled past the first page (the list is rebuilt at the item on screen, as inserting shifts every index); title, page meter and history follow the chapter on screen, the one left saved where it was left. "Back to series" pops to the comic page, or opens it when the reader came from Downloads (`fromSeries`) |
| bookmark | Bookmarks tab | `BookmarkCubit` | Search, group tabs (§6.2), refresh (§6.1) |
| category | More → Categories | `CategoryCubit` | §6.2 |
| history | History tab | `HistoryCubit` | Newest chapter per comic by day; remove one, a comic, or all |
| source | Header; More → Extensions | `SourcesCubit`, `ExtensionsCubit` | §8. Extensions: Installed / Available tabs with search, a language sheet (counts, Indonesian and English first) and Hide 18+ (on by default); icons from the repo (`ExtensionIcon`, cached with covers; no icon → first letter), `18+` in red; Mihon settings button (§8.9) |
| settings, backup, sync, download, update | More | own cubits | §4.4, §7.4, §7.6, §7.5, §1 |
| migration | More → Backup & sync → Migration; Bookmarks selection; comic page | `MatchCubit`, `MihonImportCubit` | §6.4 |

### 6.1 Checking bookmarks for new chapters
1. Pull-to-refresh calls `BookmarkCubit.updateBookmarkList` with the comics **on screen** (open group, narrowed by search). Pulling in another group during a run adds to the queue.
2. `BookmarkRefreshQueue` checks up to 3 comics at once, at most 1 per source (a site may block a burst). `RefreshBookmark` fetches the chapter list first, and the series details only when the count changed or the bookmark is an imported placeholder. A changed count saves the new details with `updatedDate = now` (moves it to the top). A failure leaves it unchanged and logs `Refresh <key>: <failure>`.
3. `ProgressNotifier` (Android) shows `done / total`, then "Bookmarks updated" with the count, or nothing.

| Stop | How |
|---|---|
| Cancel in the notification | Reaches `progressActionInBackground` in a background isolate, which forwards via `IsolateNameServer`; `BookmarkCubit.cancelRefresh` drops the queue. **Needs `ActionBroadcastReceiver` in `AndroidManifest.xml`** |
| Stop button in the Bookmarks header | Shown while `BookmarkCubit.refreshing`; same cancel |
| A comic over `refreshTimeout` (90 s) | Skipped, so one stuck site can't block the run |
| Notification swiped away | Stays away; **the run continues** |

A comic abandoned (stop, timeout, bookmark removed) has its `RefreshCancelToken` cancelled and writes nothing more; a request already sent may still finish, and a result whose write had begun arrives `late` so the screen shows it. Comics pulled after a Stop, or while a run is ending, get a run of their own.

Imported reading progress written during a refresh (§6.4) reloads the history at once through `BookmarkCubit.historyChanges`.

### 6.2 Categories and grouping
User-made `LibraryCategory` (id, name, order, `updatedDate`), managed in More → Categories. A comic can be in many (`ComicCategories`: key → ids). Bookmarking opens `SetCategoriesSheet` (skippable; with several comics, partly-applied categories start half-checked and stay unless tapped). Bookmarks group by status (All / Updated / Completed), source, or category (+ Uncategorized).

### 6.3 One series in two sources
Keys include the source (§8.1), so `source-a:some-title` and `source-b:some-title` would be two bookmarks. Bookmarking a title that matches one from another source (case, spacing, punctuation ignored) opens `DuplicateSheet`: move or keep both. Moving runs `MigrateComic`: replaces the bookmark, moves each read chapter to the same number in the new source (missing ones dropped), and joins both comics' categories.

### 6.4 Migration
Three entries under More → Migration. **All write through the normal repositories**, so sync and the journal see them.

| Entry | Input | How comics are found |
|---|---|---|
| Migrate source (`SourceMigrationScreen` → `MatchScreen`) | Bookmarks of one source, a selection, or the open comic | Title search in the target; then `MigrateToSource` runs `MigrateComic` (§6.3) |
| Mihon / Tachiyomi (`MihonImportScreen`) | `.tachibk` (gzipped protobuf, `parseMihonBackup`) | The backup link, read with the extension's `urlPatterns` (§8.2), or by source id for Mihon extensions (§8.9); no request. JS first when both match; comics the JS source can't read go to the Mihon one (a second group, "<name> (Mihon)") |
| Reading-list CSV (`MatchScreen`) | A site's CSV export (`parseComixCsv`), no links | Title search in that site's source (`MissingSource` if not installed) |

- **Title search** (`MatchCubit`): one request at a time, `gap` 3 s apart, manual searches join the queue. A single result with the same normalized title is picked automatically (`exactMatch`); failing that, a single result whose title or `altTitles` (sent in `browse` by some extensions) equals the comic's title or one of its alternative titles. When the title finds nothing, up to `maxAltQueries` (2) alternative titles of a migrated comic are searched, Latin ones first (`altQueries`). The user picks or skips the rest.
- **Mihon:** only library comics (`favorite`), with category names and their chapters (`BackupChapter`: url, read, dates, number; `BackupHistory` field 104, legacy 102, for read dates). `importChapters` keeps numbered chapters, one per number, newest first; a read chapter takes its Mihon history date, others are placed 1 ms around the nearest dated one (or Mihon's fetch date) so the newest read chapter is the latest. Half-read pages are skipped. Sources match by name; a multi-language extension's language comes from the Mihon source id (MD5 of `<name>/<lang>/<versionId>`, `mihonSourceId`). Unmatched sources are listed as skipped; a matched but missing extension can be installed from the screen (its language is enabled). Re-importing adds no bookmarks but brings read chapters to earlier imports.
- **`ImportLibrary`:** an existing key is left alone; a title already bookmarked from another source (`normalizeTitle`) is not added, and its progress goes to that bookmark (higher chapter wins); a new comic gets `placeholderDetails` (title and the imported chapter list, empty `totalChapter`, `source` set so §7.7 leaves it alone), in file order; an existing placeholder gets the imported list, a loaded list is never replaced. Missing categories are created; keys over `ComicKey.maxLength` are skipped (§7.1). Read chapters found in the target's list are written to the history at once (finished, imported dates; finished entries kept, nothing unread). The rest (a CSV's last read number, or chapters missing from the target's list) waits in `pending_reads` (local only), merged with what waits.
- **Completing an import:** the first time the comic loads — refresh (`RefreshBookmark`) or opening it (`BookmarkCubit.comicLoaded` → `CompleteImportedComic`, which keeps its place) — the details are saved and `ApplyPendingReads` marks the pending chapters read by number (exact set with dates, or every chapter up to `upTo`; existing history entries kept), then clears it; the comic's history gets the loaded details (cover). A refreshed placeholder moves up only if the source has more chapters than the imported list.

---

## 7. Storage

### 7.1 Boxes

Fourteen `Box<String>` boxes, JSON or plain strings, no type adapters (so backup and sync reuse the same JSON).

| Box | Key | Value |
|---|---|---|
| `bookmarks` | comic key | `BookmarkModel` (with details) |
| `history_entries` | chapter slug | `ReadHistoryModel` |
| `history_comics` | comic key | `HistoryComicModel` (details) |
| `downloads` | chapter slug | `DownloadedChapterModel` (status, page paths, size) |
| `download_comics` | comic key | `DownloadComicModel` (details, cover path) |
| `categories` | category id | `CategoryModel` |
| `comic_categories` | comic key | `ComicCategoriesModel` |
| `library_deletions` | `bookmark:` / `history:` / `category:` + id; `saved:` + the same | deletion time in ms; when a deleted entry was saved again (`LibraryJournal`, for sync) |
| `sync` | `account`, `lastSyncedAt` | email; last sync ms |
| `extensions` | extension id | `ExtensionMeta` |
| `extension_storage` | `<sourceId>:<key>` | value from `storage.set` |
| `source_settings` | `repos`, `active`, `langs:<id>` | repo URLs; active source; enabled languages |
| `pending_reads` | comic key | `PendingRead` from an import (§6.4): JSON `{upTo, read: {number: ms}}`, or a bare number (older versions, read as `upTo`); not synced |
| `settings` | `settings` | `SettingsModel` |

- `JsonBox<T>` gives typed access; an entry that fails to parse is skipped and logged.
- **Hive keys must be ASCII and at most 255 characters.** Hive stores the length in one byte and release builds skip the check, so a longer key corrupts the whole file. `JsonBox`, `LibraryJournal` and pending reads skip keys failing `isValidHiveKey`; imports skip comic keys over `ComicKey.maxLength` (240, room for `/<number>`). Extensions must return short, URL-safe slugs.
- Boxes open through `openStringBox`: if Hive can't read a file, it keeps `<name>.corrupt-<ms>.hive.bak`, salvages entries frame by frame (an overflowed key is replaced by the value's JSON `slug` or `id`) into a fresh box, and the app still starts.
- Not in Hive: scripts in `<app support>/extensions/<id>.js`, Mihon APKs in `<app support>/extensions/<id>-<versionCode>-<time>.apk`, cookies in `<app support>/cookies/<sourceId>/` (Mihon sources: Android's WebView `CookieManager`).

### 7.2 Stored JSON shape

```jsonc
// bookmark
{ "slug": "voratoon:solo-leveling", "updatedDate": 1700000000000,   // ms since epoch
  "addedDate": 1690000000000,                      // absent before it was stored; kept on refresh, migrate, sync, restore
  "comicDetails": { "title", "coverImg", "alternativeTitle", "released", "status",
                    "totalChapter", "author", "type", "rating", "synopsis",
                    "genres": [{ "name", "slug" }],
                    "chapters": [{ "number", "slug", "date" }],
                    "source": "voratoon" } }       // absent in data stored before sources
// history entry (one per read chapter)
{ "slug": "voratoon:solo-leveling/2", "chapterNumber": "2", "readDate": 1700000100000,
  "comicSlug": "voratoon:solo-leveling",
  "page": 12, "pageCount": 40 }                    // absent once the chapter is finished
// history comic
{ "slug": "voratoon:solo-leveling", "comicDetails": { … } }
// category / comic categories
{ "id": "…", "name": "Reading", "order": 0, "updatedDate": "2026-10-20T10:00:00.000" }
{ "slug": "voratoon:solo-leveling", "categoryIds": ["…"], "updatedDate": "2026-10-20T10:00:00.000" }
// settings
{ "themeMode": "system", "readingDirection": "vertical", "pageFit": "width",
  "keepScreenOn": true, "pageGap": false, "progressBar": true, "infiniteScroll": false, "autoScrollSpeed": 3, "incognito": false, "kururinSound": true,
  "bookmarkGrouping": "status",
  "bookmarkSort": "updated", "bookmarkSortDirection": "descending" }
```

- Categories store ISO 8601 dates; bookmarks and history store epoch ms (`EpochMillisConverter`).
- History details are stored once per comic in `history_comics`, so marking a whole comic read writes one chapter list. `HistoryRepositoryImpl` joins on read (entries without a comic record are skipped) and deletes the comic record with its last entry. The `ReadHistory` entity still carries `comicDetails`, one object shared by a comic's entries; a comic record whose JSON would not change is not written again. Entry keys are `<comicKey>/<number>`, so a comic's entries are found and removed by key, without decoding the history.
- Stored models map to entities with `fromEntity` / `toEntity`; entities carry no JSON code.
- User writes go through `LibraryJournal` (records deletions, fires a change for sync). Sync's own writes bypass it.

### 7.3 Ordering
Boxes have no order. Repositories sort on read: bookmarks by `updatedDate` and history by `readDate` (newest first, equal dates by slug), categories by `order`. `HistoryIndex` uses a list already in that order as is. Bookmarks re-sorts by the chosen `BookmarkSort` (`sortBookmarks`, stable). Saving an existing key replaces it.

### 7.4 Backup files
`bacakomik-backup-<y>-<m>-<d>-<h><min><s>.json`, in a folder the user picks:

```jsonc
{ "version": 2, "bookmarks": [ … ], "history": [ … ], "historyComics": [ … ],
  "categories": [ … ], "comicCategories": [ … ] }
```

- Same entry shapes as §7.2. Category fields were added without a version bump (older apps ignore them).
- Another `version` (including pre-2026 files) is rejected with `FileFailure`. **Changing the format bumps `BackupRepositoryImpl.formatVersion`.**
- Backup does nothing when the library is empty. Restore merges (same key or id replaced), then More reloads the bookmark and history cubits.
- Not backed up: downloads, extensions, source settings, pending reads.

### 7.5 Downloads
- **Files:** `<root>/<comicKey>/<chapter>/000.<ext>` and `<root>/<comicKey>/cover.<ext>`; unsafe characters become `_` (`voratoon:slug` → `voratoon_slug`). Root: `getExternalStorageDirectory()/downloads` on Android (app-specific, removed on uninstall), else `getApplicationSupportDirectory()/downloads`. Records store relative paths.
- **Background:** `background_downloader` (`PageDownloadQueue`) runs outside Dart, three pages at a time, through lock and process death, with `imageHeaders`, 10 retries with backoff, one grouped notification. `POST_NOTIFICATIONS` is asked on the first download.
- **Blocked hosts:** on a page's first retry, `imageHostBlocks` (§8.6) checks the host once; a blocking host's pages are saved through `comicImageCache` instead (only while the app runs). Mihon pages go through the local server (§8.9), or that way when there is none.
- **Preparing:** `DownloadRepositoryImpl` takes one chapter at a time, gets fresh page URLs from `ReaderRepository`, records planned paths and queues missing pages. Covers come from `coverImageCache` via a `.part` file; a missing cover doesn't fail the chapter.
- **Progress:** events update records while running; on start and resume `DownloadCubit.sync()` checks planned paths on disk. Nothing queued but pages missing → failed. Unprepared chapters are prepared again.
- **Status:** `queued → downloading → completed`, or `failed`; retry keeps saved pages.
- **Reading:** `GetChapterContent` tries `getOfflineChapter` first (`isOffline: true`, `Image.file`); `GetComicDetails` falls back to `getOfflineComic`. Clearing the image cache keeps downloads.

### 7.6 Sync
One file, `bacakomik-sync.json.gz`, in the app's Drive `appDataFolder` (invisible to the user). `google_sign_in` + `filesDio`.

- **When:** on start, on resume (if last sync > 1 min ago), and 5 s after the last library edit (`LibraryJournal.changes`). The reader saves its page quietly (`recordSaved(quiet: true)`: deletion records still cleared, no change event) and announces the position with one normal save when it closes, the app pauses or another chapter opens (saved before the new one, so the previous chapter never ends up newer). The save on opening a chapter never finishes it: a one-page chapter is finished by the next save, 1 s later, if the reader is still on it. A chapter without pages is not recorded (the reader repository fails it with "This chapter has no pages").
- **What:** bookmarks, history, categories. Not downloads, settings, extensions or pending reads. An imported bookmark syncs as stored (title only until it loads somewhere).
- **Format:** gzipped JSON `version: 1` (`SyncRepositoryImpl.formatVersion`): backup fields plus `deletedBookmarks`, `deletedHistory`, `deletedCategories` (id → ms), and, only when not empty, `savedBookmarks`, `savedHistory`, `savedCategories` (id → ms, deleted entries saved again; older versions ignore them). An entry or date that does not parse is skipped, not the file.
- **Merge** (`SyncSnapshot.merge`): newest wins per key (`updatedDate` / `readDate`); deleted at or after that time → dropped, unless saved again after the deletion (a restore or import keeps its old dates; `saved*` cancels that deletion everywhere); deletions and save-again times older than 180 days are forgotten; a side without category fields keeps the other's.
- **Flow** (`SyncLibrary`): download → merge → migrate legacy (§7.7) → write locally → upload only if different. Local changes bump `libraryRevision` (§4.2). Only 401, or 403 with reason `insufficientPermissions` / `authError`, becomes `AuthFailure` (signed out); quota and rate limits are `ServerFailure`. A stored account that can't be restored at start stays signed in, shown as failed; the next sync (resume or tap) restores it first.
- **Off the UI isolate:** gzip + JSON of the sync file, decoding the local boxes (read as raw JSON strings) and encoding them for `writeLocal` run in `Isolate.run`; `writeLocal` writes only records whose JSON changed, and only those unchanged since the last `readLocal` (an edit made during the sync is kept, a key added meanwhile is not deleted). `merge` walks two slug-sorted lists in one pass; `sameAs` compares each pair of details objects deeply once.

### 7.7 Legacy keys
Keys without a prefix belong to `ComicKey.defaultSource` (`bacakomik`), as all pre-sources keys do. Those came from the old API, now the `voratoon` source (`ComicSource.legacy`). `MigrateSnapshot` moves default-source entries with no `source` (or `"voratoon"`) to `voratoon:<slug>`, rewrites chapter slugs and records deletions for the old keys. It runs in sync, or via `MigrateLocalLibrary` on start/resume when signed out, which first checks stored keys (`SyncRepository.anyLocalComic`): only default-source comics are decoded, and without a legacy one the library is not read. No request is made.

---

## 8. Sources and networking

### 8.1 Sources and comic keys
A source is one site; a multi-language extension is one source per enabled language. Comics are addressed by a **comic key** (`ComicKey`):

| Kind | Format | Example |
|---|---|---|
| Comic | `sourceId:slug` (bare slug for `bacakomik`) | `mysource:some-title`, `solo-leveling` |
| Chapter | `<comicKey>/<number>` | `mysource:some-title/14` |

`SourceRegistry` (`ExtensionManager`) gives `activeSource` and `backend(sourceId)`. `SeriesRemoteDataSource` is the only caller of source methods: `browse`, `series`, `chapters`, `chapter` (plus optional `filters()`, `home`, `webUrl`; contract in `bacakomik-ext-source/types/bridge.d.ts`). DTOs convert with `ApiFormat` (`9.25` → `"9.3"`, missing format → `"-"`, dates → "3 h ago") and turn source slugs into comic keys. The active source defaults to `bacakomik`, else the first installed; with none, Home and Explore show `noSourceMessage` and lead to Extensions.

### 8.2 Extensions and repos
`ExtensionManager` owns installed extensions, repos and runtimes.

- **Repos:** `index.json` URLs (and Mihon repos' `index.min.json`, §8.9), stored in `source_settings` → `repos`; default `https://bacakomik-ext.kurodev.org/index.json` (the built `dist/` of `bacakomik-ext-source`, on a Cloudflare Worker). `addRepo` rejects non-index URLs.
- **`ExtensionMeta`:** `id` (`[a-z0-9_-]`, file name and key prefix), `name`, `lang`, semver `version`, `apiVersion` (app supports `supportedExtensionApi = 1`; higher is listed but not installable), `baseUrl`, `file`, `sha256`, `nsfw`, `languages`, and optional **`urlPatterns`**: regexes whose one capture group is the slug in a series URL path (`slugFromUrl`), used by the Mihon import (§6.4).
- **Install:** download, check `sha256`, load once in a throwaway runtime (failing scripts aren't installed), save the script and meta. Updating = installing the newer version. `catalog()` fetches repos in parallel (a failing repo shows as an error) and sets `updateCount`.
- **Uninstall** removes the script, meta, language setting, and each source's cookies, storage and hidden page.
- **Bundled:** `bacakomik` and `voratoon` in `assets/extensions/`, installed on first run and when the app bundles a newer version (made with `bundle.ts`, CONTRIBUTION §2).
- **Multi-language:** each enabled language is a source `<id>-<lang>`, named `<Name> (<LANG>)`. Enabled list in `source_settings` → `langs:<id>` (default English, else first). Turned-off languages still open.

The `bacakomik` extension wraps the project's own bacakomik-api (`https://api-bacakomik.kurodev.org`).

### 8.3 Extension runtime
`ExtensionRuntime` runs one source per `flutter_js` engine. `ExtensionManager.backend` loads it once: callers asking during the load share it, a failed load is not kept, and an engine whose extension was updated or uninstalled while loading is disposed and loaded again. It loads a prelude with the host globals (`http.fetch`, `html.select`, `storage.get/set`, `webview.run`, `log`, `qs`, `defineExtension`), then `var source = { id, lang }`, then the script (one `defineExtension`).

- Calls are async both ways: JS host calls resolve via `__bkSettle`; Dart method calls run `__bkInvoke` and answer on `bk_result`. Host calls run outside the sending JS call (the engine isn't re-entrant).
- A method fails with "did not respond" after **45 s without progress** (no host call running, starting or finishing); long chains of host calls are not cut off.
- Errors starting with `404` become `ServerException` 404. `features()` caches `filters()` + `home` as `SourceFeatures`, retrying after a failure.

### 8.4 Host side
`ExtensionBridge`, everything per source id.

| Function | Behaviour |
|---|---|
| `http.fetch` | One Dio per source with a persistent cookie jar. Cronet on Android / NSURLSession on iOS (`NativeAdapter`), because Cloudflare rejects `dart:io`'s TLS fingerprint. Chrome-on-Android User-Agent by default. Any status goes back to the script. Connection errors (TLS, reset, refused, `net::ERR_*`) retry 3 times, then `AppText.connectionFailed`. A Cloudflare challenge (`cf-mitigated: challenge`, or a 403/503 challenge page) throws `challenge: <url>`, which `SourceError` turns into "Verify in WebView" |
| `html.select` | `package:html`; returns `{text, html, outerHtml, attrs}` per match |
| `storage.get/set` | `extension_storage`, key `<sourceId>:<key>` |
| `webview.run` | `HeadlessPages` (§8.5) |

### 8.5 WebViews
**Hidden pages** (`HeadlessPages`) run `webview.run` for sites that only answer a real browser. One 360×640 `HeadlessInAppWebView` per source, kept 60 s after its last run (image-host pages 3 minutes); runs queue per source and use the page that exists when they start. Between runs a page is hidden and paused (`WebView.onPause`).

1. Load the URL (25 s) unless already shown. While the title says "Just a moment", wait up to 20 s; a check that needs the user becomes a `Challenge`.
2. Run the script with `callAsyncJavaScript` (**3-minute timeout**).
3. Copy the page's cookies into the source's jar.

- **A failed run closes the page**, so the next run starts fresh with the cookies the user got in the visible WebView. A kept page showing "Just a moment" is reloaded.
- Popups are refused; main-frame navigation to other hosts is cancelled (subdomains and `challenges.cloudflare.com` allowed).
- **Rendering:** hidden WebViews don't render, so lazy pages load nothing. Extension pages are rendered only while a script runs, and any page while it shows a "Just a moment" check: Dart calls `render` / `hide` with the WebView's id on `bacakomik/hidden_webviews`; `MainActivity.kt` moves it into an `Untouchable` frame at alpha 0 and makes it visible, so Chromium renders it while the user can't see or touch it. Image-host pages never render.

**WebView screen** shows the site with the extension's User-Agent. `SourceError` opens it on a challenge URL, the comic page on `webUrl`, and the reader the chapter page (`webUrl(slug, number)`; a source that ignores the number gives the comic page). It copies cookies (e.g. `cf_clearance`) after every load; the failed screen retries when it closes; it can clear the source's cookies.

### 8.6 Images
Two caches share one downloader. `coverImageCache` (key `bacakomikCovers`, 5000 files, 365 days) serves every cover, cover saving and download covers; Clear cache keeps it. `comicImageCache` (`DefaultCacheManager`'s key, 500 files, 14 days) serves pages, prefetch and blocked-host pages; Clear cache empties it.
- `CoverCacheMigration` (started from `main`, once, flag `coverCacheMigrated` in the `settings` box) copies covers of bookmarks, history and downloads from `comicImageCache` with `putFile` (same extension, eTag and expiry).
- Android downloads go through Cronet (`dart:io` if unavailable) with Chrome's `<img>` headers; the reader adds `imageHeaders`. WebView cookies are sent only to hosts that once answered 403/503 (`ImageHostCookies`, read at most every 10 minutes); `warmUpWebView` (from `main`) starts Chromium while idle.
- A host still answering 403/503 is fetched inside a hidden page on `<origin>/robots.txt` (site root if that is turned away) with `fetch` and credentials, for 30 minutes; bodies of 64 KB or more are base64-decoded on another isolate. `imageHostBlocks` runs the same check for the download queue (§7.5).
- `mihon://` images (Mihon sources, §8.9) are fetched through the extension in Kotlin (`ChannelMihonHost.image`); an empty result is an error, not a cached file.

### 8.7 `runRemote`
`runRemote(networkInfo, () async { … })` returns `NetworkFailure` without a connection; otherwise maps `ServerException` → `ServerFailure(message)` and other errors → `ServerFailure(e.toString())`. For parallel requests use `Future.wait`; **not** the record `.wait`, which wraps errors in `ParallelWaitError`.

### 8.8 Other HTTP
`filesDio` (no base URL, 15 s connect, 2 min receive) fetches repos and scripts, calls Drive (§7.6), and backs `ApiClient` for GitHub releases.

### 8.9 Mihon extensions
Android 9+ also runs **Mihon (Tachiyomi) extension APKs** as a second backend: a user adds a Mihon repo (e.g. Keiyoushi), installs an extension, and its sources work like any other (Home, Explore, comic page, reader, bookmarks, refresh, history, downloads, sync, migration). JS extensions keep working; on iOS and Android 8 and older, Mihon repos are skipped and can't be added. Aniyomi (anime), LNReader (novels) and desktop are not supported.

An extension APK is compiled code written against Mihon's source API (`eu.kanade.tachiyomi.source.*`). The app provides that API with the same class names, plus the libraries extensions use (OkHttp, Jsoup, …), and loads the APK as Mihon loads a "private" extension: download into app storage (no system install); `getPackageArchiveInfo` reads its manifest and signer (must be the repo's key, lib version one the host runs); `DelegateLastClassLoader(apk, …, appClassLoader)` loads the `Source` / `SourceFactory` classes. Kotlin answers Dart in the JS contract's shapes, so everything above `SourceBackend` treats both backends alike.

```
ExtensionManager ─► MihonSource (LoadedSource) ─┐
image caches (mihon:// URLs) ───────────────────┼─ channel bacakomik/mihon ─► MihonChannel (app) ─► MihonHost (android/mihon)
MihonInstaller ─────────────────────────────────┘     ├─ Contract, Filters, Description, ChapterRecognition, Images, Slugs, SourceIndex
                                                      └─ ExtensionHost + AndroidLoader (vendored from SCANCORE)
```

**Ids and keys**

| Thing | Format | Example |
|---|---|---|
| Extension id | `mihon-` + package without `eu.kanade.tachiyomi.extension.`, `.` → `_` | `mihon-en_example` |
| Source id | `mihon-<Mihon source id>` (never `:`, which `ComicKey` splits on) | `mihon-3639673976007021338` |
| Comic slug | base64url without padding of `SManga.url` (`Slugs.kt`, `ExtensionMeta.mihonSlug`); over 200 characters, `~` + the URL's SHA-1 | `L21hbmdhLzEyMw` |

Mihon source ids are stable hashes: keys survive updates and match Mihon backups. A hashed slug is read back from a map kept on the device (`bacakomik_mihon_slugs`), filled whenever Kotlin sees the URL (lists, search) and by the Mihon import (`remember`); another device opens such a bookmark once the comic has shown up there. The comic page refuses to bookmark or download a comic whose key is still too long (`ComicKey.storable`), rather than storage skipping it. A multi-source extension uses the multi-language model (`ExtensionMeta.mihonSources`, `forMihonSource`, enabled languages in `langs:<extensionId>`).

**Methods** (`Contract.kt`)

| App method | Mihon | Notes |
|---|---|---|
| `browse` | `getSearchManga` with a query or a changed filter; else `getPopularManga` / `getLatestUpdates` by the `_list` value Home sends | `limit` ignored |
| `series` | `getMangaUpdate` (details) | status from the `SManga` constant; author + artist without repeats; genres split, id = name. `Description.kt` takes alternative titles ("Alternative Titles: …"), a stats line's rating ("Rating: 9.13", or a line of stars and a score) and markdown bold out of the synopsis |
| `chapters` | `getMangaUpdate` (chapters) | see Chapter numbers |
| `chapter` | `getPageList` | finds a number's URL in the last list (fetches again when missing); `prev` / `next` are the nearest numbers; images are `mihon://` URLs |
| `webUrl` | `HttpSource.getMangaUrl`; with a chapter number, `getChapterUrl` | The reader's ⋮ menu (Open in WebView) asks for the chapter's page |
| `features` | `getFilterList` | filter groups + `home`. A source that made no request yet first loads popular page 1 (many extensions fetch their genre list then); a list still showing a "Press reset" header is read again after 2 s |

Details and chapters are separate `getMangaUpdate` calls, details first, one at a time per series (lib 1.6 sources refuse two at once); asks of the same kind arriving together share one call. The last chapter list of each series is kept (`<app files>/mihon/chapters/`) and handed back to `getMangaUpdate`, so sources that read only new chapters ("fetch until known") can: a site that pages its list in a WebView takes minutes the first time and seconds after. `chapters` asks for the details alongside when the title is not known yet.

**Chapter numbers.** The app keys chapters by number, Mihon by URL. A number is `chapter_number`, else read from the name as Mihon does (`ChapterRecognition.kt`, from Mihon; the series title is removed first). One chapter per number: the picked scanlator's when it has that number, else the first in Mihon's order. The comic page shows a scanlator picker (`MihonSource.scanlators` / `setScanlator`, kept per comic on the device) when a comic has several. A chapter without one ("Extra") gets one 0.001 above the numbered chapter before it (`placeNumbers`, counted per base number, so it stays put as new chapters come out) and keeps its name as the chapter's `title`, shown instead of "Chapter n" (`AppText.chapterName`). A list with no number at all is numbered 1, 2, … from the oldest. A comic with one chapter (a gallery such as nhentai, a oneshot) is always chapter 1 with no `title`, so it reads "Chapter 1".

**Filters** (`Filters.kt`). Each top-level filter is group `f<index>`: `Select` → select (option index; a blank option is labelled All), `Sort` → type `sort` (`<i>:a` / `<i>:d`, `''` = source default; the sheet shows one chip per field and a second tap turns the direction), `Group` of `CheckBox` / `TriState` → multi, top-level `CheckBox` / `TriState` → multi with one option. `Text`, `Header`, `Separator` have no group; TriState exclude isn't offered. Values go onto a fresh `getFilterList()` by position; a tree equal to the fresh one (and no query) means "not searching".

**Home.** "New series" is the source's newest-first sort when it has one ("Newest", "Recently added", "Date added", …, not "Latest update"); else its popular list, titled "Popular". Without latest updates the second section is popular, and the first shows only when a newest sort exists (`SourceFeatures.showFeatured`, `featuredLabel`, `latestLabel`).

**Errors.** `describeFailure` (`Rpc.kt`) words a failure; `MihonChannel` sends it as a `PlatformException` (code = status). `ChannelMihonHost.failure`: a browser check becomes `challenge: <url>`, status 404 a 404 `ServerException`. A bare `IOException` is shown as its message (how extensions say "log in to read this").

**Kotlin module** `android/mihon` (`implementation project(':mihon')`):

| Path | What |
|---|---|
| `eu/`, `mihon/`, `tachiyomi/`, `androidx/compose/runtime/Stable.kt` | Mihon's source API and network helpers (Apache 2.0), vendored from SCANCORE's `host/api`. Original package names: extensions link against them |
| `org/kurodev/bacakomik/mihon/host/` | The extension host, from SCANCORE's (MIT, `LICENSE-SCANCORE`; was `com.mediumdev.scancore.host`), trimmed to what the app calls: `ExtensionHost` (calls, `getMangaUpdate` merging, memos, warm-up; loaded extensions cached per APK path), `Codec`, `MemoStore`, `Rpc`, `android/AndroidLoader`, `AndroidSettings`, `WebViewBrowserCheck` (hidden Cloudflare solver, `WebViewCookieJar`). Changes from SCANCORE are marked `BACAKOMIK` |
| `org/kurodev/bacakomik/mihon/` | `MihonHost` (entry), `Contract`, `Filters`, `Description`, `ChapterRecognition`, `Images`, `Slugs`, `SourceIndex` |

`MihonHost.start` runs once per process (Dart calls it before the first call): the app's User-Agent (so WebView clearances work), `WebViewCookieJar`, the hidden browser check, Injekt singletons. Calls: `inspect` (path, signer; loads code only once the signer matches), `install`, `uninstall` (also drops the sources' `source_<id>` preferences), `call`, `preferences` / `setPreference` (a change unloads the extension), `userAgent`. `SourceIndex` (SharedPreferences `bacakomik_mihon_index`) maps source ids to their APK and signer, so a call naming only a source (a cover at start) finds its extension; extensions load on first use. `MihonChannel.kt` runs calls on `Dispatchers.IO`. `MihonHost.supported` is false below Android 9.

**Dart side:** `core/source/mihon_host.dart` (interface; `ChannelMihonHost`), `mihon_source.dart`, `mihon_repo.dart`, `mihon_store.dart`, `mihon_installer.dart`. `ExtensionMeta` gains `pkg`, `signer`, `versionCode`, `mihonSources` (`MihonSourceRef`, with `configurable`) and `icon`.

- **APK files:** `<app support>/extensions/<id>-<versionCode>-<time>.apk`, read-only (Android 14 refuses writable code). Every install gets a new file; the old one is deleted after the new one installs.
- **Updates:** a higher `versionCode`, same badge and button as JS. Lib versions: `supportedMihonLibs` (`1.4`–`1.6`) must match `AndroidLoader.libs`.
- **Images** need the source's own client (headers, cookies, interceptors that unscramble pages): `mihon://<sourceId>/cover/<b64url>` and `mihon://<sourceId>/page/<b64url of page JSON>` (`Images.kt`), fetched by the image caches' `FileService` through the channel (§8.6). The same on every device, so stored covers survive sync.
- **Downloads:** `mihon://` pages go to the background downloader as `http://127.0.0.1:<port>/<token>/image?u=…` (`MihonProxy.kt`, a local server started with the process from `BacaKomikApplication`, which starts the host by itself with the last User-Agent when Dart isn't running). The port is kept across runs; the token keeps other apps out. Without the server they are saved through `comicImageCache` while the app runs (§7.5).
- **Settings:** `ConfigurableSource` screens are read with androidx.preference (`AndroidSettings`) and shown in a Dotline sheet (`mihon_settings_sheet.dart`); values stay in the extension's `source_<id>` SharedPreferences, not in backup or sync. The button shows only for extensions with a configurable source.
- **Cloudflare:** `CloudflareInterceptor` solves automatic checks in a hidden WebView; one that needs the user becomes "Verify in WebView". Extensions and the app's WebViews share Android's `CookieManager`.

**Repos.** Stored by their `index.min.json` URL (a pasted `repo.json` or base URL is normalised). `MihonRepo.fetch` reads `repo.json`: with `index_v2` (Mihon 0.20.1+) it reads that protobuf store (`mihon_store.dart`, gzipped or not, capped at 64 MB; `index.min.json` is then only an "update the app" stub), else the legacy `index.min.json` (APKs at `apk/<file>`, icons at `icon/<pkg>.png`).

```
Store         { 1 name, 2 badge, 3 signingKey, 4 contact, 101 ExtensionList, 102 extensionListUrl }
ExtensionList { repeated 1 Extension }
Extension     { 1 name, 2 packageName, 3 Resources {1 apkUrl, 2 iconUrl}, 4 extensionLib,
                5 versionCode, 6 versionName, 7 contentWarning (3 = NSFW), 8 repeated Source }
Source        { 1 id, 2 name, 3 language, 4 homeUrl }
```

**Trust.** A repo without a signing key is refused; an APK loads only if signed by it. Extensions run with all of the app's permissions: the signer is the only gate. The same package in two repos with different keys (a fork) is two builds: an installed extension is offered updates only from repos with its key, and installing it from another key is refused until it is uninstalled. `android:usesCleartextTraffic="true"`, because some sites are plain `http`.

**R8.** `android/mihon/consumer-rules.pro` keeps the API and every library extensions use, plus `com.squareup.zstd` and `org.brotli`, which native code finds by name over JNI (stripping them aborts the process). Test changes on a **release** build (CONTRIBUTION Recipe H).

**Desktop (not planned).** It could run the same host the way SCANCORE and Suwayomi do (a JVM process, dex2jar per APK, Android stand-ins, JCEF), with Dart sending the same calls as JSON lines. `MihonSource` already talks to the `MihonHost` interface, not the channel.

---

## 9. Errors and logging

| Layer | Errors |
|---|---|
| Data | Throws `ServerException` (optional `statusCode`) or `CacheException`. Source errors: script error, "did not respond", `challenge: <url>`, missing source |
| Repositories | Return `Left`: `ServerFailure`, `NetworkFailure`, `CacheFailure`, `FileFailure`, `AuthFailure` |
| Remote blocs | `NetworkFailure` → `noInternet` (`EmptyState.offline`); others → `SourceError` (challenge: "Verify in WebView" + retry; no source: link to Extensions; else message + retry) |
| Library cubits / backup | Log with `debugPrint` and reload / show a snackbar |

Log with `debugPrint`, never `print`. Extension `log()` prints `[<sourceId>] …`. Never log full backup or sync contents.

---

## 10. Code generation

`build_runner` writes `*.freezed.dart`, `*.g.dart`, `lib/core/di/injection.config.dart` and `lib/core/assets/*.gen.dart`. They are committed and excluded from analysis; `build.yaml` enables `explicit_to_json`.

### 10.1 Version pins
- `freezed: ">=4.0.0 <4.0.2"`: 3.x emits `final` constructor parameters (rejected by Dart 3.13); 4.0.2+ needs a newer `test` than `flutter_test` pins.
- `hive_ce_generator` is deliberately **not** used: boxes hold JSON, and its analyzer range conflicts with freezed.

Upgrade these together in their own PR and run all tests after regenerating.

---

## 11. Feature summary

All done: extensions with repos and updates, multi-language sources, Cloudflare handling (Android), Home / Latest (10-page cap) / Explore per source, comic detail, reader (zoom, auto-scroll, resume, save image), bookmarks with grouping and cancellable refresh, categories, moving a comic between sources, history, theme, backup / restore, Drive sync, offline downloads (background on Android), in-app updates, migrate source and Mihon / CSV import, Mihon extensions on Android 9+ (§8.9).

---

## 12. Open questions

- **Mihon:** mark sources a site offers in both backends? TriState exclude in the filter contract? Extensions whose chapter list loads slowly (pages read in a WebView) keep the comic page waiting, since details and chapters come from one `getMangaUpdate`.
- **Formatting:** the code predates the current `dart format` style. Reformatting everything at once would be a large, noisy diff. Decide whether to do it.
