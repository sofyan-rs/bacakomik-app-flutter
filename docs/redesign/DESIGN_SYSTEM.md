# BacaKomik — Design System (Dotline untuk Flutter)

Redesign BacaKomik memakai **Dotline**: monokrom, dark-first, satu warna sinyal merah, motif titik. Aplikasinya tetap **Flutter**; dokumen ini menerjemahkan Dotline ke `ThemeData`, `ThemeExtension` dan widget Flutter, lalu memetakan tiap layar baru ke file yang sudah ada di `lib/presentation/`.

Sumber: Dotline (design system) dan Dotnote for Android (implementasi Compose yang menjadi acuan nilai). Semua nilai di bawah sama persis dengan keduanya.

---

## 1. Prinsip

- **Sedikit, lalu lebih sedikit.** Satu ide per layar. Elemen yang tidak membantu orang bertindak dihapus.
- **Merah adalah sinyal, bukan warna.** `accent` muncul paling banyak satu–dua kali per layar: titik "BARU", badge update (`+3`), aksi hapus. Switch dan pilihan aktif memakai `ink`, bukan merah.
- **Doto hanya untuk judul layar.** Judul (`BERANDA`, `JELAJAH`, `RIWAYAT`) dan nama aplikasi memakai Doto. Semua angka di dalam layar — chapter, rating, total, tahun, peringkat, progres — memakai `stat` (Geist 600).
- **Datar dan jujur.** Permukaan rata, hairline, titik, pill. Tanpa gradien, tanpa glass. Kedalaman dari tingkat permukaan (`bg` → `surface` → `surfaceRaised`); bayangan hanya `shadowFloat` untuk elemen yang melayang (bottom nav, menu).
- **Tipe komik bukan warna.** Manga / Manhwa / Manhua tidak lagi dibedakan biru/oranye/hijau; cukup label mono kecil.

## 2. Setup proyek

### 2.1 Font (dibundel, bukan dari jaringan)

Salin `assets/fonts/*` ke proyek, lalu di `pubspec.yaml`:

```yaml
flutter:
  fonts:
    - family: Geist
      fonts:
        - asset: assets/fonts/Geist-Regular.ttf
          weight: 400
        - asset: assets/fonts/Geist-Medium.ttf
          weight: 500
        - asset: assets/fonts/Geist-SemiBold.ttf
          weight: 600
    - family: GeistMono
      fonts:
        - asset: assets/fonts/GeistMono-Regular.ttf
          weight: 400
        - asset: assets/fonts/GeistMono-Medium.ttf
          weight: 500
    - family: Doto
      fonts:
        - asset: assets/fonts/Doto-Bold.ttf
          weight: 700
        - asset: assets/fonts/Doto-Black.ttf
          weight: 900
```

File TTF statis ini dibuat dari font variabel Geist, Geist Mono dan Doto (SIL Open Font License 1.1). `google_fonts` boleh tetap dipakai untuk font lain, tapi `GoogleFonts.rubik()` di `core/constants/theme.dart` diganti dengan family di atas.

### 2.2 Ikon: Lucide

> **Catatan implementasi:** aplikasi memakai `lucide_icons_flutter` varian weight 300 (`LucideIcons300`, stroke terukur 1.54) alih-alih SVG di bawah. Lihat `docs/REDESIGN_PLAN.md` D6.

Dotline memakai **Lucide** (ISC) dengan stroke **1.5**, ujung dan sambungan bulat. `solar_icons` diganti. Repo sudah punya `flutter_svg`, jadi cara paling akurat:

```yaml
flutter:
  assets:
    - assets/icons/lucide/
```

```dart
class DotIcon extends StatelessWidget {
  const DotIcon(this.name, {super.key, this.size = 24, this.color});
  final String name; // 'house', 'compass', 'bookmark', ...
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        'assets/icons/lucide/$name.svg',
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(
          color ?? IconTheme.of(context).color ?? Dotline.of(context).ink,
          BlendMode.srcIn,
        ),
      );
}
```

SVG di `assets/icons/lucide/` sudah diset `stroke-width="1.5"`. Ikon lain: unduh dari lucide.dev, ganti `stroke-width` menjadi `1.5`.

| Pemakaian | Lucide |
|---|---|
| Tab Beranda / Jelajah / Favorit / Riwayat / Lainnya | `house`, `compass`, `bookmark`, `history`, `ellipsis` |
| Cari, kembali, panah baris | `search`, `chevron-left`, `chevron-right` |
| Bagikan, urutkan, daftar chapter, pengaturan/filter | `share-2`, `arrow-down-up`, `list`, `sliders-horizontal` |
| Hapus, centang, tutup | `trash-2`, `check`, `x` |
| Baca, lanjut | `book-open`, `arrow-right` |
| Cadangkan, pulihkan, lapor bug, gambar | `database`, `rotate-ccw`, `bug`, `image` |

## 3. Token

### 3.1 Warna

Dark adalah tema utama (`bg` hitam murni untuk OLED). Light mencerminkannya di `#F2F2F2`.

| Token | Dark | Light | Dipakai untuk |
|---|---|---|---|
| `bg` | `#000000` | `#F2F2F2` | Latar setiap layar; list group di dalam bottom sheet |
| `surface` | `#111111` | `#FFFFFF` | Kartu, list group, sheet, menu, wadah segmented |
| `surfaceRaised` | `#1C1C1C` | `#E8E8E8` | Pressed, search field, placeholder cover, quick-action tile, track switch off, tombol disabled |
| `line` | `#FFFFFF` 12% | `#000000` 10% | Hairline antar baris (semi-transparan, terbaca di semua permukaan) |
| `lineStrong` | `#4A4A4A` | `#BDBDBD` | Tepi kontrol (chip, tombol outline), titik DotMeter yang mati. ⚠︎ di bawah 3:1 — jangan jadi satu-satunya penanda kontrol |
| `ink` | `#FFFFFF` | `#000000` | Teks/ikon utama; isi tombol primer, switch on, segmen/chip terpilih |
| `inkMuted` | `#A6A6A6` | `#4D4D4D` | Teks sekunder, thumb switch off |
| `inkFaint` | `#808080` | `#6B6B6B` | Caption, waktu, ikon tab tidak aktif (hanya di `bg`/`surface`) |
| `onInk` | `#000000` | `#FFFFFF` | Teks/ikon di atas `ink` |
| `accent` | `#E5211C` | `#D70015` | Sinyal sebagai isi: titik BARU, badge `+3`, tombol hapus |
| `onAccent` | `#FFFFFF` | `#FFFFFF` | Teks di atas `accent` |
| `accentText` | `#FF5A52` | `#D70015` | Teks merah: "Move to trash", "DIHAPUS", label BARU |
| `positive` | `#4AD991` | `#0B6B3C` | Konfirmasi (tersinkron, tetap) — selalu dengan kata/ikon |
| `focus` | `#FFFFFF` | `#000000` | Ring fokus 2px, offset 2px |
| `scrim` | `#000000` 72% | `#000000` 40% | Di belakang sheet dan dialog |
| `navBar` | `#1C1C1C` | `#E2E2E2` | Pill bottom nav |
| `navSelected` | `#3A3A3A` | `#FFFFFF` | Lingkaran tab aktif |

```dart
@immutable
class DotlineColors extends ThemeExtension<DotlineColors> {
  const DotlineColors({
    required this.bg, required this.surface, required this.surfaceRaised,
    required this.line, required this.lineStrong, required this.ink,
    required this.inkMuted, required this.inkFaint, required this.onInk,
    required this.accent, required this.onAccent, required this.accentText,
    required this.positive, required this.focus, required this.scrim,
    required this.navBar, required this.navSelected,
  });

  final Color bg, surface, surfaceRaised, line, lineStrong, ink, inkMuted,
      inkFaint, onInk, accent, onAccent, accentText, positive, focus, scrim,
      navBar, navSelected;

  static const dark = DotlineColors(
    bg: Color(0xFF000000), surface: Color(0xFF111111), surfaceRaised: Color(0xFF1C1C1C),
    line: Color(0x1FFFFFFF), lineStrong: Color(0xFF4A4A4A), ink: Color(0xFFFFFFFF),
    inkMuted: Color(0xFFA6A6A6), inkFaint: Color(0xFF808080), onInk: Color(0xFF000000),
    accent: Color(0xFFE5211C), onAccent: Color(0xFFFFFFFF), accentText: Color(0xFFFF5A52),
    positive: Color(0xFF4AD991), focus: Color(0xFFFFFFFF), scrim: Color(0xB8000000),
    navBar: Color(0xFF1C1C1C), navSelected: Color(0xFF3A3A3A),
  );

  static const light = DotlineColors(
    bg: Color(0xFFF2F2F2), surface: Color(0xFFFFFFFF), surfaceRaised: Color(0xFFE8E8E8),
    line: Color(0x1A000000), lineStrong: Color(0xFFBDBDBD), ink: Color(0xFF000000),
    inkMuted: Color(0xFF4D4D4D), inkFaint: Color(0xFF6B6B6B), onInk: Color(0xFFFFFFFF),
    accent: Color(0xFFD70015), onAccent: Color(0xFFFFFFFF), accentText: Color(0xFFD70015),
    positive: Color(0xFF0B6B3C), focus: Color(0xFF000000), scrim: Color(0x66000000),
    navBar: Color(0xFFE2E2E2), navSelected: Color(0xFFFFFFFF),
  );

  @override
  DotlineColors copyWith() => this;

  @override
  DotlineColors lerp(DotlineColors? o, double t) {
    if (o == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return DotlineColors(
      bg: l(bg, o.bg), surface: l(surface, o.surface), surfaceRaised: l(surfaceRaised, o.surfaceRaised),
      line: l(line, o.line), lineStrong: l(lineStrong, o.lineStrong), ink: l(ink, o.ink),
      inkMuted: l(inkMuted, o.inkMuted), inkFaint: l(inkFaint, o.inkFaint), onInk: l(onInk, o.onInk),
      accent: l(accent, o.accent), onAccent: l(onAccent, o.onAccent), accentText: l(accentText, o.accentText),
      positive: l(positive, o.positive), focus: l(focus, o.focus), scrim: l(scrim, o.scrim),
      navBar: l(navBar, o.navBar), navSelected: l(navSelected, o.navSelected),
    );
  }
}

/// Akses singkat: Dotline.of(context).ink
abstract final class Dotline {
  static DotlineColors of(BuildContext c) => Theme.of(c).extension<DotlineColors>()!;
}
```

### 3.2 Tipografi

| Style | Family | Ukuran / line-height | Weight | Tracking | Dipakai untuk |
|---|---|---|---|---|---|
| `dotM` | Doto | 32 / 36 | 700 | 0 | Judul layar KAPITAL: `BERANDA`, `JELAJAH` |
| `dotBrand` | Doto | 40 / 44 | 900 | 0.01em | Nama aplikasi di splash |
| `title` | Geist | 22 / 28 | 500 | −0.01em | Judul sheet, "Chapter 67 selesai", judul section |
| `stat` | Geist | 32 / 36 | 600 | −0.02em | Angka di stat tile (`6`, `431`), nomor chapter Lanjut baca (28px) |
| `statS` | Geist | 24 / 32 | 600 | −0.01em | Tiga stat sejajar (`7.50 · 49 · 2018`) |
| `headline` | Geist | 17 / 24 | 500 | 0 | Judul baris, tombol besar |
| `body` | Geist | 15 / 22 | 400 | 0 | Paragraf, sinopsis, tombol |
| `bodyS` | Geist | 13 / 18 | 400 | 0 | Subjudul baris, judul di grid cover |
| `label` | GeistMono | 11 / 14 | 400 | 0.12em | Overline, chip, segmen, label tipe — **selalu KAPITAL** (`.toUpperCase()`) |
| `data` | GeistMono | 13 / 18 | 400 | 0 | `CH. 49`, `12 mnt`, path, hitungan |

Doto tidak pernah di bawah 24px dan tidak untuk paragraf atau angka statistik.

```dart
abstract final class DotlineText {
  static TextStyle _s(String f, double size, double lh, FontWeight w, [double ls = 0]) =>
      TextStyle(fontFamily: f, fontSize: size, height: lh / size, fontWeight: w, letterSpacing: ls * size);

  static final dotM     = _s('Doto', 32, 36, FontWeight.w700);
  static final dotBrand = _s('Doto', 40, 44, FontWeight.w900, .01);
  static final title    = _s('Geist', 22, 28, FontWeight.w500, -.01);
  static final stat     = _s('Geist', 32, 36, FontWeight.w600, -.02);
  static final statS    = _s('Geist', 24, 32, FontWeight.w600, -.01);
  static final headline = _s('Geist', 17, 24, FontWeight.w500);
  static final body     = _s('Geist', 15, 22, FontWeight.w400);
  static final bodyS    = _s('Geist', 13, 18, FontWeight.w400);
  static final label    = _s('GeistMono', 11, 14, FontWeight.w400, .12);
  static final data     = _s('GeistMono', 13, 18, FontWeight.w400);
}
```

### 3.3 Spasi, radius, ukuran, bayangan

| Spasi | Nilai | Dipakai untuk |
|---|---|---|
| `s1` | 4 | Label ↔ nilai, celah titik meter |
| `s2` | 8 | Antar chip, ikon ↔ label |
| `s3` | 12 | Antar kartu/kolom grid, padding baris ringkas |
| `s4` | 16 | Margin samping layar, padding grup |
| `s5` | 24 | Antar section |
| `s6` | 32 | Di bawah judul layar `dotM`, padding bawah sheet |
| `s7` | 48 | Ruang di atas angka hero |

| Radius | Nilai | Dipakai untuk |
|---|---|---|
| `s` | 8 | Thumbnail kecil (44×60) |
| `cover` | 12 | Cover di grid 3 kolom |
| `m` | 16 | List group, search field, cover besar, quick tile |
| `tile` | 20 | Stat tile pendek, kartu chapter berikutnya |
| `l` | 28 | Kartu Lanjut baca, sheet (atas), menu, dialog |
| `pill` | 999 | Tombol, chip, segmented, switch, bottom nav |

| Ukuran | Nilai |
|---|---|
| Touch target minimum | 48 |
| Titik (`dot`) / jarak titik (`dotPitch`) | 4 / 8 |
| Stroke ikon & tepi kontrol | 1.5 |
| Tinggi pill bottom nav | 64 (padding 6, lingkaran tab 52) |
| Tinggi baris minimum | 56 |
| Ikon | 24 (menu 22, kecil 20) |

`shadowFloat` = `BoxShadow(color: Color(0x80000000), offset: Offset(0, 8), blurRadius: 24)` — hanya untuk bottom nav, pill navigasi chapter dan menu. Sheet, dialog dan kartu tidak berbayang.

### 3.4 Gerak

- Tekan dan toggle: **140 ms** `Curves.easeOut`; tombol mengecil ke `0.97` saat ditekan. Tanpa ripple Material (`splashFactory: NoSplash.splashFactory`).
- Indikator pilihan **bergeser**, tidak melompat: lingkaran tab nav dan pill segmented bergerak dengan pegas lembut tanpa overshoot (~300 ms). Di Flutter: `AnimatedPositioned`/`AnimatedAlign` dengan `Curves.easeOutCubic`, `Duration(milliseconds: 320)`; warna ikon/teks cross-fade lewat `AnimatedDefaultTextStyle`/`TweenAnimationBuilder<Color?>`.
- Sheet naik dari bawah (bawaan `showModalBottomSheet`), menu fade + scale 0.96 → 1 dari pemicunya.
- Hormati `MediaQuery.disableAnimationsOf(context)`.

## 4. ThemeData

```dart
ThemeData dotlineTheme(DotlineColors c, Brightness b) => ThemeData(
  useMaterial3: true,
  brightness: b,
  fontFamily: 'Geist',
  scaffoldBackgroundColor: c.bg,
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  colorScheme: ColorScheme(
    brightness: b,
    primary: c.ink, onPrimary: c.onInk,
    secondary: c.ink, onSecondary: c.onInk,
    error: c.accent, onError: c.onAccent,
    surface: c.surface, onSurface: c.ink,
    surfaceContainerHighest: c.surfaceRaised,
    outline: c.lineStrong, outlineVariant: c.line,
  ),
  dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
  progressIndicatorTheme: ProgressIndicatorThemeData(color: c.ink),
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: c.surface, modalBackgroundColor: c.surface,
    elevation: 0, modalElevation: 0, surfaceTintColor: Colors.transparent,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    showDragHandle: false,
  ),
  extensions: [c],
);

// MaterialApp(theme: dotlineTheme(DotlineColors.light, Brightness.light),
//             darkTheme: dotlineTheme(DotlineColors.dark, Brightness.dark),
//             themeMode: settings.themeMode) // Sistem / Terang / Gelap
```

## 5. Komponen

Nama di kiri = nama di Dotline; di kanan cara membangunnya di Flutter.

**Judul layar** — `Text('JELAJAH', style: DotlineText.dotM)` di kiri atas, padding atas 24, di bawahnya `data` `inkFaint` untuk konteks ("6 komik · 2 ada update"). Aksi di kanan: tombol bulat 48 `surface` berisi ikon 20–24.

**Bottom nav (FloatingNavBar)** — pill `navBar` tinggi 64, padding 6, lima tab ikon saja (Beranda, Jelajah, Favorit, Riwayat, Lainnya), tanpa label teks; nama tab lewat `Semantics(label:)`. Lingkaran `navSelected` 52px di belakang tab aktif digeser dengan `AnimatedPositioned`; ikon aktif `ink`, lainnya `inkFaint`. Melayang `12` di atas inset navigasi sistem, dengan `shadowFloat`; tanpa band/latar penuh di belakangnya. Daftar yang bisa di-scroll menambah padding bawah setinggi nav. Sembunyikan saat keyboard terbuka. Pakai `Stack` di `RootScreen` (ganti `NavigationBar`/`NavigationRail`).

**Segmented control** — wadah `surface` pill, padding 4; segmen tinggi 40 berteks `label`; pill `ink` bergeser ke segmen terpilih (`AnimatedAlign` di belakang `Row` segmen `Expanded`), teks terpilih `onInk`, lainnya `inkMuted`. Dipakai: tipe di Jelajah, filter Favorit, tema di Lainnya, arah baca & ukuran halaman.

**Chip** — pill tinggi 36, tepi 1.5 `lineStrong`, teks `label`. Terpilih: isi `ink`, teks `onInk`, ikon `check` 14 di depan (filter multi-pilih genre).

**Tombol** — pill, tinggi 56 (besar) / 48 (sedang). Primer: `ink`/`onInk`. Outline: transparan, tepi 1.5 `lineStrong`. Hapus: `accent`/`onAccent`. Disabled: **tidak diburamkan** — primer jadi `surfaceRaised` + teks `inkFaint`, outline jadi tepi `line` + teks `inkFaint`.

**Switch** — 52×32, thumb 26 berjarak 3 dari tepi. On: track & tepi `ink`, thumb `onInk` di kanan. Off: track `surfaceRaised`, tepi `lineStrong`, thumb `inkMuted` di kiri. Disabled: opacity 0.4. Bangun sendiri dengan `AnimatedContainer` + `AnimatedAlign` (140 ms); `Switch` Material tidak cocok bentuknya.

**List group & ListRow** — `Container(color: surface, borderRadius: 16)` + `ClipRRect`; baris min 56, padding 12×16, ikon 24 `ink` → judul `headline` + subjudul `bodyS inkMuted` → nilai `data` atau `chevron-right` 20 `inkFaint`. Hairline `line` 1px di antara baris. Baris hapus: ikon + judul `accentText`, subjudul menjelaskan dampaknya. Di dalam sheet, grup memakai `bg`.

**Bottom sheet** — `showModalBottomSheet(isScrollControlled: true, barrierColor: c.scrim, ...)`; panel `surface`, sudut atas 28, tanpa elevasi. Pegangan: lima titik 4px `lineStrong` berjarak 4, 12 dari atas. Isi kolom padding 16, gap 16, bawah 32. Pola action sheet: header (tile ikon 48 `surfaceRaised` radius 16 + `title` + subjudul `data`) → quick-action tile (tinggi 72, `surfaceRaised`, radius 16, ikon 22 di atas `label`) → list group `bg` dengan baris hapus terakhir. Contoh di layar: Filter, Bersihkan cache, Pengaturan baca.

**Menu (dropdown)** — `MenuAnchor` dengan `MenuStyle`: lebar 248, `surface`, radius 28, tepi 1px `line`, `shadowFloat`. Baris 52, padding horizontal 24, ikon 22 + `body`; hairline di antara baris; baris hapus terakhir `accentText`. Pemicu: tombol bulat 48 ⋮ (`ellipsis` vertikal) yang jadi `surfaceRaised` saat terbuka.

**DotMeter (progres titik)** — baris titik 4px dengan gap 3–4: menyala `ink`, mati `lineStrong`. Jumlah titik = presisi yang dibutuhkan (12 di Favorit, 10 di Riwayat, 22 di Lanjut baca, 24 = jumlah halaman di pembaca). `Semantics(value: '12 dari 24')`.

**Cover** — rasio 2:3, radius 12 (grid) / 16 (detail). Saat memuat: `surfaceRaised` dengan grid titik samar (`CustomPainter`, titik r=1 tiap 8px, putih 16%) sebagai placeholder `CachedNetworkImage`, bukan shimmer/gradien. Label tipe di pojok kiri atas: pill hitam berteks `label` 10px.

**Penanda baru / update** — titik `accent` 6px + `label` `accentText` "BARU"; jumlah chapter baru di Favorit: pill `accent` berteks `data` putih "+3".

**Stat tile** — `surface`, radius 16–20, padding 12–16; `label inkFaint` di atas/bawah angka `stat`/`statS`.

**Search field** — pill `surfaceRaised` tinggi 52, padding 18, ikon `search` 20 `inkMuted`, teks `body`, placeholder `inkFaint`.

**Swipe hapus (Riwayat)** — `flutter_slidable` (sudah ada di proyek): aksi 96px isi `accent`, ikon `trash-2` + `label` "HAPUS" putih.

## 6. Peta layar → kode Flutter

> **Catatan implementasi.** Path di tabel ini memakai struktur lama (`lib/presentation/...`). Path yang benar ada di `docs/REDESIGN_PLAN.md` §3. Ikon diimplementasikan dengan package `lucide_icons_flutter` (`LucideIcons300`), bukan SVG + `DotIcon` (lihat §2.2 dan keputusan D6 di plan).

| PNG | Layar | File yang diubah / dibuat |
|---|---|---|
| `01-splash` | Splash | `screens/initial/splash/splash_screen.dart` (+ `flutter_native_splash`: latar `#000000`, gambar `assets/images/splash-art.webp`) |
| `02-beranda` | Beranda | `screens/main/home/home_screen.dart`, `widgets/last_read_comic.dart` (kartu Lanjut baca + DotMeter), `comic_slider*.dart` (Hot komik bernomor 01–03), `latest_chapter*.dart` |
| `03-detail-komik` | Detail komik | `screens/sub/comic_details/*` — cover tengah, 3 stat tile, chip genre outline, daftar chapter (BARU / sudah dibaca ✓), bar bawah bookmark + "Lanjut baca · Ch. N" |
| `04-jelajah` | Jelajah | `screens/main/explore/*` — search pill, segmented tipe, tombol Filter + jumlah filter aktif, grid 3 kolom |
| `05-filter-sheet` | Filter | `explore/widgets/filter_comic.dart` → bottom sheet (bukan halaman); tipe/status/urutan single-select, genre multi-select |
| `06-favorit` | Favorit | `screens/main/bookmarks/*` — segmented Semua / Ada update / Selesai, badge `+N`, DotMeter dibaca |
| `07-riwayat` | Riwayat (tab) | pindah dari `screens/sub/history/` ke tab utama ke-4; dikelompokkan per hari, swipe hapus |
| `08-lainnya` | Lainnya | `screens/main/more/*` — tanpa kartu akun; 2 stat tile, grup Data, segmented Tema, Tentang |
| `09-bersihkan-cache-sheet` | Konfirmasi cache | sheet baru dari baris "Bersihkan cache" |
| `10-baca-chapter` | Pembaca | `screens/sub/read_chapter/*` — tap halaman untuk tampil/sembunyi kontrol; bar atas + pill navigasi chapter dengan DotMeter halaman |
| `11-pengaturan-baca-sheet` | Pengaturan baca | sheet baru: arah baca, ukuran halaman, layar tetap menyala, jarak antar halaman (simpan di `SettingsCubit`) |
| `12-akhir-chapter` | Akhir chapter | item terakhir di list pembaca: "Chapter N selesai" + kartu chapter berikutnya + tombol |
| `13-ikon-perbandingan` | Ikon aplikasi | dipilih **B · Panel** — lihat `app-icon/` |

`RootScreen`: lima tab = Beranda, Jelajah, Favorit, **Riwayat**, Lainnya. Baris "Riwayat baca" di Lainnya dihapus.

## 7. Bersih-bersih dari tema lama

- `core/constants/colors.dart`: hapus `primary` biru `#2565C7`, `mangaColor` / `manhwaColor` / `manhuaColor`, `rating`. Ganti dengan `DotlineColors`.
- `core/constants/theme.dart`: ganti `ColorScheme.fromSeed(...)` + Rubik dengan `dotlineTheme(...)` di atas.
- `solar_icons` → Lucide (`DotIcon`). Setelah semua layar pindah, dependensi `solar_icons` bisa dihapus.
- Sapaan berbasis akun ("Selamat siang, KuroNeko") dan kartu akun dihapus — aplikasi tidak memakai akun.

## 8. Ikon aplikasi (B · Panel)

`app-icon/android/app/src/main/res/` siap menimpa folder yang sama di proyek:

- `mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher_{background,foreground,monochrome}.png` — adaptive icon 108dp; glyph 52dp di tengah, di dalam safe zone 66dp.
- `ic_launcher.png` / `ic_launcher_round.png` — untuk Android < 8.
- `mipmap-anydpi-v26/ic_launcher.xml` & `ic_launcher_round.xml` — dengan `<monochrome>` untuk themed icon Material You (Android 13+).
- `playstore-icon-512.png`.

Jangan jalankan `flutter_launcher_icons` setelah menimpa, karena akan menulis ulang file ini.

## 9. Lisensi aset

- Geist, Geist Mono — © 2024 The Geist Project Authors, SIL Open Font License 1.1.
- Doto — © 2024 The Doto Project Authors, SIL Open Font License 1.1.
- Lucide — ISC License (lihat `assets/icons/lucide/LICENSE`).
- `splash-art.webp` — potongan dari `assets/images/splash.png` milik proyek (bingkai abu-abu dibuang).
