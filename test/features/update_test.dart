import 'dart:async';

import 'package:yoru/core/error/failures.dart';
import 'package:yoru/core/usecase/usecase.dart';
import 'package:yoru/features/update/data/models/github_release_model.dart';
import 'package:yoru/features/update/domain/entities/app_release.dart';
import 'package:yoru/core/utils/version.dart';
import 'package:yoru/features/update/domain/entities/update_progress.dart';
import 'package:yoru/features/update/domain/repositories/update_repository.dart';
import 'package:yoru/features/update/domain/usecases/update_usecases.dart';
import 'package:yoru/features/update/presentation/bloc/update_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockUpdateRepository extends Mock implements UpdateRepository {}

class MockCheckForUpdate extends Mock implements CheckForUpdate {}

class MockInstallUpdate extends Mock implements InstallUpdate {}

ReleaseAsset apk(String suffix) => ReleaseAsset(
  name: 'Yoru-1.1.0-$suffix.apk',
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
          ReleaseAsset(name: 'Yoru-1.1.0-macos.zip', url: 'm'),
          ReleaseAsset(name: 'Yoru-1.1.0-windows-setup.exe', url: 'w'),
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
          'name': 'Yoru-1.1.0-universal.apk',
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
        name: 'Yoru-1.1.0-universal.apk',
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

  group('UpdateCubit installation', () {
    late MockCheckForUpdate check;
    late MockInstallUpdate install;
    late UpdateCubit cubit;

    setUp(() {
      check = MockCheckForUpdate();
      install = MockInstallUpdate();
      when(() => check(const NoParams()))
          .thenAnswer((_) async => right(release));
      cubit = UpdateCubit(check, install);
    });

    tearDown(() => cubit.close());

    test(
      'blocks duplicate installs and checks while awaiting approval',
      () async {
        final progress = StreamController<UpdateProgress>();
        when(() => install(release)).thenAnswer((_) => progress.stream);
        await cubit.check();
        cubit.install();
        final installing = cubit.stream.firstWhere(
          (state) => state is UpdateInstallingState,
        );
        progress.add(const UpdateInstalling());
        await installing;

        cubit.install();
        await cubit.check();
        expect(cubit.state, UpdateState.installing(release));
        verify(() => check(const NoParams())).called(1);
        verify(() => install(release)).called(1);

        final failure = cubit.stream.firstWhere(
          (state) => state is UpdateInstallFailedState,
        );
        progress.add(
          const UpdateInstallFailed('Administrator approval was cancelled'),
        );
        await failure;
        await progress.close();
        expect(cubit.state, UpdateState.installFailed(release));

        when(() => install(release))
            .thenAnswer((_) => Stream.value(const UpdateInstalling()));
        final retry = cubit.stream.firstWhere(
          (state) => state is UpdateAvailable,
        );
        cubit.install();
        await retry;
        verify(() => install(release)).called(1);
      },
    );

    test(
      'Android handoff restores the update button after its stream ends',
      () async {
        when(() => install(release))
            .thenAnswer((_) => Stream.value(const UpdateInstalling()));
        await cubit.check();
        final states = <UpdateState>[];
        final subscription = cubit.stream.listen(states.add);
        final available = cubit.stream.firstWhere(
          (state) => state is UpdateAvailable,
        );
        cubit.install();
        await available;
        expect(states, [
          UpdateState.downloading(release, 0),
          UpdateState.installing(release),
          UpdateState.available(release),
        ]);
        await subscription.cancel();
      },
    );
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
