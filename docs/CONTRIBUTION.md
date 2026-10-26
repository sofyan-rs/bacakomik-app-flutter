# Contribution guide

Recipes for working on BacaKomik. Read [ARCHITECTURE.md](ARCHITECTURE.md) once first.

§ numbers refer to this file; "ARCHITECTURE §n" to the other one.

---

## 1. One-time setup

1. Install **Flutter** stable with **Dart 3.13+**, the Android SDK (platform 37) and **JDK 17**. Run `flutter doctor` until it is clean.
2. Use a device or emulator on Android 7.0+ (API 24); test on a recent one (API 34+) too. Mihon extensions need Android 9+ (API 28). Cloudflare sources and Cronet need Google Play services.
3. For extension work: [Bun](https://bun.sh) and access to the private `bacakomik-ext-source` repo. To write your own extension without that access, use the public extension source, [sofyan-rs/bacakomik-ext-public-source](https://github.com/sofyan-rs/bacakomik-ext-public-source), served at `https://sofyan-rs.github.io/bacakomik-ext-public-source/index.json`.

There is no server to configure. Content comes from the bundled extensions and the default repo `https://bacakomik-ext.kurodev.org/index.json`.

---

## 2. Build, run and recipes

```bash
flutter pub get
dart run build_runner build -d   # after changing @freezed, @JsonSerializable, injectable annotations or assets
flutter run                      # emulator or test device only, see Recipe G
flutter analyze                  # must say "No issues found!"
flutter test
```

Generated files are committed: **commit them with the change that caused them.**

### Recipe A: Add a screen or feature
1. Create `lib/features/<name>/` with the layers it needs (ARCHITECTURE §3).
2. Domain first: entity, repository interface, use cases. Put real rules here.
3. Data: data source and `*RepositoryImpl` (`@LazySingleton(as: …)`, `runRemote` / `runLocal`).
4. Presentation: bloc or cubit (`@injectable`), provided by its screen; page built from Dotline widgets, strings in `AppText` (ARCHITECTURE §5).
5. Run `build_runner`, add tests (§5), run analyze, test and the domain grep.
6. Update ARCHITECTURE.md (§3, §6, §7.1) if the design changed.

Example: `migration` has `ImportLibrary` (domain), `PendingReadRepositoryImpl` (data), `MatchCubit` and `MatchScreen` (presentation).

### Recipe B: Add a field to stored data
1. Make it **nullable or defaulted**, so existing data still parses. Never rename or remove a field (§4).
2. Add it to the model and entity, map it in `fromEntity` / `toEntity`, run `build_runner`.
3. If the backup or sync format changes, bump its `formatVersion` (ARCHITECTURE §7.4, §7.6) and say in the PR whether old files still load.
4. Test that old JSON without the field parses, then do the upgrade test (Recipe G).

### Recipe C: Add a source method or host function
- **Source method:** change the contract in `bacakomik-ext-source` (`types/bridge.d.ts`), then call it from `SeriesRemoteDataSource` with a DTO (`toEntity()`), passing comic keys. Test with `FakeSourceBackend`.
- **Host function:** handle it in `ExtensionBridge.handle` and add it to the `ExtensionRuntime` prelude. **If old apps can't run scripts that use it, bump `supportedExtensionApi`.**

### Recipe D: Try an unpublished extension in the app
1. In the extension repo: `bun run build` (validates `src/`, writes `dist/`). `bun scripts/run.ts <id> smoke` tests one outside the app.
2. Serve `dist/`:
   ```bash
   cd dist && bun -e "Bun.serve({port:8787, fetch(r){const p=new URL(r.url).pathname; return new Response(Bun.file('.'+(p==='/'?'/index.json':p)))}})"
   ```
3. `adb reverse tcp:8787 tcp:8787`, then in the app add the repo `http://localhost:8787/index.json` (More → Extensions → repos button) and install.

**Bump the extension's `version` for every change** the app should pick up, including a new or changed `urlPatterns` (installed extensions keep the metadata they were installed with). Remove the local repo afterwards. Script `log()` shows in logcat as `[<sourceId>] …`.

### Recipe E: Ship newer bundled extensions
```bash
# in bacakomik-ext-source
bun run build
bun scripts/bundle.ts ../bacakomik-app-flutter/assets/extensions bacakomik voratoon
```
`bundle.ts` replaces the folder and writes its `index.json`. Run `build_runner` (asset names change) and commit. Phones replace a bundled extension only when the bundled `version` is newer.

### Recipe F: Publish a release
1. Bump `version:` in `pubspec.yaml` (e.g. `1.6.0+13`); **the build number after `+` must increase.**
2. Optionally write `.github/release-notes/v1.6.0.md` (otherwise notes come from commits).
3. Commit, then `git tag v1.6.0 && git push origin v1.6.0`.

`.github/workflows/release.yml` checks the tag against the pubspec, runs analyze and tests, and publishes signed `arm64-v8a`, `armeabi-v7a`, `x86_64` and universal APKs as `BacaKomik-<version>-<abi>.apk` with a "Which APK?" table. **Don't rename the assets or that heading**: installed apps find updates through them.

Secrets (Settings → Secrets → Actions): `KEYSTORE_BASE64` (`base64 -w0 upload-keystore.jks`), `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`. Local signing reads `android/key.properties` (git-ignored: `storeFile`, `storePassword`, `keyAlias`, `keyPassword`). **Back up the keystore and password**; without them no update can ship. By hand: `flutter build apk --release --split-per-abi` (per ABI), `flutter build apk --release` (universal), `flutter build appbundle --release`.

### Recipe G: Test on a phone with real data
> **Never `flutter run` on a phone whose library you want to keep.** On a versionCode mismatch it uninstalled the app first and wiped its bookmarks, history and downloads.

1. Install over the existing app; `-r` keeps the data:
   ```bash
   flutter build apk --release --split-per-abi
   adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
   ```
   The APK must be signed with the same key (Recipe F). Drive sign-in only works with a key whose SHA-1 is registered as an Android OAuth client (`AppVariables.googleServerClientId`).
2. **Upgrade test** (any storage, backup or sync change): install the current release, add bookmarks, categories and history, install the new build with `adb install -r`, check nothing is lost.
3. **Logs:** release builds log `debugPrint` under the `flutter` tag. On phones with a small buffer, stream to a file before reproducing, and restart it after each reinstall:
   ```bash
   adb logcat -s flutter > flutter.log
   ```

### Recipe H: Work on Mihon extension support
Mihon extensions run in Kotlin, in `android/mihon` (ARCHITECTURE §8.9).

1. **Kotlin tests** (no device): `cd android && ./gradlew :mihon:testDebugUnitTest` (chapter numbers, synopsis parsing, filters). Results in `build/mihon/test-results/`. Dart side: `flutter test test/core/mihon_test.dart`.
2. **Always try a release build** (Recipe G): R8 runs only there, and a class it strips that an extension or native code needs only fails on the phone (an abort in `logcat -b crash`). Add keep rules to `android/mihon/consumer-rules.pro`.
3. **On the phone:** add a Mihon repo (e.g. Keiyoushi's `index.min.json`), install two or three extensions (one HTML site, one API site, one behind Cloudflare), then Home, Explore search and filters, comic page, reader, download, settings, uninstall. For the Mihon import, a small `.tachibk` pushed to `/sdcard/Download` works; don't import test data into a library you keep.
4. **Vendored code** (`eu/`, `mihon/`, `tachiyomi/`) comes from SCANCORE's `host/api` and keeps Mihon's package names, as extensions link against them. The host in `org/kurodev/bacakomik/mihon/host/` started as SCANCORE's `host/` (package `com.mediumdev.scancore.host`) and is now the app's own; porting a SCANCORE fix means diffing by hand (changes are marked `BACAKOMIK`). library versions in `android/mihon/build.gradle` follow Mihon's, and a new extension lib version goes into both `AndroidLoader.libs` and `supportedMihonLibs`.

---

## 3. Project map

Folders are explained in ARCHITECTURE §3. Shared test fakes are in `test/helpers/`, sample data in `test/fixtures/`. Extensions live in the private `bacakomik-ext-source` repo; a public extension source with its own set of extensions is [sofyan-rs/bacakomik-ext-public-source](https://github.com/sofyan-rs/bacakomik-ext-public-source).

Reading order: run the app; ARCHITECTURE §3–§4; `features/home/` end to end (entity → repository → use case → `HomeBloc` → `HomeScreen`); ARCHITECTURE §8 with `core/source/`; `comic_list_state.dart` and `latest`; `features/bookmark/` and `core/storage/` with ARCHITECTURE §7.

---

## 4. Rules

**Code**
- `flutter analyze` clean (`flutter_lints`). `dart format` new files; in old files format only what you change (ARCHITECTURE §12).
- `package:bacakomik_app/...` imports. Comment *why*; `///` on public and non-obvious things.
- No `!` on values that can be null, no empty `catch`: return a `Failure` or `debugPrint`.
- Strings in `AppText`, colours from `Dotline.of(context)`.

**Layers and blocs**
- Domain is plain Dart (ARCHITECTURE §3 grep). Repositories return `Either` via `runRemote` / `runLocal`.
- Sources only through `SeriesRemoteDataSource` + DTOs; pass comic keys, never bare slugs. Site logic belongs in extensions.
- Register with injectable (except tests and `lib/app/`).
- Freezed sealed states (`initial / loading / loaded / error / noInternet`), errors via `SourceError`; events named after what happened.
- Screen-only blocs are provided by the screen (ARCHITECTURE §4.2). Widgets call blocs, never use cases or repositories. No work in `build()`.

**Data safety (non-negotiable)**

| Rule | Why |
|---|---|
| **Never rename or remove a stored JSON field** without a migration; new fields are nullable or defaulted (ARCHITECTURE §7.2) | Existing data must parse |
| **Never change the comic key format** or an extension `id` (ARCHITECTURE §8.1) | Keys are in the library, history, downloads, backups, sync |
| **Never write a Hive key that is non-ASCII or over 255 characters**; use `JsonBox` or `isValidHiveKey` (ARCHITECTURE §7.1) | Release builds corrupt the whole box. Keys from source data (slugs, titles) are the usual culprit |
| **Backup format change → bump `BackupRepositoryImpl.formatVersion`**; say whether old files restore | Old files must not restore wrongly |
| **Sync format change → bump `SyncRepositoryImpl.formatVersion`** | Other devices may run the old version |
| User writes go through repositories; sync writes through data sources | `LibraryJournal` records user writes for sync |
| Storage, backup or sync change → upgrade test (Recipe G) | Only proof nothing is lost |

---

## 5. Testing

| What | How |
|---|---|
| Remote repositories | `FakeSourceRegistry` / `FakeSourceBackend` (`test/helpers/fake_source.dart`) with `test/fixtures/api_fixtures.dart` and `FakeNetworkInfo`; assert entities and recorded calls |
| Local repositories | Real Hive in a temp dir: `setUpTempHive()` (`test/helpers/hive.dart`) |
| Use cases / blocs | mocktail; `bloc_test` with mocked or real use cases |
| Sources | `test/core/source_test.dart` |
| Storage, backup, sync | `library_test`, `backup_test`, `sync_test`, `migrate_library_test` (`test/fixtures/library_fixtures.dart`); `test/core/box_recovery_test.dart` salvages a hand-built corrupt box |
| Migration | `test/features/migration_test.dart` (Mihon protobuf, `urlPatterns`, CSV, `ImportLibrary`, pending reads) with `MemoryPendingReads` |
| Mihon extensions | `test/core/mihon_test.dart` (repos, `index_v2` stores, ids, `MihonSource` with a fake host, error mapping, import matching); Kotlin unit tests in `android/mihon/src/test` (Recipe H) |
| Manual | Every screen on a recent Android before a release, one Cloudflare source, one download, one Mihon extension (release build), plus the upgrade test when storage changed |

**Every bug fix gets a regression test** where possible. The JS engine, WebViews and Cronet don't run in `flutter test`: fake them, and test scripts in the extension repo.

---

## 6. Errors and logging

Data layer throws, repositories return `Failure`, blocs show `noInternet` or `SourceError` (ARCHITECTURE §9). Log with `debugPrint`, never `print`, and **never log full backup or sync contents**. Phone logs: Recipe G.

---

## 7. Dependencies

- Add a package only if it is maintained, works on Android 7.0+, and is needed.
- `freezed`, the generators and `hive_ce` are pinned (ARCHITECTURE §10.1): upgrade in their own PR, regenerate, run all tests. Same for Flutter itself.
- `flutter_inappwebview` (6.2 beta), `flutter_js`, `native_dio_adapter`, `cronet_http`: upgrades need a device test on a Cloudflare source.
- **Mihon (`android/mihon/build.gradle`):** OkHttp, kotlinx.serialization, coroutines, Jsoup, RxJava 1, Injekt and QuickJS (from jitpack, `zhanghai/quickjs-java`) follow Mihon's versions, because extensions are compiled against them. Kotlin is 2.4.21 for the whole build; the module applies the serialization plugin with its own version (`background_downloader` pins another). Upgrade them only together with Mihon and test a release build (Recipe H).
- **`flutter_local_notifications` needs `ActionBroadcastReceiver` declared in `android/app/src/main/AndroidManifest.xml`.** Without it the refresh Cancel button does nothing.

---

## 8. Git and pull requests

- Branch from `main` (`feat/…`, `fix/…`, `refactor/…`, `docs/…`, `chore/…`). [Conventional Commits](https://www.conventionalcommits.org/): `feat(reader): remember scroll position`, `fix(backup): accept missing history`. One feature or fix per PR.

PR checklist (also in `.github/pull_request_template.md`):

- [ ] `flutter analyze` and `flutter test` pass.
- [ ] Code regenerated with `build_runner` and committed, if annotations changed.
- [ ] New domain logic and repositories have tests.
- [ ] Data-safety rules (§4) respected; storage/backup/sync changes tested with an upgrade install.
- [ ] UI checked in light and dark theme, on a phone and on a wide screen if layout changed.
- [ ] Bundled extensions updated (§2) if the change needs newer extension versions.
- [ ] ARCHITECTURE.md updated if the design changed.

---

## 9. Scope guard

BacaKomik is a reader: **browse comics from installed sources, read chapters, keep a library on the device** (optionally synced via the user's Drive). New sites are extensions. Accounts, a server-side library or site code in the app start as a discussion issue, not a PR. Changes to stored data, backup or sync need a migration plan first.
