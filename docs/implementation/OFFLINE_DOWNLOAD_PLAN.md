# Offline chapter download — implementation plan

Status: implemented on `feat/offline-download` (2026-10-20). See `ARCHITECTURE.md` §7.5 for the shipped design. Differences from this plan are listed in §7.

## 1. Feasibility

Possible with the current stack and no new heavy dependencies:

- `GET /series/{slug}/{number}` (`SeriesRemoteDataSource.getChapter`) already returns the full list of page image URLs. The images load without extra headers (`CachedNetworkImage` uses none), so a plain `Dio` download works.
- `dio`, `path_provider` and `hive_ce` are already dependencies. The `JsonBox` + `Box<String>` pattern fits download metadata.
- The reader goes through one seam: `ReaderRepository.getChapter`. A local-first lookup there makes the reader work offline without touching `ReaderBloc`.
- History is local, so reading offline still records progress.

Why not reuse `flutter_cache_manager`: its disk cache is evicted by age and count, and "Hapus cache" empties it. Downloads must survive both, so they need their own folder.

## 2. Scope

### v1 (this plan)

- Download one or more chapters from the comic detail screen (selection bar), while the app is open.
- Queue with progress per chapter; cancel; retry a failed chapter (already saved pages are skipped).
- Read a downloaded chapter with no connection. Prev/next works when the neighbour is also downloaded.
- Open the comic detail page offline for a comic that has downloads (stored snapshot).
- "Unduhan" screen under Lainnya: downloads grouped by comic, total size, delete per chapter or per comic, delete all.
- Download badge on chapter rows.

### Not in v1

- Background downloads after the app is closed (needs a foreground service or `workmanager`; Android 14 foreground-service types and iOS background limits make this its own project).
- Auto-download new chapters of bookmarked comics.
- Wi-Fi only setting, storage location picker, export as CBZ.
- Downloads in backup files. Backups stay small JSON; downloaded files are not included.

## 3. Storage design

### 3.1 Files

```
<downloadsRoot>/
  <seriesSlug>/
    cover.<ext>
    <chapterNumber>/
      000.<ext>
      001.<ext>
      ...
```

`downloadsRoot`:

| Platform | Directory | Example |
|---|---|---|
| Android | `getExternalStorageDirectory()` + `/downloads` | `/storage/emulated/0/Android/data/<package>/files/downloads` |
| Android, external storage unavailable | `getApplicationSupportDirectory()` + `/downloads` | `/data/user/0/<package>/files/downloads` |
| iOS | `getApplicationSupportDirectory()` + `/downloads` | app container, excluded from the Files app |

- App-specific external storage on Android: a dedicated folder for downloads, no permission needed, and it does not count against the smaller internal data partition on older devices. Android removes it on uninstall, together with the Hive boxes, so files and metadata never get out of sync.
- Not the cache directory: the OS may clear cache directories.
- Not a public folder (`/storage/emulated/0/BacaKomik`): that needs `MANAGE_EXTERNAL_STORAGE`, a `.nomedia` file to keep pages out of the gallery, and a way to rebuild the Hive index after a reinstall. Out of scope.
- `DownloadFileDataSource` resolves `downloadsRoot` once at startup. If `getExternalStorageDirectory()` returns null (storage not mounted), it uses the fallback. Downloads already saved in the other root are not migrated.
- Store paths **relative** to `downloadsRoot`. On iOS the container path changes between app updates, so absolute paths go stale. Resolve to absolute at read time.
- Page file names are zero-padded indexes, so order never depends on the URL. Extension comes from the URL path, falling back to the `Content-Type` header, then `.jpg`.
- Write each page to `NNN.<ext>.part` and rename when complete. A crash never leaves a truncated file that looks finished.
- Slugs are ASCII and URL-safe (see §7.1 of `ARCHITECTURE.md`), so they are safe as folder names. Sanitize anyway (`[^A-Za-z0-9._-]` → `_`).

### 3.2 Hive boxes

Add to `HiveBoxes` and `StorageModule`:

| Box | Key | Value |
|---|---|---|
| `downloads` | chapter slug (`series/number`) | `DownloadedChapterModel` JSON |
| `download_comics` | series slug | `DownloadComicModel` JSON (comic details snapshot + local cover path) |

`DownloadedChapterModel`:

```json
{
  "slug": "one-piece/1100",
  "seriesSlug": "one-piece",
  "chapterNumber": "1100",
  "chapterTitle": "Chapter 1100",
  "previousChapterSlug": "one-piece/1099",
  "nextChapterSlug": null,
  "pages": ["one-piece/1100/000.webp", "one-piece/1100/001.webp"],
  "pageCount": 2,
  "sizeBytes": 3145728,
  "status": "completed",
  "downloadedAt": "2026-10-20T10:00:00.000"
}
```

- `status`: `queued | downloading | completed | failed`. Only `completed` is readable offline. On startup, `queued`/`downloading` entries become `failed` (the app was closed mid-download), and the user can retry.
- `pages` is filled in as pages finish, so retry knows what to skip.
- Reuse the model style of `ReadHistoryModel` (json_serializable, every field defaulted where reasonable) so later fields do not break loading.
- `DownloadComicModel` reuses the `ComicDetails` JSON shape already used by `HistoryComicModel`. Refresh the snapshot whenever a new chapter of that comic is downloaded.

## 4. Architecture

New feature folder `lib/features/download/`, following the existing layers:

```
features/download/
  data/
    datasources/
      download_local_data_source.dart   # JsonBox over the two boxes
      download_file_data_source.dart    # folder paths, Dio file download, delete, size
    models/
      downloaded_chapter_model.dart
      download_comic_model.dart
    repositories/
      download_repository_impl.dart
  domain/
    entities/
      downloaded_chapter.dart           # freezed
      download_task.dart                # freezed: slug, status, done/total pages
    repositories/
      download_repository.dart
    usecases/
      download_usecases.dart            # enqueue, cancel, retry, delete, list
  presentation/
    bloc/
      download_cubit.dart               # app scope
    pages/
      downloads_screen.dart
    widgets/
      download_badge.dart
      download_comic_group.dart
```

### 4.1 Download queue

`DownloadQueue` (`@lazySingleton`, in `data/`) owns the running work:

- One chapter at a time; up to 3 pages of that chapter in parallel. Comic image hosts throttle aggressive clients, and one chapter at a time keeps progress easy to read.
- For each chapter: call `SeriesRemoteDataSource.getChapter` to get fresh image URLs (do not trust URLs from an old screen), save metadata as `downloading`, download missing pages, then mark `completed` with `sizeBytes`.
- A separate `Dio` instance for files (`ResponseType.bytes` / `download()`, longer `receiveTimeout`, no `baseUrl`). Register it as a named instance in `RegisterModule`.
- `CancelToken` per chapter. Cancel deletes the chapter folder and its metadata.
- Exposes `Stream<Map<String, DownloadTask>>`. `DownloadCubit` maps it to state; chapter rows and the Unduhan screen watch the cubit.
- Retries: each page up to 2 retries with a short delay. Then the chapter is `failed`; saved pages stay.
- Keep the screen on while the queue runs (`wakelock_plus` is already a dependency), so the OS does not suspend the app mid-download. Release it when the queue is empty.

### 4.2 Reader integration

`ReaderRepositoryImpl.getChapter`:

1. Ask `DownloadRepository` for a `completed` chapter with this slug.
2. Found: return `ChapterContent` built from local data, no network.
3. Not found: current remote path.

Local first also when online: faster, and no data use.

`ChapterContent` gets a field telling the reader where pages come from:

```dart
@freezed
abstract class ChapterContent with _$ChapterContent {
  const factory ChapterContent({
    required String chapterTitle,
    required String chapterNumber,
    required String seriesSlug,
    String? previousChapterSlug,
    String? nextChapterSlug,
    required List<String> images,

    /// True when [images] are absolute file paths of a downloaded chapter.
    @Default(false) bool isOffline,
  }) = _ChapterContent;
}
```

Reader changes in `read_chapter_screen.dart` and `chapter_image.dart`:

- `_loadNextBatch`: skip the `DefaultCacheManager().getSingleFile` prefetch when `isOffline`; mark the batch settled at once.
- `ChapterImg`: when offline, render `Image.file` with the same `cacheWidth` / `cacheHeight` logic as `memCacheWidth` / `memCacheHeight` today. Keep the placeholder and error widget.
- Save to gallery (`saveImg`): accept a local file path as well as a URL.
- Prev/next to a chapter that is not downloaded while offline: the remote path returns `NetworkFailure`, so the existing "no internet" state shows. No extra work.

### 4.3 Comic detail offline

`ComicDetailRepositoryImpl.getComicDetails`: on `NetworkFailure`, fall back to the `download_comics` snapshot if it exists. The screen shows the snapshot; only downloaded chapters open. Optional small banner: "Mode offline".

### 4.4 Comic detail UI

- `ComicAppBar._selectionBar`: add a download `RoundIconButton` (`LucideIcons300.download`) next to mark read/unread. Enqueues the selected chapters in reading order (oldest first) and clears the selection. Snackbar: "N chapter ditambahkan ke unduhan".
- `ChapterTile`: trailing badge from `DownloadCubit`:
  - completed: `LucideIcons300.circleCheck` (or download-done icon) in `inkFaint`
  - downloading: `DotMeter`/small progress text `12/30`
  - queued: clock icon
  - failed: alert icon in accent color; tap row still opens online
- Long press menu stays selection only; no per-row download button, to keep rows calm.

### 4.5 Unduhan screen

Entry: new `ListRow` in `more_screen.dart` (Lainnya), with total size as trailing text.

- Header: total size and chapter count (`StatTile`).
- Active queue section at the top: current chapter with progress, queued list, cancel buttons.
- Comics grouped (`ListGroup`), cover from the local file, chapter rows sorted by number. Tap opens the reader.
- Swipe to delete a chapter (`flutter_slidable` is already a dependency); sheet action to delete a whole comic; "Hapus semua unduhan" with a destructive confirm sheet.
- Empty state via `EmptyState`.

### 4.6 Other touch points

- `ClearCacheSheet`: add a row "Unduhan — kept" so users know clearing cache does not remove downloads.
- `BackupCubit` / backup format: unchanged. Mention in the restore sheet that downloads are not part of backups (optional).
- `AppText`: new strings (`download`, `downloads`, `downloadAdded`, `downloadFailed`, `deleteDownload`, `deleteAllDownloads`, `offlineMode`, ...).
- `app.dart`: provide `DownloadCubit` at app scope.
- Android: no new permissions. Files live in app-private storage; `INTERNET` is already declared.

## 5. Phases

Each phase is one PR-sized step that builds and passes tests.

1. **Storage and models**
   - `HiveBoxes.downloads`, `HiveBoxes.downloadComics`, `StorageModule` entries.
   - Models, entities, `DownloadLocalDataSource`, `DownloadFileDataSource` (paths, size, delete).
   - Unit tests for model round trip and path resolution.
2. **Download queue and repository**
   - `DownloadQueue`, file `Dio`, `DownloadRepository(Impl)`, use cases, `DownloadCubit`.
   - Startup cleanup: stale `queued`/`downloading` → `failed`; delete orphan `.part` files.
   - Tests with a fake downloader: order, skip saved pages on retry, cancel cleanup, failure status.
3. **Reader reads local chapters**
   - `ChapterContent.isOffline`, local-first `ReaderRepositoryImpl`, `ChapterImg` file mode, `saveImg` file path.
   - Tests: repository returns local content when completed, remote otherwise.
4. **Comic detail UI**
   - Download button in the selection bar, badge in `ChapterTile`, offline fallback for comic details.
5. **Unduhan screen**
   - Screen, entry in Lainnya, delete flows, `ClearCacheSheet` row.
6. **Docs and release**
   - `ARCHITECTURE.md`: boxes table (§7.1), feature folder list, runtime diagram (app-scope `DownloadCubit`), feature summary row "Offline reading → Done (foreground only)".
   - Manual test on a real device: airplane mode, kill app mid-download, low storage.

## 6. Risks and open questions

- **Image URL lifetime.** If the API's image URLs are signed or expire, a stale queue entry fails. Mitigation: fetch fresh URLs per chapter right before downloading (already in the plan).
- **Host throttling / hotlink protection.** Today no headers are needed. If a host starts requiring `Referer`, add it to the file `Dio` and to `CachedNetworkImage.httpHeaders` together.
- **Storage use.** A webtoon chapter is often 5–30 MB. Show sizes clearly; consider a warning when free space is low (needs a plugin such as `disk_space`; out of v1).
- **App closed mid-download.** v1 marks the chapter failed and resumes on retry. True background download is a later project.
- **Re-uploaded chapters.** If the source replaces a chapter's images, the download keeps the old pages. Acceptable; user can delete and re-download.
- **Open question:** should completed downloads be deleted automatically once a chapter is marked finished? Default no; maybe a setting later.

## 7. As built

Differences from the plan above:

- **Offline lookup lives in the use cases**, not in `ReaderRepositoryImpl`. `GetChapterContent` checks `DownloadRepository.getOfflineChapter` first, and `GetComicDetails` falls back to `getOfflineComic` on any failure. `DownloadRepositoryImpl` fetches fresh page URLs through `ReaderRepository`, so the chapter mapping is not duplicated and there is no dependency cycle.
- **No queue/task stream.** Progress is written to Hive after every page and `DownloadRepository.changes` fires; `DownloadCubit` reloads (coalesced) and its state is a `DownloadLibrary` (chapters by slug + comics).
- **No wakelock during downloads.** The reader already enables and disables the wakelock on its own, and the two would fight. The Dart isolate keeps running while the app is in the background until Android kills the process; an interrupted chapter becomes `failed` on the next start and resumes on retry.
- **No "Mode offline" banner** on the comic page; the stored details simply show.
- **Cancel = delete.** The queue row's × removes the record and any saved pages.
- Unduhan entry is the first row of DATA in Lainnya, showing the size used.
- Verified on an Android 15 emulator: download two chapters, read one in airplane mode, fail mid-download, retry, swipe-delete, open the comic page offline.
