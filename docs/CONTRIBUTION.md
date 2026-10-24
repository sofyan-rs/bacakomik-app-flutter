# Contributing

How to set up, build, and work on BacaKomik. Read [ARCHITECTURE.md](ARCHITECTURE.md) before a non-trivial change.

---

## 1. Prerequisites

- **Flutter** (current stable) with **Dart 3.13+**. Check with `flutter --version`.
- **Android Studio** or the Android SDK command-line tools, with platform 37 and current build-tools. Run `flutter doctor` and fix what it reports.
- **JDK 17** for Gradle.
- A device or emulator on Android 7.0+ (API 24). Test on at least one recent Android (API 34+). Cloudflare-protected sources and Cronet need a device or emulator with Google Play services.
- For extension work: [Bun](https://bun.sh) and access to the private `bacakomik-ext-source` repo (§5.1).

---

## 2. Build and run

```bash
flutter pub get
dart run build_runner build -d      # regenerate freezed / json / injectable / assets code
flutter run                         # debug build on an emulator or a test device (not a phone with real data, see below)
flutter analyze                     # must report "No issues found!"
flutter test                        # unit and bloc tests, no device needed
```

`build_runner` has to run after you change anything annotated with `@freezed`, `@JsonSerializable`, `@injectable`/`@LazySingleton`/`@module`, or the assets. Generated files are committed, so commit them with the change that caused them.

There is no API server to configure. Content comes from extensions (ARCHITECTURE §8): the bundled ones in `assets/extensions/` and the default repo `https://bacakomik-ext.kurodev.org/index.json`. To try extensions that are not published yet, see §5.1.

### Testing on a phone with real data

> **Never use `flutter run` on a phone whose library you want to keep.** When the installed app's versionCode did not match, `flutter run` uninstalled the app before installing, which wiped its bookmarks, history and downloads.

Build a release APK and install it over the existing app instead. `adb install -r` keeps the app's data:

```bash
flutter build apk --release --split-per-abi
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

This needs `android/key.properties` (below): the APK must be signed with the same key as the installed app, or Android refuses the update. Google Drive sign-in also only works in APKs signed with a key whose SHA-1 is registered as an Android OAuth client in the Google Cloud project (`AppVariables.googleServerClientId`).

### Updating the bundled extensions

The app ships some extensions in `assets/extensions/` so it works before any repo is reachable (ARCHITECTURE §8.2). To ship newer versions, build them in the extension repo and copy them over:

```bash
# in bacakomik-ext-source
bun run build
bun scripts/bundle.ts ../bacakomik-app-flutter/assets/extensions bacakomik voratoon
```

`bundle.ts` replaces everything in the target folder and writes a matching `index.json`. Commit the result. Installed apps replace a bundled extension only when the bundled `version` is newer.

### Release builds

`flutter build apk --release --split-per-abi` builds signed per-ABI APKs, `flutter build apk --release` a universal one, and `flutter build appbundle --release` an `.aab`. Signing comes from `android/key.properties` (git-ignored) with `storeFile`, `storePassword`, `keyAlias`, `keyPassword`. Back up the keystore and its password: without them no update can be published for the same app id.

Before a release, bump `version:` in `pubspec.yaml`. The build number after `+` must increase.

### Publishing a release

Releases are built by `.github/workflows/release.yml` when a `v*` tag is pushed:

1. Bump `version:` in `pubspec.yaml` (for example `1.6.0+13`).
2. Write the notes in `.github/release-notes/v1.6.0.md` (optional; without it GitHub generates notes from the commits).
3. Commit, then `git tag v1.6.0 && git push origin v1.6.0`.

The workflow checks that the tag matches the pubspec version, runs analyze and tests, builds signed `arm64-v8a`, `armeabi-v7a`, `x86_64` and universal APKs, and publishes them as `BacaKomik-<version>-<abi>.apk` with a "Which APK?" table appended to the notes. Installed apps find the release through the GitHub API (ARCHITECTURE §1), so do not rename the assets or that heading.

It needs these repository secrets (Settings → Secrets and variables → Actions):

| Secret | Value |
|---|---|
| `KEYSTORE_BASE64` | The keystore file, base64-encoded (`base64 -w0 upload-keystore.jks`) |
| `KEYSTORE_PASSWORD` | `storePassword` |
| `KEY_ALIAS` | `keyAlias` |
| `KEY_PASSWORD` | `keyPassword` |

---

## 3. Project structure

See ARCHITECTURE §3. In short:

- `lib/app/`: app shell, splash, root tabs (`RootTabs`).
- `lib/core/`: DI, errors, network and image cache, sources and extensions (`core/source/`), Hive storage, notifications, shared entities/DTOs/widgets, constants.
- `lib/features/<name>/{domain,data,presentation}`: one folder per feature.
- `android/app/src/main/kotlin/…/MainActivity.kt`: the `bacakomik/hidden_webviews` channel (ARCHITECTURE §8.5).
- `hosting/`: Cloudflare Worker for the shared-link host `bacakomik.kurodev.org`.
- `test/`: mirrors `lib/`. Shared fakes are in `test/helpers/` and sample data in `test/fixtures/`.
- `docs/`: this guide and ARCHITECTURE.md.

Extensions themselves live in the separate private repo `bacakomik-ext-source`, with the extension contract in `types/bridge.d.ts`.

### Reading order for newcomers

1. Run the app and click through every tab (what it does).
2. ARCHITECTURE.md §3–§4.
3. `features/home/` end to end: entity → repository → use case → `HomeBloc` → `HomeScreen`. Every remote feature follows this pattern.
4. ARCHITECTURE §8 and `core/source/`: how a repository call reaches an extension.
5. `core/presentation/bloc/comic_list_state.dart` and one of the paginated features (`latest`).
6. `features/bookmark/` and `core/storage/` for local data, then ARCHITECTURE §7.

---

## 4. Code conventions

### General
- Follow `flutter_lints` (`analysis_options.yaml`). `flutter analyze` must be clean.
- Run `dart format` on new files. In existing files, format only what you change, so diffs stay readable (see ARCHITECTURE §12).
- Use full `package:bacakomik_app/...` imports, not relative ones.
- Comment *why*, not *what*. Use `///` docs on public types and on anything non-obvious (formats, ordering, compatibility).
- Don't use `!` on values that can really be null, and don't swallow errors with an empty `catch`. Return a `Failure` or log with `debugPrint` (§6).
- UI text is English and goes in `AppText`; colours come from `Dotline.of(context)`. No inline strings or colour literals in widgets.

### Layers
- Domain code is plain Dart: no Flutter, Dio, Hive, `dart:io` or file_picker. Run the grep in ARCHITECTURE §3.
- Repositories return `Either<Failure, T>`. Use `runRemote` for source calls and `runLocal` for storage.
- Source calls go through `SeriesRemoteDataSource`, with a DTO that has `toEntity()`. Widgets never see DTOs. Pass comic keys (`ComicKey`), never bare source slugs.
- Site-specific logic belongs in an extension, not in the app. A change to the host functions or the contract must stay compatible with installed extensions, or bump `supportedExtensionApi` (ARCHITECTURE §8.2).
- Register new classes with injectable annotations instead of building them by hand. The only exceptions are tests and `lib/app/`.

### Bloc patterns
- States are freezed sealed unions. Remote screens use `initial / loading / loaded / error / noInternet`, and show errors with `SourceError`.
- Event names say what happened: `HomeStarted`, `ExploreRequested`.
- A bloc used by one screen is provided by that screen (ARCHITECTURE §4.2). Only add an app-wide provider in `lib/app/app.dart` when several screens share the state.
- Widgets dispatch events or call cubit methods. They never call use cases or repositories directly.
- Keep long-running work in blocs or use cases, never in `build()`.

### Data safety (non-negotiable)
- **Never rename or remove a stored JSON field** (ARCHITECTURE §7.2) without a migration. Adding a field is fine if it is nullable or has a default, so data already on the device still parses.
- **Never change the comic key format** (ARCHITECTURE §8.1) or an extension's `id`. Keys are stored in the library, history, downloads, backups and sync files.
- **Backup format changes bump `BackupRepositoryImpl.formatVersion`** (ARCHITECTURE §7.4), and the PR says whether files of the previous version can still be restored. **Sync format changes** bump `SyncRepositoryImpl.formatVersion` (ARCHITECTURE §7.6) and must consider devices still on the old version.
- Library writes made by the user go through the repositories, so `LibraryJournal` records them for sync. Writes made by sync go through the data sources.
- Any change to storage, backup or sync needs a manual upgrade test: install the current release, add bookmarks, categories and history, install the new build over it with `adb install -r` (§2), and check that nothing was lost.

---

## 5. Testing

| Layer | How |
|---|---|
| Repositories (remote) | `FakeSourceRegistry` and `FakeSourceBackend` (`test/helpers/fake_source.dart`) return canned source results from `test/fixtures/api_fixtures.dart`; use `FakeNetworkInfo`. Assert the entity fields and the recorded `method(...args)` calls. |
| Repositories (local) | Real Hive in a temp directory via `setUpTempHive()` (`test/helpers/hive.dart`). |
| Use cases | Mock the repository interfaces with mocktail. |
| Blocs / cubits | `bloc_test`, with mocked use cases or real ones over temp Hive. |
| Sources | `test/core/source_test.dart`: `ComicKey`, filter groups, `ExtensionMeta` versions and languages, `Challenge`. |
| Storage / backup / sync | `test/features/library_test.dart`, `backup_test.dart`, `sync_test.dart` (merge rules) and `migrate_library_test.dart` (sample data in `test/fixtures/library_fixtures.dart`). |
| Manual | Every tab and screen on a recent Android before each release, plus the upgrade test above when storage changed. Check at least one Cloudflare-protected source and one download. |

Every bug fix gets a regression test where it can be tested without a device. The JS engine, WebViews and Cronet are not available in `flutter test`; test the Dart around them with fakes, and the scripts themselves in the extension repo.

### 5.1 Testing extensions locally

Extensions are written and checked in `bacakomik-ext-source` (`bun scripts/run.ts <id> smoke` runs one against its live site outside the app). To run unpublished extensions in the app:

1. In the extension repo, build: `bun scripts/build.ts` (same as `bun run build`). It validates `src/` and writes `dist/`.
2. Serve `dist/` on port 8787, from the extension repo:
   ```bash
   cd dist && bun -e "Bun.serve({port:8787, fetch(r){const p=new URL(r.url).pathname; return new Response(Bun.file('.'+(p==='/'?'/index.json':p)))}})"
   ```
3. Forward the port to the phone: `adb reverse tcp:8787 tcp:8787`.
4. In the app: More → Extensions → the repos button in the top bar, add `http://localhost:8787/index.json`. Install or update the extension from that repo.

Bump the extension's `version` for every change you want the app to pick up as an update. Remove the local repo when you are done; the app keeps it until removed. Script `log()` output appears in `flutter logs` / logcat as `[<sourceId>] …`.

---

## 6. Errors and logging

- The data layer throws `ServerException` or `CacheException`. Repositories turn every error into a `Failure` (ARCHITECTURE §9).
- Blocs show `NetworkFailure` as the offline placeholder and other failures through `SourceError`, which also handles Cloudflare challenges and a missing source.
- Log with `debugPrint`, never `print`. Never log full backup or sync contents.

---

## 7. Dependencies

- Versions live in `pubspec.yaml`. Before adding a package, check that it is maintained, works on Android 7.0+, and is really needed.
- `freezed`, the code generators (`injectable_generator`, `json_serializable`) and `hive_ce` are pinned for compatibility (ARCHITECTURE §10.1). Upgrade them in their own PR, then regenerate code and run all tests.
- `flutter_inappwebview` is on a 6.2 beta. Upgrades of it, `flutter_js`, `native_dio_adapter` or `cronet_http` need a device test against a Cloudflare-protected source.
- Upgrades of Flutter itself also go in their own PR, with a smoke test on a device.

---

## 8. Git workflow

- Branch from `main`: `feat/…`, `fix/…`, `refactor/…`, `docs/…`, `chore/…`.
- Use [Conventional Commits](https://www.conventionalcommits.org/): `feat(reader): remember scroll position`, `fix(backup): accept missing history`.
- Keep PRs small: one feature or fix per PR.

### PR checklist

The same list is in the PR template (`.github/pull_request_template.md`).
- [ ] `flutter analyze` and `flutter test` pass.
- [ ] Code regenerated with `build_runner` and committed, if annotations changed.
- [ ] New domain logic and repositories have tests.
- [ ] Data-safety rules (§4) respected; storage/backup/sync changes tested with an upgrade install.
- [ ] UI checked in light and dark theme, on a phone and on a wide screen if layout changed.
- [ ] Bundled extensions updated (§2) if the change needs newer extension versions.
- [ ] ARCHITECTURE.md updated if the design changed.

---

## 9. Scope guard

BacaKomik is a reader: **browse comics from installed sources, read chapters, keep a library on the device** (optionally synced through the user's own Google Drive). Support for a new site is an extension, not an app change. Proposals for BacaKomik accounts, a server-side library, or site-specific code in the app start as a discussion issue, not a PR. Anything that changes stored data, backup or sync files needs a migration plan first.
