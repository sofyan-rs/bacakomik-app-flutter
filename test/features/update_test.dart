import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/update/data/models/github_release_model.dart';
import 'package:bacakomik_app/features/update/domain/entities/app_release.dart';
import 'package:bacakomik_app/core/utils/version.dart';
import 'package:bacakomik_app/features/update/domain/entities/update_progress.dart';
import 'package:bacakomik_app/features/update/domain/repositories/update_repository.dart';
import 'package:bacakomik_app/features/update/domain/usecases/update_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockUpdateRepository extends Mock implements UpdateRepository {}

ReleaseAsset apk(String suffix) => ReleaseAsset(
  name: 'BacaKomik-1.1.0-$suffix.apk',
  url: 'https://example.com/$suffix.apk',
);

final release = AppRelease(
  version: '1.1.0',
  notes:
      '## Changes\n\n- New reader.\n\n${AppRelease.apkTableHeading}\n\n| File |',
  pageUrl: 'https://github.com/x/y/releases/tag/v1.1.0',
  assets: [apk('arm64-v8a'), apk('armeabi-v7a'), apk('universal')],
);

void main() {
  group('isNewerVersion', () {
    test('compares major, minor and patch as numbers', () {
      expect(isNewerVersion('1.0.1', '1.0.0'), isTrue);
      expect(isNewerVersion('1.10.0', '1.9.9'), isTrue);
      expect(isNewerVersion('2.0.0', '1.99.99'), isTrue);
      expect(isNewerVersion('1.0.0', '1.0.0'), isFalse);
      expect(isNewerVersion('1.0.0', '1.0.1'), isFalse);
    });

    test('ignores a leading v, suffixes and missing parts', () {
      expect(isNewerVersion('v1.2.0', '1.1.9'), isTrue);
      expect(isNewerVersion('1.2', '1.2.0'), isFalse);
      expect(isNewerVersion('1.2.0+7', '1.2.0'), isFalse);
      expect(isNewerVersion('1.2.1-beta', '1.2.0'), isTrue);
    });
  });

  group('AppRelease', () {
    test('picks the APK for the device ABI', () {
      expect(
        release.assetFor(['armeabi-v7a.apk', 'universal.apk'])?.name,
        endsWith('armeabi-v7a.apk'),
      );
    });

    test('falls back to the universal APK', () {
      expect(
        release.assetFor(['x86.apk', 'universal.apk'])?.name,
        endsWith('universal.apk'),
      );
      expect(
        release.assetFor(['universal.apk'])?.name,
        endsWith('universal.apk'),
      );
      expect(
        const AppRelease(version: '1', pageUrl: '').assetFor(['universal.apk']),
        isNull,
      );
    });

    test('picks the desktop asset by its ending', () {
      final desktop = AppRelease(
        version: '1.1.0',
        pageUrl: '',
        assets: [
          ReleaseAsset(name: 'BacaKomik-1.1.0-macos.zip', url: 'm'),
          ReleaseAsset(name: 'BacaKomik-1.1.0-windows-setup.exe', url: 'w'),
        ],
      );
      expect(desktop.assetFor(['windows-setup.exe'])?.url, 'w');
      expect(desktop.assetFor(['linux-x86_64.AppImage']), isNull);
    });

    test('changes drop the APK table', () {
      expect(release.changes, '## Changes\n\n- New reader.');
    });
  });

  test('GitHubReleaseModel keeps the assets and their SHA-256', () {
    final model = GitHubReleaseModel.fromJson({
      'tag_name': 'v1.1.0',
      'body': 'Notes',
      'html_url': 'https://github.com/x/y/releases/tag/v1.1.0',
      'assets': [
        {
          'name': 'BacaKomik-1.1.0-universal.apk',
          'browser_download_url': 'https://example.com/u.apk',
          'digest': 'sha256:abc123',
        },
        {
          'name': 'SHA256SUMS.txt',
          'browser_download_url': 'https://example.com/sums',
        },
      ],
    }).toEntity();

    expect(model.version, '1.1.0');
    expect(model.assets, [
      const ReleaseAsset(
        name: 'BacaKomik-1.1.0-universal.apk',
        url: 'https://example.com/u.apk',
        sha256: 'abc123',
      ),
      const ReleaseAsset(
        name: 'SHA256SUMS.txt',
        url: 'https://example.com/sums',
      ),
    ]);
  });

  group('CheckForUpdate', () {
    late MockUpdateRepository repository;
    late CheckForUpdate check;

    setUp(() {
      repository = MockUpdateRepository();
      check = CheckForUpdate(repository);
      when(() => repository.latestRelease())
          .thenAnswer((_) async => right(release));
    });

    test('returns a newer release', () async {
      when(() => repository.installedVersion())
          .thenAnswer((_) async => '1.0.0');
      expect(
        await check(const NoParams()),
        right<Failure, AppRelease?>(release),
      );
    });

    test('returns null when the app is up to date', () async {
      when(() => repository.installedVersion())
          .thenAnswer((_) async => '1.1.0');
      expect(await check(const NoParams()), right<Failure, AppRelease?>(null));
    });
  });

  test('InstallUpdate fails when no asset fits the device', () async {
    final repository = MockUpdateRepository();
    when(() => repository.assetSuffixes())
        .thenAnswer((_) async => ['x86.apk', 'universal.apk']);
    final progress = await InstallUpdate(repository)(
      const AppRelease(version: '1.1.0', pageUrl: ''),
    ).toList();
    expect(progress.single, isA<UpdateInstallFailed>());
  });
}
