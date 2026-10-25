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
  (mangafire.to, comix.to…)    │                  Hive boxes (library) ◄────│
                               └───────────────────────────────────────────┘
```

- The app has **no content of its own**. Each site is a **source**, backed by a small JavaScript **extension** downloaded from a repo (§8.2) and run in an embedded JS engine on the phone (§8.3).
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
- iOS. The code mostly runs there, but background downloads, hidden-WebView rendering (§8.5) and notifications are Android-only or untested, and download paths are absolute (§7.5).
- An app store. Releases are APKs on GitHub Releases; the app checks for a newer one on start and in More, downloads the APK for its ABI and opens the installer (`features/update`, `ota_update`). Asset names and the `## Which APK?` heading come from the release workflow (CONTRIBUTION §2).

---

## 2. Tech stack

| Concern | Choice | Notes |
|---|---|---|
| UI | Dart 3.13, Flutter stable | Material 3 themed as Dotline (§5); Geist, Geist Mono, Doto fonts; Lucide icons |
| State / DI / errors | `flutter_bloc`, `get_it` + `injectable`, `fpdart` | `Either<Failure, T>` from repositories (§9) |
| Models | `freezed`, `json_serializable` | Stored models use `@JsonSerializable` (§7.2) |
| Sources | `flutter_js` | One QuickJS engine per source (§8.3); `crypto` checks script `sha256` |
| Source HTTP | `dio` + `native_dio_adapter` (Cronet), `cookie_jar`, `html` | One cookie jar per source (§8.4) |
| WebViews | `flutter_inappwebview` | Hidden pages and the visible WebView screen (§8.5) |
| Images | `cached_network_image`, `flutter_cache_manager`, `cronet_http` | One `comicImageCache` (§8.6) |
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
| `android/…/MainActivity.kt` | `bacakomik/hidden_webviews` channel (§8.5) | Rarely |
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
2. `configureDependencies()` registers everything and opens the fourteen boxes (§7.1) before returning (`@preResolve` in `StorageModule`).
3. `ExtensionManager.installBundled()` installs or upgrades the bundled extensions (§8.2).
4. `runApp`. Library cubits (`BookmarkCubit`, `CategoryCubit`, `HistoryCubit`, `SettingsCubit`, `DownloadCubit`) `load()` when created. `SourcesCubit` and `SyncCubit` are eager; `SyncCubit.start()` restores the Google account and syncs.
5. `ExtensionManager.catalog()` fetches the repos in the background for the update badge.

### 4.2 Bloc scope
- **App scope** (`lib/app/app.dart`): `HomeBloc`, `ExploreBloc`, `FilterCubit`, `SourcesCubit`, the library cubits, `BackupCubit`, `SyncCubit`, `UpdateCubit`. They outlive navigation.
- Two app-level listeners: a new active source resets `FilterCubit` and reloads `HomeBloc`; a new `SyncCubit.libraryRevision` reloads the bookmark, category and history cubits.
- **Route scope:** `LatestBloc`, `ComicDetailsBloc`, `ReaderBloc`, `ExtensionsCubit` are created by their screen (`BlocProvider(create: (_) => getIt<…>())`). The public screen is a thin wrapper over a private view (`_ComicDetailsView`), so each opening starts fresh.

### 4.3 State shapes
- Remote screens: freezed sealed `initial / loading / loaded / error / noInternet`; widgets test `state is HomeLoaded`; errors render `SourceError` (§9).
- Paginated lists share `ComicListState` and the `ComicListLoader` mixin (`loadFirstPage`, `loadNextPage`). Next page is ignored until the first loaded; `ComicListLoaded.isLoadMore` is true while loading.
- Library cubits hold plain lists or `AppSettings` and reload from the repository after every write.
- `SourcesState` mirrors `ExtensionManager`: installed and known sources (incl. languages turned off), active source and its `SourceFeatures`, update count.
- Events are `final class`es named after what happened (`HomeStarted`, `ChapterRequested`).

### 4.4 Settings
`AppSettings`: `themeMode` (`system | light | dark`), reader settings (`readingDirection`, `pageFit`, `keepScreenOn`, `pageGap`, `autoScrollSpeed`), `bookmarkGrouping` (`status | source | category`), `bookmarkSort` (`updated | title | chapters | latestChapter | added | lastRead`) and `bookmarkSortDirection` (`ascending | descending`; default `updated` descending = repository order). `SettingsModel` defaults every field and tolerates unknown enum values, so new fields never break loading. Source settings live in the `source_settings` box, not here.

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
| home | Home tab | `HomeBloc` | Two parallel `browse` calls: slider with `home.featured` (10) and "Latest updates" with `home.latest` (20); last read comic; header opens the source picker |
| latest | "See all" | `LatestBloc` | Infinite scroll, up to 10 pages |
| explore | Explore tab | `ExploreBloc`, `FilterCubit` | `ExploreFilter` (source, query, values per group) goes to one `browse`. Sheet built from `filters()`; a `quick` group shows above the grid. Changing source resets it. Genre chips on a comic page open Explore with that genre alone (`FilterCubit.showGenre`). Requests run in order |
| comic_detail | Card tap, shared link | `ComicDetailsBloc` | Series and chapters in parallel; bookmark (then categories, §6.2), continue, WebView, share, multi-select to download or mark read. Offline: opens from stored details (downloads, bookmarks, history). Missing source: `MissingSource` offers to install it |
| reader | Chapter tap | `ReaderBloc` | Chapter slug `<comicKey>/<number>`; prev/next replace the route; writes history with the page reached; uses `imageHeaders`; downloaded chapters read from files |
| bookmark | Bookmarks tab | `BookmarkCubit` | Search, group tabs (§6.2), refresh (§6.1) |
| category | More → Categories | `CategoryCubit` | §6.2 |
| history | History tab | `HistoryCubit` | Newest chapter per comic by day; remove one, a comic, or all |
| source | Header; More → Extensions | `SourcesCubit`, `ExtensionsCubit` | §8 |
| settings, backup, sync, download, update | More | own cubits | §4.4, §7.4, §7.6, §7.5, §1 |
| migration | More → Backup & sync → Migration; Bookmarks selection; comic page | `MatchCubit`, `MihonImportCubit` | §6.4 |

### 6.1 Checking bookmarks for new chapters
1. Pull-to-refresh calls `BookmarkCubit.updateBookmarkList` with the comics **on screen** (open group, narrowed by search). Pulling in another group during a run adds to the queue.
2. `RefreshBookmark` reloads each comic in turn. A changed chapter count saves the new details with `updatedDate = now` (moves it to the top). A failure leaves it unchanged and logs `Refresh <key>: <failure>`.
3. `ProgressNotifier` (Android) shows `done / total`, then "Bookmarks updated" with the count, or nothing.

| Stop | How |
|---|---|
| Cancel in the notification | Reaches `progressActionInBackground` in a background isolate, which forwards via `IsolateNameServer`; `BookmarkCubit.cancelRefresh` drops the queue. **Needs `ActionBroadcastReceiver` in `AndroidManifest.xml`** |
| Stop button in the Bookmarks header | Shown while `BookmarkCubit.refreshing`; same cancel |
| A comic over `refreshTimeout` (90 s) | Skipped, so one stuck site can't block the run |
| Notification swiped away | Stays away; **the run continues** |

Imported reading progress written during a refresh (§6.4) reloads the history at once through `BookmarkCubit.historyChanges`.

### 6.2 Categories and grouping
User-made `LibraryCategory` (id, name, order, `updatedDate`), managed in More → Categories. A comic can be in many (`ComicCategories`: key → ids). Bookmarking opens `SetCategoriesSheet` (skippable; with several comics, partly-applied categories start half-checked and stay unless tapped). Bookmarks group by status (All / Updated / Completed), source, or category (+ Uncategorized).

### 6.3 One series in two sources
Keys include the source (§8.1), so `westmanga:oreaku` and `voratoon:oreaku` would be two bookmarks. Bookmarking a title that matches one from another source (case, spacing, punctuation ignored) opens `DuplicateSheet`: move or keep both. Moving runs `MigrateComic`: replaces the bookmark, moves each read chapter to the same number in the new source (missing ones dropped), and joins both comics' categories.

### 6.4 Migration
Three entries under More → Migration. **All write through the normal repositories**, so sync and the journal see them.

| Entry | Input | How comics are found |
|---|---|---|
| Migrate source (`SourceMigrationScreen` → `MatchScreen`) | Bookmarks of one source, a selection, or the open comic | Title search in the target; then `MigrateToSource` runs `MigrateComic` (§6.3) |
| Mihon / Tachiyomi (`MihonImportScreen`) | `.tachibk` (gzipped protobuf, `parseMihonBackup`) | The backup link, read with the extension's `urlPatterns` (§8.2); no request |
| Comix.to (`MatchScreen`) | CSV export (`parseComixCsv`), no links | Title search in `comix` (`MissingSource` if not installed) |

- **Title search** (`MatchCubit`): one request at a time, `gap` 3 s apart, manual searches join the queue. A single result with the same normalized title is picked automatically (`exactMatch`); the user picks or skips the rest.
- **Mihon:** only library comics (`favorite`), with category names and their chapters (`BackupChapter`: url, read, dates, number; `BackupHistory` field 104, legacy 102, for read dates). `importChapters` keeps numbered chapters, one per number, newest first; a read chapter takes its Mihon history date, others are placed 1 ms around the nearest dated one (or Mihon's fetch date) so the newest read chapter is the latest. Half-read pages are skipped. Sources match by name; a multi-language extension's language comes from the Mihon source id (MD5 of `<name>/<lang>/<versionId>`, `mihonSourceId`). Unmatched sources are listed as skipped; a matched but missing extension can be installed from the screen (its language is enabled). Re-importing adds no bookmarks but brings read chapters to earlier imports.
- **`ImportLibrary`:** an existing key is left alone; a title already bookmarked from another source (`normalizeTitle`) is not added, and its progress goes to that bookmark (higher chapter wins); a new comic gets `placeholderDetails` (title and the imported chapter list, empty `totalChapter`, `source` set so §7.7 leaves it alone), in file order; an existing placeholder gets the imported list, a loaded list is never replaced. Missing categories are created; keys over `ComicKey.maxLength` are skipped (§7.1). Read chapters found in the target's list are written to the history at once (finished, imported dates; finished entries kept, nothing unread). The rest (Comix's last read number, or chapters missing from the target's list) waits in `pending_reads` (local only), merged with what waits.
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
| `library_deletions` | `bookmark:` / `history:` / `category:` + id | deletion time in ms (`LibraryJournal`, for sync) |
| `sync` | `account`, `lastSyncedAt` | email; last sync ms |
| `extensions` | extension id | `ExtensionMeta` |
| `extension_storage` | `<sourceId>:<key>` | value from `storage.set` |
| `source_settings` | `repos`, `active`, `langs:<id>` | repo URLs; active source; enabled languages |
| `pending_reads` | comic key | `PendingRead` from an import (§6.4): JSON `{upTo, read: {number: ms}}`, or a bare number (older versions, read as `upTo`); not synced |
| `settings` | `settings` | `SettingsModel` |

- `JsonBox<T>` gives typed access; an entry that fails to parse is skipped and logged.
- **Hive keys must be ASCII and at most 255 characters.** Hive stores the length in one byte and release builds skip the check, so a longer key corrupts the whole file. `JsonBox`, `LibraryJournal` and pending reads skip keys failing `isValidHiveKey`; imports skip comic keys over `ComicKey.maxLength` (240, room for `/<number>`). Extensions must return short, URL-safe slugs.
- Boxes open through `openStringBox`: if Hive can't read a file, it keeps `<name>.corrupt-<ms>.hive.bak`, salvages entries frame by frame (an overflowed key is replaced by the value's JSON `slug` or `id`) into a fresh box, and the app still starts.
- Not in Hive: scripts in `<app support>/extensions/<id>.js`, cookies in `<app support>/cookies/<sourceId>/`.

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
  "keepScreenOn": true, "pageGap": false, "autoScrollSpeed": 3, "bookmarkGrouping": "status",
  "bookmarkSort": "updated", "bookmarkSortDirection": "descending" }
```

- Categories store ISO 8601 dates; bookmarks and history store epoch ms (`EpochMillisConverter`).
- History details are stored once per comic in `history_comics`, so marking a whole comic read writes one chapter list. `HistoryRepositoryImpl` joins on read (entries without a comic record are skipped) and deletes the comic record with its last entry. The `ReadHistory` entity still carries `comicDetails`.
- Stored models map to entities with `fromEntity` / `toEntity`; entities carry no JSON code.
- User writes go through `LibraryJournal` (records deletions, fires a change for sync). Sync's own writes bypass it.

### 7.3 Ordering
Boxes have no order. Repositories sort on read: bookmarks by `updatedDate` and history by `readDate` (newest first), categories by `order`. Bookmarks re-sorts by the chosen `BookmarkSort` (`sortBookmarks`, stable). Saving an existing key replaces it.

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
- **Blocked hosts:** on a page's first retry, `imageHostBlocks` (§8.6) checks the host once; a blocking host's pages are saved through `comicImageCache` instead (only while the app runs).
- **Preparing:** `DownloadRepositoryImpl` takes one chapter at a time, gets fresh page URLs from `ReaderRepository`, records planned paths and queues missing pages. Covers come from `comicImageCache` via a `.part` file; a missing cover doesn't fail the chapter.
- **Progress:** events update records while running; on start and resume `DownloadCubit.sync()` checks planned paths on disk. Nothing queued but pages missing → failed. Unprepared chapters are prepared again.
- **Status:** `queued → downloading → completed`, or `failed`; retry keeps saved pages.
- **Reading:** `GetChapterContent` tries `getOfflineChapter` first (`isOffline: true`, `Image.file`); `GetComicDetails` falls back to `getOfflineComic`. Clearing the image cache keeps downloads.

### 7.6 Sync
One file, `bacakomik-sync.json.gz`, in the app's Drive `appDataFolder` (invisible to the user). `google_sign_in` + `filesDio`.

- **When:** on start, on resume (if last sync > 1 min ago), and 5 s after the last library edit (`LibraryJournal.changes`).
- **What:** bookmarks, history, categories. Not downloads, settings, extensions or pending reads. An imported bookmark syncs as stored (title only until it loads somewhere).
- **Format:** gzipped JSON `version: 1` (`SyncRepositoryImpl.formatVersion`): backup fields plus `deletedBookmarks`, `deletedHistory`, `deletedCategories` (id → ms).
- **Merge** (`SyncSnapshot.merge`): newest wins per key (`updatedDate` / `readDate`); deleted at or after that time → dropped; deletions older than 180 days are forgotten; a side without category fields keeps the other's.
- **Flow** (`SyncLibrary`): download → merge → migrate legacy (§7.7) → write locally → upload only if different. Local changes bump `libraryRevision` (§4.2). Auth errors become `AuthFailure`.

### 7.7 Legacy keys
Keys without a prefix belong to `ComicKey.defaultSource` (`bacakomik`), as all pre-sources keys do. Those came from the old API, now the `voratoon` source (`ComicSource.legacy`). `MigrateSnapshot` moves default-source entries with no `source` (or `"voratoon"`) to `voratoon:<slug>`, rewrites chapter slugs and records deletions for the old keys. It runs in sync, or via `MigrateLocalLibrary` on start/resume when signed out. No request is made.

---

## 8. Sources and networking

### 8.1 Sources and comic keys
A source is one site; a multi-language extension (MangaDex) is one source per enabled language. Comics are addressed by a **comic key** (`ComicKey`):

| Kind | Format | Example |
|---|---|---|
| Comic | `sourceId:slug` (bare slug for `bacakomik`) | `westmanga:oreaku`, `solo-leveling` |
| Chapter | `<comicKey>/<number>` | `westmanga:oreaku/14` |

`SourceRegistry` (`ExtensionManager`) gives `activeSource` and `backend(sourceId)`. `SeriesRemoteDataSource` is the only caller of source methods: `browse`, `series`, `chapters`, `chapter` (plus optional `filters()`, `home`, `webUrl`; contract in `bacakomik-ext-source/types/bridge.d.ts`). DTOs convert with `ApiFormat` (`9.25` → `"9.3"`, missing format → `"-"`, dates → "3 h ago") and turn source slugs into comic keys. The active source defaults to `bacakomik`, else the first installed; with none, Home and Explore show `noSourceMessage` and lead to Extensions.

### 8.2 Extensions and repos
`ExtensionManager` owns installed extensions, repos and runtimes.

- **Repos:** `index.json` URLs, stored in `source_settings` → `repos`; default `https://bacakomik-ext.kurodev.org/index.json` (the built `dist/` of `bacakomik-ext-source`, on a Cloudflare Worker). `addRepo` rejects non-index URLs.
- **`ExtensionMeta`:** `id` (`[a-z0-9_-]`, file name and key prefix), `name`, `lang`, semver `version`, `apiVersion` (app supports `supportedExtensionApi = 1`; higher is listed but not installable), `baseUrl`, `file`, `sha256`, `nsfw`, `languages`, and optional **`urlPatterns`**: regexes whose one capture group is the slug in a series URL path (`slugFromUrl`), used by the Mihon import (§6.4).
- **Install:** download, check `sha256`, load once in a throwaway runtime (failing scripts aren't installed), save the script and meta. Updating = installing the newer version. `catalog()` fetches repos in parallel (a failing repo shows as an error) and sets `updateCount`.
- **Uninstall** removes the script, meta, language setting, and each source's cookies, storage and hidden page.
- **Bundled:** `bacakomik` and `voratoon` in `assets/extensions/`, installed on first run and when the app bundles a newer version (made with `bundle.ts`, CONTRIBUTION §2).
- **Multi-language:** each enabled language is a source `<id>-<lang>`, named `<Name> (<LANG>)`. Enabled list in `source_settings` → `langs:<id>` (default English, else first). Turned-off languages still open.

The `bacakomik` extension wraps the project's own bacakomik-api (`https://api-bacakomik.kurodev.org`, serving bacakomik.my).

### 8.3 Extension runtime
`ExtensionRuntime` runs one source per `flutter_js` engine. It loads a prelude with the host globals (`http.fetch`, `html.select`, `storage.get/set`, `webview.run`, `log`, `qs`, `defineExtension`), then `var source = { id, lang }`, then the script (one `defineExtension`).

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
**Hidden pages** (`HeadlessPages`) run `webview.run` for sites that only answer a real browser. One `HeadlessInAppWebView` per source, kept 3 minutes after its last run; runs queue per source and use the page that exists when they start.

1. Load the URL (25 s) unless already shown. While the title says "Just a moment", wait up to 20 s; a check that needs the user becomes a `Challenge`.
2. Run the script with `callAsyncJavaScript` (**3-minute timeout**).
3. Copy the page's cookies into the source's jar.

- **A failed run closes the page**, so the next run starts fresh with the cookies the user got in the visible WebView. A kept page showing "Just a moment" is reloaded.
- Popups are refused; main-frame navigation to other hosts is cancelled (subdomains and `challenges.cloudflare.com` allowed).
- **Rendering:** hidden WebViews don't render, so lazy pages load nothing. After creating one, Dart calls `render` on `bacakomik/hidden_webviews`; `MainActivity.kt` moves it into an `Untouchable` frame at alpha 0 and makes it visible, so Chromium renders it while the user can't see or touch it.

**WebView screen** shows the site with the extension's User-Agent. `SourceError` opens it on a challenge URL, the comic page on `webUrl`. It copies cookies (e.g. `cf_clearance`) after every load; the failed screen retries when it closes; it can clear the source's cookies.

### 8.6 Images
`comicImageCache` serves covers, pages, prefetch, download covers and blocked-host pages (keeps `DefaultCacheManager`'s key).
- Android downloads go through Cronet (`dart:io` if unavailable) with Chrome's `<img>` headers and the WebViews' cookies; the reader adds `imageHeaders`.
- A host answering 403/503 is fetched inside a hidden page (`fetch` with credentials, base64) for 30 minutes. `imageHostBlocks` runs the same check for the download queue (§7.5).

### 8.7 `runRemote`
`runRemote(networkInfo, () async { … })` returns `NetworkFailure` without a connection; otherwise maps `ServerException` → `ServerFailure(message)` and other errors → `ServerFailure(e.toString())`. For parallel requests use `Future.wait`; **not** the record `.wait`, which wraps errors in `ParallelWaitError`.

### 8.8 Other HTTP
`filesDio` (no base URL, 15 s connect, 2 min receive) fetches repos and scripts, calls Drive (§7.6), and backs `ApiClient` for GitHub releases.

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

All done: extensions with repos and updates, multi-language sources, Cloudflare handling (Android), Home / Latest (10-page cap) / Explore per source, comic detail, reader (zoom, auto-scroll, resume, save image), bookmarks with grouping and cancellable refresh, categories, moving a comic between sources, history, theme, backup / restore, Drive sync, offline downloads (background on Android), in-app updates, migrate source and Mihon / Comix.to import.

---

## 12. Open questions

- **Formatting:** the code predates the current `dart format` style. Reformatting everything at once would be a large, noisy diff. Decide whether to do it.
