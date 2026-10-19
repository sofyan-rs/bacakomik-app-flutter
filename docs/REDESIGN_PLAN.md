# Rencana Redesign UI — Dotline

Rencana implementasi redesign seluruh UI BacaKomik berdasarkan `docs/redesign/` (DESIGN_SYSTEM.md + 13 mockup). Dokumen ini menerjemahkan design system ke struktur kode **saat ini** (feature-first clean architecture, lihat `ARCHITECTURE.md`).

> Catatan: tabel "Peta layar → kode" di `DESIGN_SYSTEM.md §6` masih memakai path lama (`lib/presentation/screens/...`). Path yang benar ada di §3 dokumen ini.

---

## 1. Ruang lingkup

**Termasuk**
- Tema baru (Dotline dark-first + light), font Geist/Geist Mono/Doto, ikon Lucide.
- Semua layar: Splash, Beranda, Detail komik, Jelajah (+ Filter sheet), Favorit, Riwayat (jadi tab), Lainnya (+ sheet Bersihkan cache), Pembaca (+ sheet Pengaturan baca, layar akhir chapter).
- Layar tanpa mockup ikut disesuaikan dengan komponen yang sama: Chapter terbaru ("Lihat semua"), hasil pencarian, placeholder error/kosong, dialog konfirmasi.
- Ikon aplikasi B · Panel dan native splash.
- Fitur kecil yang dibutuhkan mockup (pengaturan baca, progres halaman, filter Favorit, dsb. — §4).

**Tidak termasuk**
- Perubahan API, domain bisnis besar, akun/sinkronisasi.
- Perubahan format penyimpanan yang merusak data lama. Semua field baru wajib punya default supaya JSON lama dan file backup lama tetap terbaca (aturan kompatibilitas di `ARCHITECTURE.md §7`).

## 2. Strategi

- Branch: `feat/redesign` dari `main`. Satu PR, commit per fase (§5).
- Bangun fondasi dan komponen dulu, lalu migrasi layar satu per satu. Aplikasi tetap bisa jalan di setiap commit.
- Logika (bloc, use case, repository) tidak diubah kecuali untuk kebutuhan data baru di §4. UI hanya membaca state yang ada.
- `solar_icons`, `google_fonts`, `AppColors` lama dan `AppThemes` lama dihapus di fase terakhir, setelah tidak ada pemakai.

## 3. Peta layar → kode

| Mockup | Layar | File |
|---|---|---|
| `01-splash` | Splash | `lib/app/splash_screen.dart`, native splash (Android `res/drawable*`, `values*/styles.xml`) |
| `02-beranda` | Beranda | `features/home/presentation/pages/home_screen.dart`, `widgets/last_read_comic.dart`, `comic_slider.dart`, `comic_slider_card.dart`, `latest_chapter.dart`, `latest_chapter_card.dart` |
| — | Chapter terbaru (lihat semua) | `features/latest/presentation/pages/latest_chapter_screen.dart`, `widgets/latest_chapter_more.dart` |
| `03-detail-komik` | Detail komik | `features/comic_detail/presentation/pages/comic_details_screen.dart`, `widgets/comic_app_bar.dart`, `comic_cover.dart`, `comic_info.dart`, `comic_chapters.dart`, `chapter_tile.dart` |
| `04-jelajah` | Jelajah | `features/explore/presentation/pages/explore_screen.dart`, `widgets/filter_result.dart` |
| `05-filter-sheet` | Filter | `features/explore/presentation/widgets/filter_comic.dart` → bottom sheet |
| — | Pencarian | `features/search/presentation/pages/search_screen.dart`, `widgets/search_result.dart` (tetap layar sendiri, tampilan mengikuti Jelajah, §4.4) |
| `06-favorit` | Favorit | `features/bookmark/presentation/pages/bookmarks_screen.dart`, `widgets/bookmark_comic_card.dart` |
| `07-riwayat` | Riwayat (tab) | `features/history/presentation/pages/history_screen.dart`, `widgets/history_comic_card.dart` |
| `08-lainnya` | Lainnya | `features/settings/presentation/pages/more_screen.dart`, `widgets/settings.dart`, `widgets/app_info.dart` |
| `09-bersihkan-cache-sheet` | Konfirmasi cache | widget baru `features/settings/presentation/widgets/clear_cache_sheet.dart` |
| `10-baca-chapter` | Pembaca | `features/reader/presentation/pages/read_chapter_screen.dart`, `widgets/chapter_image.dart` |
| `11-pengaturan-baca-sheet` | Pengaturan baca | widget baru `features/reader/presentation/widgets/reader_settings_sheet.dart` |
| `12-akhir-chapter` | Akhir chapter | widget baru `features/reader/presentation/widgets/chapter_end.dart` |
| `13-ikon-perbandingan` | Ikon aplikasi | `android/app/src/main/res/mipmap-*` (salin dari `docs/redesign/app-icon/`) |
| — | Navigasi root | `lib/app/root_screen.dart` (5 tab + FloatingNavBar) |
| — | Widget bersama | `core/presentation/widgets/comic_card.dart`, `chip/*`, `placeholder/*` |

## 4. Kebutuhan data dan perilaku baru

Mockup menampilkan beberapa hal yang belum ada di kode. Semua diturunkan dari data lokal yang sudah ada kalau memungkinkan.

### 4.1 Progres baca (Beranda, Favorit, Riwayat, Detail)
- Progres = `nomor chapter terakhir dibaca / jumlah chapter` (contoh `67 / 88`). Sumber: `ReadHistoryQueries.latestOf(slug)` + `ComicDetails.chapters.length`.
- Tambah helper murni (extension di domain history) yang mengembalikan `ReadProgress(current, total)` supaya Beranda, Favorit, Riwayat dan Detail memakai hitungan yang sama. Ditest unit.

### 4.2 Favorit: badge `+N`, filter Semua / Ada update / Selesai
- `+N` = jumlah chapter yang lebih baru dari chapter terakhir yang dibaca (dari history). Tidak butuh field baru di `Bookmark`.
- **Ada update** = `N > 0`. **Selesai** = semua chapter sudah dibaca (`current == total`, keputusan D1).
- Subjudul "6 komik · 2 ada update". Tombol cari = filter lokal judul di dalam daftar favorit.
- Filter disimpan di state UI (bukan storage).

### 4.3 Riwayat jadi tab
- `RootScreen`: 5 tab Beranda, Jelajah, Favorit, Riwayat, Lainnya. Baris "Riwayat baca" di Lainnya dihapus.
- Dikelompokkan per hari (Hari ini, Kemarin, lalu tanggal) dari `readDate`, satu baris per komik (`latestPerComic`), jam dalam format `HH:mm`.
- Swipe hapus per komik (sudah ada `flutter_slidable`); tombol tempat sampah di header = hapus semua dengan sheet konfirmasi.

### 4.4 Pencarian dan Chapter terbaru (layar tanpa mockup)
- **Pencarian** tetap layar sendiri (`SearchScreen` + `SearchBloc`, alur sekarang). Tampilannya mengikuti Jelajah:
  - tombol kembali bulat + search pill (autofocus) di atas;
  - hasil memakai grid 3 kolom `ComicCover` yang sama dengan Jelajah (label tipe, judul, `CH. N`), dengan pagination seperti sekarang;
  - state kosong/tidak ditemukan/error memakai `EmptyState` / `ErrorState`.
- Dibuka dari tombol cari Beranda dan dari tap search pill di Jelajah (search pill di Jelajah hanya pemicu, bukan input).
- **Chapter terbaru ("Lihat semua")** tetap layar sendiri. Tampilannya sama dengan section Chapter terbaru di Beranda: header + list group dengan baris yang sama (thumbnail, judul, tipe · status, `CH. N`, titik BARU + waktu), plus pagination seperti sekarang. Baris dibuat sekali dan dipakai di kedua tempat.
- Segmented tipe di Jelajah dan pilihan "Tipe" di Filter sheet menulis ke `FilterCubit` yang sama. Baris "URUT: TERBARU · ONGOING" dan angka badge Filter dibaca dari state filter.

### 4.5 Detail komik
- Bar bawah: bookmark (toggle) + tombol "Lanjut baca · Ch. N" (dari history) atau "Mulai baca · Ch. 1" kalau belum pernah baca.
- Daftar chapter: cari nomor chapter dan urutkan naik/turun (state UI lokal). Chapter yang sudah dibaca redup + ikon `check`. Label "BARU" untuk chapter yang rilis < 24 jam (atau sesuai format `Chapter.date`, keputusan D3).
- Tombol bagikan memakai `share_plus` (dependensi baru) dengan URL komik.

### 4.6 Pembaca
- Tap halaman: tampil/sembunyi bar atas dan pill navigasi (animasi fade/slide 140 ms). Mode imersif sistem saat kontrol tersembunyi.
- Bar atas: kembali, judul chapter + judul komik, tombol daftar chapter (sheet daftar chapter), tombol pengaturan baca.
- Pill bawah: prev chapter, DotMeter halaman + "HAL 12 / 24", next chapter.
- Halaman aktif dihitung dari posisi scroll. Karena tinggi gambar beragam, pakai `scrollable_positioned_list` (dependensi baru) atau `GlobalKey` per item. Pilihan default: `scrollable_positioned_list`.
- Item terakhir list = layar Akhir chapter (`12-akhir-chapter`): DotMeter penuh, "Chapter N selesai", kartu chapter berikutnya, tombol Lanjut / Daftar chapter / Ke beranda. Kalau tidak ada chapter berikutnya, kartu diganti teks "Kamu sudah di chapter terbaru".
- Simpan gambar (long-press, pakai `gal`) tetap ada, sheet-nya ikut gaya action sheet.

### 4.7 Pengaturan baca (field baru di `AppSettings`)
| Field | Tipe | Default | Efek |
|---|---|---|---|
| `readingDirection` | `vertical` / `rtl` / `ltr` | `vertical` | `vertical` = list scroll; `rtl`/`ltr` = `PageView` horizontal (rtl = `reverse: true`) |
| `pageFit` | `width` / `height` | `width` | `BoxFit.fitWidth` / `BoxFit.fitHeight` |
| `keepScreenOn` | bool | `true` | `wakelock_plus` (dependensi baru) aktif selama di pembaca |
| `pageGap` | bool | `false` | jarak 8px antar halaman |

- `SettingsModel` JSON: field baru opsional dengan default, jadi data lama dan backup lama tetap terbaca. Tambah test round-trip JSON lama → model baru.
- Disimpan lewat `SettingsCubit` seperti `darkMode`.

### 4.8 Lainnya
- Stat tile: jumlah favorit (`BookmarkCubit`) dan "Chapter dibaca" (`history.length`).
- Grup Data: Cadangkan, Pulihkan, Bersihkan cache (buka sheet `09`). Segmented Tema menggantikan dropdown dark mode lama. Grup Tentang: Lapor bug. Footer `BACAKOMIK <versi>` dari `package_info_plus`.
- Kartu akun dan sapaan berbasis nama dihapus. Beranda tetap menampilkan sapaan waktu ("SELAMAT PAGI/SIANG/SORE/MALAM") memakai `Clock`.

### 4.9 Splash
- Latar `bg`, `splash-art.webp` (radius `l`), "BACAKOMIK" Doto `dotBrand`, overline "MANGA · MANHWA · MANHUA", loader 5 titik beranimasi, footer "FROM / Kurodev".
- Native splash: `flutter_native_splash` (dev dependency) dengan latar `#000000` dan splash art, supaya transisi native → Flutter mulus.
- Durasi tetap 3 detik (perilaku sekarang, keputusan D2).

### 4.10 Lebar layar ≥ 640 dp
Design system tidak punya NavigationRail. Keputusan D4: FloatingNavBar yang sama (lebar pas isi, D9), di tengah bawah; grid Jelajah/Favorit menambah kolom sesuai lebar (`SliverGridDelegateWithMaxCrossAxisExtent`).

## 5. Fase

Setiap fase diakhiri `flutter analyze` bersih, `flutter test` hijau, dan cek manual di emulator (dark + light).

### Fase 0 — Persiapan
- Branch `feat/redesign`.
- Salin `docs/redesign/assets/fonts/*` → `assets/fonts/` dan `splash-art.webp` → `assets/images/`. SVG Lucide di `docs/redesign/assets/icons/lucide/` tidak disalin (ikon dari package, D6).
- `pubspec.yaml`: daftar font; tambah `lucide_icons_flutter`, `share_plus`, `wakelock_plus`, `scrollable_positioned_list`, dev `flutter_native_splash`. Jalankan `build_runner` untuk `assets.gen.dart`.

### Fase 1 — Fondasi tema
- `core/theme/` (baru): `dotline_colors.dart` (`DotlineColors` + `Dotline.of`), `dotline_text.dart`, `dotline_tokens.dart` (spasi, radius, ukuran, `shadowFloat`, durasi gerak), `dotline_theme.dart` (`dotlineTheme()`).
- `app.dart`: pakai `dotlineTheme` untuk light/dark, `themeMode` dari `SettingsCubit`.
- `core/constants/theme.dart` dan `colors.dart` tetap ada sementara agar layar lama tidak rusak.

### Fase 2 — Komponen
Di `core/presentation/widgets/dotline/` (baru), masing-masing dengan widget test ringan:
Ikon tidak butuh widget sendiri: pakai `Icon(LucideIcons300.x)`, ukuran dan warna dari `IconTheme` (D6).
`ScreenHeader` (judul Doto + subjudul + aksi bulat), `RoundIconButton`, `FloatingNavBar`, `SegmentedControl`, `DotChip`, `DotButton` (primer/outline/hapus, besar/sedang, disabled), `DotSwitch`, `ListGroup` + `ListRow`, `showDotSheet` + `SheetHandle` + `ActionSheetHeader` + `QuickActionTile`, `DotMenu`, `DotMeter`, `ComicCover` (placeholder grid titik + label tipe), `NewBadge` / `UpdateBadge`, `StatTile`, `SearchField`, `SectionLabel` (overline + "LIHAT SEMUA"), `DotLoader`, `EmptyState` / `ErrorState` (pengganti `placeholder/*`).
Tambah `previews.dart` untuk melihat semua komponen di dark & light (opsional).

### Fase 3 — Root + navigasi
- `RootScreen`: `Stack` + `IndexedStack` 5 tab + `FloatingNavBar` (sembunyi saat keyboard terbuka), padding bawah daftar setinggi nav.
- Fade bawah di belakang nav (D7): `Positioned` + `IgnorePointer` + `DecoratedBox` `LinearGradient` vertikal dari `bg` alpha 0 ke `bg` penuh. Tingginya dari atas nav sampai bawah layar (nav + jarak 12 + inset navigasi sistem). Hanya di 5 tab utama. Edge-to-edge (system navigation bar transparan) supaya fade menutup sampai bawah layar.
- Pindah `HistoryScreen` ke tab ke-4 (tanpa AppBar/back).

### Fase 4 — Splash & ikon
- `SplashScreen` baru, konfigurasi `flutter_native_splash`, salin `app-icon/android/.../res` ke `android/app/src/main/res` (jangan jalankan `flutter_launcher_icons`).

### Fase 5 — Beranda & Chapter terbaru
- Header sapaan + BACAKOMIK + tombol cari (buka `SearchScreen`), kartu Lanjut baca (DotMeter 22), Hot komik horizontal bernomor 01–03…, list group Chapter terbaru (titik BARU + waktu relatif).
- Baris chapter terbaru jadi satu widget (`latest_chapter_card.dart`) yang dipakai Beranda dan `LatestChapterScreen` (§4.4).

### Fase 6 — Jelajah + Filter + Pencarian
- Search pill (pemicu `SearchScreen`), segmented tipe, baris urut + tombol Filter (badge jumlah filter aktif), grid 3 kolom `ComicCover` (widget grid dipakai juga oleh `SearchScreen`).
- Filter jadi bottom sheet (`showDotSheet`): chip single-select Tipe/Status/Urutkan, multi-select Genre, Reset, tombol "Tampilkan hasil".
- `SearchScreen` dengan tampilan Jelajah (§4.4).

### Fase 7 — Detail komik
- Cover tengah, meta overline, judul, author, 3 `StatTile`, sinopsis expand, chip genre outline, daftar chapter (cari, urut, BARU, ✓), bar bawah bookmark + Lanjut baca, bagikan.

### Fase 8 — Favorit & Riwayat
- Helper progres (§4.1) + test.
- Favorit (§4.2), Riwayat (§4.3) dengan swipe hapus dan hapus semua.

### Fase 9 — Lainnya
- Stat tile, grup Data, sheet Bersihkan cache, segmented Tema, Lapor bug, versi.

### Fase 10 — Pembaca
- Field baru `AppSettings` + model + test kompatibilitas (§4.7).
- Kontrol tampil/sembunyi, bar atas, pill navigasi + DotMeter halaman, mode vertikal/horizontal, fit, jarak, wakelock, sheet Pengaturan baca, sheet daftar chapter, layar Akhir chapter.

### Fase 11 — Bersih-bersih
- Ganti sisa `SolarIcons` (saat ini dipakai di 24 file) dengan `LucideIcons300`; hapus `solar_icons`, `google_fonts`, `AppColors` lama, `AppThemes` lama, warna tipe komik, widget placeholder/chip lama yang tidak dipakai.
- Rapikan string di `core/constants/texts.dart` (hapus yang tidak dipakai, tambah yang baru).
- Perbarui `ARCHITECTURE.md` §2/§3 (font, ikon, tab Riwayat, `core/theme`), tabel path di `DESIGN_SYSTEM.md §6`, dan §2.2 (ikon via `lucide_icons_flutter`).
- Uji akhir: dark/light, layar kecil & ≥ 640 dp, `disableAnimations`, TalkBack untuk nav tanpa label (Semantics), update dari versi lama (data favorit/riwayat/pengaturan masih ada, backup lama bisa dipulihkan).

## 6. Pengujian

- Unit: helper progres baca, hitungan `+N`/filter Favorit, pengelompokan Riwayat per hari, JSON `SettingsModel` lama → baru.
- Bloc: `SettingsCubit` untuk field baru (bloc_test).
- Widget: `FloatingNavBar` (ganti tab), `SegmentedControl`, `DotSwitch`, `DotMeter` (Semantics value), Filter sheet (pilih & reset).
- Test yang sudah ada di `test/` harus tetap hijau; sesuaikan kalau ada finder yang bergantung pada teks/ikon lama.

## 7. Risiko

| Risiko | Mitigasi |
|---|---|
| Data lama rusak karena field settings baru | Field opsional + default, test round-trip, jangan ganti nama key lama |
| Hitungan halaman aktif tidak akurat (tinggi gambar beda-beda) | `scrollable_positioned_list` + `itemPositionsListener` |
| Mode horizontal mengubah perilaku simpan riwayat | Riwayat tetap dicatat saat chapter dibuka (perilaku sekarang), tidak bergantung mode |
| Kontras `lineStrong` < 3:1 | Jangan jadikan satu-satunya penanda kontrol (sesuai DESIGN_SYSTEM) |
| PR terlalu besar | Commit per fase, tiap fase bisa direview sendiri |

## 8. Keputusan

- **D1. Filter "Selesai" di Favorit** = semua chapter sudah dibaca (`current == total`), bukan status komik Completed.
- **D2. Splash** tetap 3 detik seperti sekarang.
- **D3. Label "BARU" di chapter** = rilis < 24 jam. Format `Chapter.date` dari API dicek saat implementasi; kalau tidak bisa diparse, BARU hanya untuk chapter terbaru yang belum dibaca.
- **D4. Layar lebar** untuk sekarang tetap FloatingNavBar di tengah bawah (tanpa NavigationRail). Bisa ditinjau ulang nanti.
- **D5. Dependensi baru disetujui:** `lucide_icons_flutter`, `share_plus`, `wakelock_plus`, `scrollable_positioned_list`, dev `flutter_native_splash`.
- **D6. Semua ikon pakai Lucide dari package `lucide_icons_flutter` (^4.0.0), varian `LucideIcons300`** (`import 'package:lucide_icons_flutter/lucide_icons_300.dart'`). Ini menggantikan pendekatan SVG + `DotIcon` di `DESIGN_SYSTEM.md §2.2`.
  - Alasan memilih weight 300: hasil ukur glyph `minus` di font package, stroke per weight di grid 24 = 100: 0.48, 200: 1.01, **300: 1.54**, 400: 2.02, 500: 2.50, 600: 2.98. Weight 300 paling dekat dengan stroke 1.5 di design system.
  - Semua 25 ikon yang sudah teridentifikasi tersedia, penamaan lowerCamelCase: `house`, `compass`, `bookmark`, `history`, `ellipsis`, `ellipsisVertical`, `search`, `chevronLeft`, `chevronRight`, `share2`, `arrowDownUp`, `list`, `slidersHorizontal`, `trash2`, `check`, `x`, `bookOpen`, `arrowRight`, `database`, `rotateCcw`, `bug`, `image`, `download`, `wifiOff`, `searchX`.
  - Hanya import `lucide_icons_300.dart` (jangan `lucide_icons_weights.dart`) supaya hanya satu font yang ikut. `IconData` const, jadi tree-shaking ikon saat `flutter build` tetap jalan.
  - Tidak ada `SolarIcons` maupun `Icons.*` Material yang tersisa di UI. Fase 11 memverifikasi dengan grep di `lib/`.
- **D7. Fade di bagian bawah tab utama.** Konten yang di-scroll memudar ke `bg` di belakang FloatingNavBar, seperti contoh dari user. Fade ini sengaja menyimpang dari `DESIGN_SYSTEM.md` ("tanpa gradien", "tanpa band/latar penuh di belakangnya"). Gradien hanya dipakai untuk fade ini dan mengikuti tema (hitam di dark, `#F2F2F2` di light). Fade tidak menangkap sentuhan (`IgnorePointer`). Pembaca dan Detail komik tidak memakai fade.
- **D8. FloatingNavBar tanpa shadow** (permintaan user). `shadowFloat` tetap ada untuk menu dan pill navigasi chapter, tapi lebih halus dari design system: dark `0x52000000`, light `0x14000000`, offset 0,4, blur 16 (`shadowFloat(brightness)` di `dotline_tokens.dart`).
- **D9. FloatingNavBar selebar isinya**, mengikuti contoh dari user: lingkaran tab berjarak 6 satu sama lain, sama dengan jarak ke tepi pill, jadi ujung lingkaran konsentris dengan ujung pill. Untuk 5 tab lebarnya 296 dp (`FloatingNavBar.widthFor`). Area tap tiap tab sampai setengah jarak ke tab tetangga.
- **D10. Native splash hanya warna hitam.** `flutter_native_splash` butuh PNG, sedangkan splash art berupa WebP dan di mesin ini tidak ada alat konversi. Android 12+ menampilkan ikon aplikasi di atas hitam, lalu splash Flutter menampilkan art-nya. Bisa diganti nanti dengan PNG dari `splash-art.webp`.
- **D11. Data yang tidak tersedia dari API.** Baris Chapter terbaru tidak menampilkan waktu rilis (`Comic` tidak punya tanggal). Hot komik tidak punya "Lihat semua" karena belum ada layar daftar populer. Bagikan mengirim judul + teks, bukan URL, karena belum ada URL web komik.
- **D12. Kuru-kuru tetap.** Gif dan sound saat pull-to-refresh di Beranda dipertahankan sebagai easter egg.
- **D13. Istilah "Bookmark", bukan "Favorit".** Permintaan user: tab, judul layar, filter, stat di Lainnya dan semua teks UI memakai "Bookmark". Mockup `06-favorit` dan teks "Favorit" di `DESIGN_SYSTEM.md` dibaca sebagai Bookmark.
- **D14. Pembaca.** Mode Kanan-kiri / Kiri-kanan memakai `PageView`; halaman webtoon yang sangat tinggi dengan "Lebar layar" terpotong di mode ini (pakai "Tinggi layar" atau mode Vertikal). Request Dio tambahan per gambar di `ChapterImg` lama dihapus karena hasilnya tidak dipakai (gambar tetap dimuat lewat `CachedNetworkImage`). Ikon aplikasi diberi `<inset>` 14% di adaptive icon karena glyph terlalu mepet ke tepi.
- **D15. "Tentang aplikasi"** tidak lagi menampilkan changelog; diganti tautan ke kurodev.org (permintaan user). `core/constants/changelogs.dart` dihapus.
- **D16. Zoom dan pemuatan halaman (permintaan user).** Double-tap memperbesar 2.5× ke titik yang diketuk dengan animasi 260 ms dan kembali dengan double-tap lagi; pinch sampai 4×. Saat zoom, mode vertikal tetap bisa di-scroll dan digeser ke samping; di mode halaman, swipe antar halaman dimatikan. Gambar dimuat berurutan per 5 halaman (`precacheImage`); batch berikutnya dibuka setelah batch sebelumnya selesai, atau lebih awal saat pembaca sampai 2 halaman sebelum batas.
- **D17. Search digabung ke Jelajah** (permintaan user, setelah API `/series` dipastikan menerapkan `q` bersama filter). Search pill di Jelajah sekarang input sungguhan (debounce 400 ms); hasilnya mengikuti tipe, status, urutan dan genre yang aktif. `SearchScreen`/`SearchBloc` dihapus; tombol cari di Beranda pindah ke tab Jelajah dan memfokuskan kolom cari (`RootTabs`). Hint "Cari judul komik" karena API hanya mencari judul. Ini menggantikan §4.4 bagian Pencarian.
- **D18. Filter mengikuti enum API** (`/openapi.json`): urutan Terbaru, Seri Baru, Bookmark, Populer, Rating, A–Z; status + Cancelled. Parameter lain (`mangatoon`/`webtoon`, `type`, `anime`, `minChapters`) sengaja tidak dipakai. `test/core/filters_test.dart` menjaga opsi tetap di dalam enum.
