# Contributing

How to set up, build, and work on BacaKomik. Read [ARCHITECTURE.md](ARCHITECTURE.md) before a non-trivial change.

---

## 1. Prerequisites

- **Flutter** (current stable) with **Dart 3.13+**. Check with `flutter --version`.
- **Android Studio** or the Android SDK command-line tools, with platform 37 and current build-tools. Run `flutter doctor` and fix what it reports.
- **JDK 17** for Gradle.
- A device or emulator on Android 7.0+ (API 24). Test on at least one recent Android (API 34+).

---

## 2. Build and run

```bash
flutter pub get
dart run build_runner build -d      # regenerate freezed / json / injectable / assets code
flutter run                         # debug build on the connected device
flutter analyze                     # must report "No issues found!"
flutter test                        # unit and bloc tests, no device needed
```

`build_runner` has to run after you change anything annotated with `@freezed`, `@JsonSerializable`, `@injectable`/`@LazySingleton`/`@module`, or the assets. Generated files are committed, so commit them with the change that caused them.

Use a different API server with:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

(`10.0.2.2` is the host machine as seen from the Android emulator.) Without it, the app uses `https://api-bacakomik.kurodev.org`.

### Release builds

`flutter build apk --release` builds a signed APK and `flutter build appbundle --release` builds an `.aab`. Signing comes from `android/key.properties` (git-ignored) with `storeFile`, `storePassword`, `keyAlias`, `keyPassword`. Back up the keystore and its password: without them no update can be published for the same app id.

Before a release, bump `version:` in `pubspec.yaml`. The build number after `+` must increase.

### Publishing a release

Releases are built by `.github/workflows/release.yml` when a `v*` tag is pushed:

1. Bump `version:` in `pubspec.yaml` (for example `1.1.0+2`).
2. Write the notes in `.github/release-notes/v1.1.0.md` (optional; without it GitHub generates notes from the commits).
3. Commit, then `git tag v1.1.0 && git push origin v1.1.0`.

The workflow checks that the tag matches the pubspec version, runs analyze and tests, builds signed `arm64-v8a`, `armeabi-v7a`, `x86_64` and universal APKs, and publishes them as `BacaKomik-<version>-<abi>.apk` with an "Which APK?" table appended to the notes. Installed apps find the release through the GitHub API (ARCHITECTURE §1), so do not rename the assets or that heading.

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
- `lib/core/`: DI, errors, network, Hive storage, shared entities/DTOs/widgets, constants.
- `lib/features/<name>/{domain,data,presentation}`: one folder per feature.
- `test/`: mirrors `lib/`. Shared fakes are in `test/helpers/` and sample data in `test/fixtures/`.
- `docs/`: this guide and ARCHITECTURE.md.

### Reading order for newcomers

1. Run the app and click through every tab (what it does).
2. ARCHITECTURE.md §3–§4.
3. `features/home/` end to end: entity → repository → use case → `HomeBloc` → `HomeScreen`. Every remote feature follows this pattern.
4. `core/presentation/bloc/comic_list_state.dart` and one of the paginated features (`latest`).
5. `features/bookmark/` and `core/storage/` for local data, then ARCHITECTURE §7.

---

## 4. Code conventions

### General
- Follow `flutter_lints` (`analysis_options.yaml`). `flutter analyze` must be clean.
- Run `dart format` on new files. In existing files, format only what you change, so diffs stay readable (see ARCHITECTURE §12).
- Use full `package:bacakomik_app/...` imports, not relative ones.
- Comment *why*, not *what*. Use `///` docs on public types and on anything non-obvious (formats, ordering, compatibility).
- Don't use `!` on values that can really be null, and don't swallow errors with an empty `catch`. Return a `Failure` or log with `debugPrint` (§6).
- UI text goes in `AppText`, colours in `AppColors`. No inline strings or colour literals in widgets.

### Layers
- Domain code is plain Dart: no Flutter, Dio, Hive, `dart:io` or file_picker. Run the grep in ARCHITECTURE §3.
- Repositories return `Either<Failure, T>`. Use `runRemote` for API calls and `runLocal` for storage.
- New API endpoints go in `SeriesRemoteDataSource` with a DTO that has `toEntity()`. Widgets never see DTOs.
- Register new classes with injectable annotations instead of building them by hand. The only exceptions are tests and `lib/app/`.

### Bloc patterns
- States are freezed sealed unions. Remote screens use `initial / loading / loaded / error / noInternet`.
- Event names say what happened: `HomeStarted`, `SearchNextPageRequested`.
- A bloc used by one screen is provided by that screen (ARCHITECTURE §4.2). Only add an app-wide provider in `lib/app/app.dart` when several screens share the state.
- Widgets dispatch events or call cubit methods. They never call use cases or repositories directly.
- Keep long-running work in blocs or use cases, never in `build()`.

### Data safety (non-negotiable)
- **Never rename or remove a stored JSON field** (ARCHITECTURE §7.2) without a migration. Adding a field is fine if it is nullable or has a default, so data already on the device still parses.
- **Backup format changes bump `BackupRepositoryImpl.formatVersion`** (ARCHITECTURE §7.4), and the PR says whether files of the previous version can still be restored.
- Any change to storage or backup needs a manual upgrade test: install the current release, add bookmarks and history, install the new build over it, and check that nothing was lost.

---

## 5. Testing

| Layer | How |
|---|---|
| Repositories (remote) | Mock `ApiClient` with mocktail, use `FakeNetworkInfo`, feed JSON from `test/fixtures/api_fixtures.dart`. Assert the entity fields and the query sent. |
| Repositories (local) | Real Hive in a temp directory via `setUpTempHive()` (`test/helpers/hive.dart`). |
| Use cases | Mock the repository interfaces. |
| Blocs / cubits | `bloc_test`, with mocked use cases or real ones over temp Hive. |
| Storage / backup | History storage and the backup format are covered in `test/features/library_test.dart` and `test/features/backup_test.dart` (sample data in `test/fixtures/library_fixtures.dart`). |
| Manual | Every tab and screen on a recent Android before each release, plus the upgrade test above when storage changed. |

Every bug fix gets a regression test where it can be tested without a device.

---

## 6. Errors and logging

- The data layer throws `ServerException` or `CacheException`. Repositories turn every error into a `Failure` (ARCHITECTURE §9).
- Blocs show `NetworkFailure` as the no-internet placeholder and other failures as their message.
- Log with `debugPrint`, never `print`. Never log full backup contents.

---

## 7. Dependencies

- Versions live in `pubspec.yaml`. Before adding a package, check that it is maintained, works on Android 7.0+, and is really needed.
- `freezed`, the code generators (`injectable_generator`, `json_serializable`) and `hive_ce` are pinned for compatibility (ARCHITECTURE §10.1). Upgrade them in their own PR, then regenerate code and run all tests.
- Upgrades of Flutter itself also go in their own PR, with a smoke test on a device.

---

## 8. Git workflow

- Branch from `main`: `feat/…`, `fix/…`, `refactor/…`, `docs/…`, `chore/…`.
- Use [Conventional Commits](https://www.conventionalcommits.org/): `feat(reader): remember scroll position`, `fix(backup): accept missing history`.
- Keep PRs small: one feature or fix per PR.

### PR checklist
- [ ] `flutter analyze` and `flutter test` pass.
- [ ] Code regenerated with `build_runner` and committed, if annotations changed.
- [ ] New domain logic and repositories have tests.
- [ ] Data-safety rules (§4) respected; storage/backup changes tested with an upgrade install.
- [ ] UI checked in light and dark theme, on a phone and on a wide screen if layout changed.
- [ ] ARCHITECTURE.md updated if the design changed.

---

## 9. Scope guard

BacaKomik is a reader: **browse comics, read chapters, keep a local library.** Proposals for accounts, cloud sync or offline downloads start as a discussion issue, not a PR. Anything that changes stored data or backup files needs a migration plan first.
