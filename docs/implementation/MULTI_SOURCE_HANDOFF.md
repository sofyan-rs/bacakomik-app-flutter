# Multi-source (extensions) — handoff

Status per 2026-10-24. Branch `feat/multi-source`. Lanjutkan dari sini di PC lain.

## Ringkasan

App sekarang multi-source ala Tachiyomi/Mihon, tapi ekstensinya **file JavaScript** yang dijalankan di QuickJS (Android) / JavaScriptCore (iOS) lewat `flutter_js`. Bukan APK, karena Flutter tidak bisa load kode Dart saat runtime.

Repo terkait:

| Repo | Isi | Status |
|---|---|---|
| `bacakomik-app-flutter` (ini) | App, runtime ekstensi, UI sumber | branch `feat/multi-source` |
| `bacakomik-ext-source` (`github.com/sofyan-rs/bacakomik-ext-source`, private; folder lokal `bacakomik-ext`) | Source ekstensi `bacakomik` + `voratoon`, tooling Bun, workflow `Publish` | branch `main` |
| `bacakomik-ext` (`github.com/sofyan-rs/bacakomik-ext`, public) | Hasil build (`index.json` + `*.js`) di root, di-push oleh workflow `Publish`. Jangan edit manual. | branch `main` |
| `bacakomik-api` | Worker API bacakomik (dipakai ekstensi `bacakomik`) | UA Chrome Android di `src/upstream.ts` belum di-commit |

## Setup di PC baru

1. Flutter **≥ 3.47 / Dart ≥ 3.13** (pubspec butuh `sdk: ^3.13.0`). `flutter upgrade` kalau perlu.
2. Gradle wrapper 9.3.1 (`android/gradle/wrapper`) — download pertama besar (~200 MB).
3. ```bash
   git checkout feat/multi-source
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   flutter analyze && flutter test   # terakhir: bersih, 174 test lolos
   ```
4. Repo ekstensi: `bun install`, lalu `bun run build`, `bun scripts/run.ts voratoon smoke`, `bun scripts/run.ts bacakomik smoke`.

## Arsitektur

### Comic key (inti kompatibilitas data lama)

`lib/core/source/comic_key.dart`. Semua tempat yang dulu pakai slug (Hive, history, download, deep link, sync) sekarang pakai **key**:

- sumber default `bacakomik` → slug polos (`solo-leveling`) — **semua data lama otomatis valid**
- sumber lain → `sourceId:slug` (`voratoon:solo-leveling`)
- chapter slug tetap `key/number`

Satu judul dari dua sumber = dua entri terpisah di bookmark & history (seperti Mihon).

### Runtime ekstensi — `lib/core/source/`

| File | Fungsi |
|---|---|
| `extension_runtime.dart` | `ExtensionRuntime`: satu engine JS per ekstensi. Prelude JS menyediakan `http`, `html`, `storage`, `log`, `qs`, `defineExtension`. Pemanggilan dua arah async lewat channel `bk_bridge` / `bk_result` (promise di-settle dari Dart dengan `__bkSettle`). Interface `SourceBackend { features(), call(method, args) }`. |
| `extension_bridge.dart` | Implementasi host: `http.fetch` (Dio + cookie jar per ekstensi di `<appSupport>/cookies/<id>`, UA Chrome Android), `html.select` (`package:html`), `storage` (Hive box `extension_storage`). |
| `extension_manager.dart` | Install / update / uninstall, repo, sumber aktif, cache runtime. Script di `<appSupport>/extensions/<id>.js`, metadata di Hive box `extensions`. Ekstensi bundled (`assets/extensions/`) di-install saat start (`main.dart`) bila belum ada / versi bundled lebih baru. Verifikasi `sha256`, validasi id `^[a-z0-9][a-z0-9_-]*$`. Interface `SourceRegistry` untuk test. |
| `extension_meta.dart` | `ExtensionMeta` (entri `index.json`), `FilterGroup`, `SourceFeatures`, `FilterValues`. `supportedExtensionApi = 1`. |

`SeriesRemoteDataSourceImpl` (`lib/core/data/datasources/`) sekarang memanggil method JS lalu menulis ulang slug jadi key. DTO lama (`SeriesResponse` dkk.) tetap dipakai karena output ekstensi = shape bacakomik-api.

### Kontrak ekstensi (apiVersion 1)

Lengkapnya di `bacakomik-ext/README.md` dan `types/bridge.d.ts`.

```js
defineExtension({
  async filters() { return FilterGroup[] },          // opsional, boleh fetch (genre)
  home: { featured: { sort: ['newseries'] }, latest: { sort: ['latest'] } },
  async browse({ page, limit, query, filters }) {},  // -> { items: Series[], hasNext }
  async series(slug) {}, async chapters(slug) {}, async chapter(slug, number) {},
})
// FilterGroup = { key, label, type: 'select'|'multi', options:[{value,label}], default?, quick? }
```

- Filter **sepenuhnya dinamis** per source. Grup `quick: true` tampil sebagai segmented/chips di atas grid Explore.
- Grup multi ber-key `genre` = id genre di `SeriesDetail.genres` (chip genre di detail → Explore terfilter).
- Error "tidak ditemukan": `throw new Error('404 ...')` → `ServerException(statusCode: 404)`.
- Script = plain JS (bukan module). Tidak ada `URL`, `fetch`, `setTimeout`, `atob`. Pakai `qs()`.

### UI

- `features/source/`: `SourcesCubit` (sumber aktif + features), `ExtensionsCubit`, `ExtensionsScreen` (tab Installed/Available, filter bahasa, update, uninstall), `ReposSheet` (tambah/hapus URL repo), `SourcePickerSheet` (dropdown ala screenshot vault: judul + chevron → sheet "Change source", Manage, Add source, Open).
- Home & Explore: judul = nama sumber + chevron, subjudul `domain · ● Online/Error/Offline` dari state screen (tanpa request tambahan).
- Ganti sumber → `app.dart` listener: `FilterCubit.setSource` (reset filter) + `HomeStarted`. Explore reload sendiri saat `filter.source` berubah.
- More → Data → **Extensions**.
- Kartu bookmark & history menampilkan nama sumber (`context.sourceNameOf(key)`).

### Duplikat & migrate (ala Mihon)

Saat bookmark judul yang sudah ada dari sumber lain (judul dinormalisasi): sheet **Migrate / Add anyway / Cancel** (`comic_detail/presentation/widgets/duplicate_sheet.dart`).

- `MigrateComic` (`bookmark/domain/usecases/migrate_comic.dart`): bookmark pindah ke key baru, history dipindah per nomor chapter yang ada di sumber baru, entri lama dihapus (tercatat di journal → ikut sync).
- Add anyway: dua entri terpisah.

### Migrasi data lama

`MigrateSnapshot` (`sync/domain/usecases/migrate_library.dart`) sekarang **tanpa network**: entri dengan key polos dan `source == null` atau `'voratoon'` (data dari era voratoon) dipindah ke `voratoon:<slug>`, tombstone untuk key lama. Entri `source == 'bacakomik'` tidak disentuh. `SeriesLookupRepository` dihapus. Format sync/backup tidak berubah (key tetap string).

### Lokalisasi

Semua teks UI sudah English (`AppText` + literal lain). Tab: Home, Explore, Bookmarks, History, More.

## Belum selesai / TODO

1. **Tes di emulator/HP belum dilakukan.** Belum terbukti `flutter_js` + bridge async jalan di device. Rencana tes:
   - Install build `main` (v1.5.1) → buat beberapa bookmark & history → install build branch ini (debug key sama, data tetap) → cek bookmark/history lama masih ada dan bisa dibuka.
   - Ganti sumber ke VoraToon, browse, filter, buka chapter.
   - Bookmark judul yang sama dari dua sumber → cek sheet Migrate / Add anyway, cek history ikut pindah.
   - Extensions screen: repo, install/uninstall.
   - Worktree `/tmp/bk-main` (checkout `main`) dibuat di PC lama untuk tes ini — abaikan / `git worktree prune` di PC baru.
2. **Publish repo ekstensi**: `defaultRepo` = `https://raw.githubusercontent.com/sofyan-rs/bacakomik-ext/main/index.json`. Workflow `Publish` di repo source butuh secret `PUBLISH_DEPLOY_KEY` + deploy key (write) di repo public — langkah di header `.github/workflows/publish.yml`. Sampai publish pertama, app tetap jalan dengan ekstensi bundled.
3. **Sinkron aset bundled**: tiap ubah ekstensi → `bun run build` di `bacakomik-ext` → copy `dist/*` ke `assets/extensions/` → naikkan `version` di `meta.json` kalau user lama harus dapat versi baru.
4. **Download** belum dimigrasi untuk entri voratoon lama (folder/key tetap slug polos). Konten offline masih bisa dibaca dari Downloads.
5. **Cover voratoon** = presigned S3 (kedaluwarsa ~6 hari). Cover di bookmark diperbarui saat refresh bookmark / buka detail.
6. **ISP block**: voratoon kadang diblok Internet Positif (sertifikat `internetpositif.id`). Pertimbangkan DoH/pengaturan DNS di bridge.
7. **bacakomik-api**: filter `type=project` selalu kosong; field `author` solo-leveling rusak (`"Chugong, h-goon, ..., ]DUBU ... [Add, Redice Studio"`) — kemungkinan bug di commit "include artists in series author". UA Chrome Android di `src/upstream.ts` belum di-commit.
8. `lib/core/assets/assets.gen.dart` ikut men-generate `assets/extensions/*` (nama file berversi → churn). Opsional: exclude di config `flutter_gen`.
9. iOS: `flutter_js` menambah CocoaPods (`ios/Flutter/*.xcconfig` berubah). Belum dicoba build iOS.
