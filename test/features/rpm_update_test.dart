import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoru/features/update/data/datasources/app_installer.dart';
import 'package:yoru/features/update/data/datasources/linux_rpm_updater.dart';
import 'package:yoru/features/update/domain/entities/app_release.dart';
import 'package:yoru/features/update/domain/entities/update_progress.dart';

void main() {
  group('RPM installation detection', () {
    test('recognizes Yoru RPM ownership and caches the query', () async {
      final queries = <List<String>>[];
      final rpm = LinuxRpmUpdater(
        isLinux: true,
        environment: {},
        executable: '/opt/yoru/yoru',
        run: (command, args) async {
          expect(command, '/usr/bin/rpm');
          queries.add(args);
          return ProcessResult(1, 0, 'yoru', '');
        },
      );
      expect(await rpm.isInstalled(), isTrue);
      expect(await rpm.isInstalled(), isTrue);
      expect(queries, [
        ['--query', '--file', '/opt/yoru/yoru', '--queryformat', '%{NAME}'],
      ]);
    });

    test('AppImage and other platforms never probe or select an RPM', () async {
      for (final config in [
        (true, {'APPIMAGE': '/home/user/Yoru.AppImage'}),
        (false, <String, String>{}),
      ]) {
        final rpm = LinuxRpmUpdater(
          isLinux: config.$1,
          environment: config.$2,
          run: (_, _) async => fail('RPM must not be queried'),
        );
        expect(await rpm.isInstalled(), isFalse);
        if (Platform.isLinux) {
          final dio = Dio();
          expect(await DesktopAppInstaller(dio, rpm: rpm).assetSuffixes(), [
            'linux-x86_64.AppImage',
          ]);
          dio.close();
        }
      }
    });

    test(
      'does not mistake unpackaged or unrelated programs for RPM installs',
      () async {
        for (final result in [
          ProcessResult(1, 1, '', 'file is not owned by any package'),
          ProcessResult(1, 0, 'another-package', ''),
        ]) {
          final rpm = LinuxRpmUpdater(
            isLinux: true,
            environment: {},
            run: (_, _) async => result,
          );
          expect(await rpm.isInstalled(), isFalse);
        }
      },
    );

    test(
      'missing RPM executable is treated as an unpackaged install',
      () async {
        final rpm = LinuxRpmUpdater(
          isLinux: true,
          environment: {},
          run: (command, args) async => throw ProcessException(command, args),
        );
        expect(await rpm.isInstalled(), isFalse);
      },
    );
  });

  group('RPM update', () {
    late Directory temp;
    late HttpServer server;
    late Dio dio;
    late LinuxRpmUpdater rpm;
    late DesktopAppInstaller installer;
    late List<(String, List<String>)> commands;
    late int installExitCode;
    late int responseCode;
    late int requests;
    late bool restarted;
    late bool missingPkexec;
    final bytes = utf8.encode('test release package');

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('yoru rpm test;');
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      responseCode = HttpStatus.ok;
      requests = 0;
      server.listen((request) async {
        requests++;
        request.response.statusCode = responseCode;
        request.response.contentLength = bytes.length;
        request.response.add(bytes);
        await request.response.close();
      });
      dio = Dio();
      commands = [];
      installExitCode = 0;
      restarted = false;
      missingPkexec = false;
      rpm = LinuxRpmUpdater(
        isLinux: true,
        environment: {},
        executable: '/opt/yoru/yoru',
        run: (command, args) async {
          commands.add((command, args));
          if (command == '/usr/bin/rpm') {
            return ProcessResult(1, 0, 'yoru', '');
          }
          if (missingPkexec) throw ProcessException(command, args);
          expect(await File(args.last).readAsBytes(), bytes);
          return ProcessResult(
            2,
            installExitCode,
            '',
            'test installer failure',
          );
        },
        restart: () async {
          expect(await temp.list().toList(), isEmpty);
          restarted = true;
        },
      );
      installer = DesktopAppInstaller(
        dio,
        rpm: rpm,
        temporaryDirectory: () async => temp,
      );
    });

    tearDown(() async {
      dio.close(force: true);
      await server.close(force: true);
      await temp.delete(recursive: true);
    });

    ReleaseAsset asset({String? checksum}) => ReleaseAsset(
      name: 'Yoru-2.19.0-linux-x86_64.rpm',
      url: 'http://127.0.0.1:${server.port}/release.rpm',
      sha256: checksum ?? sha256.convert(bytes).toString(),
    );

    test('selects only RPM and never substitutes the AppImage', () async {
      final suffixes = await installer.assetSuffixes();
      expect(suffixes, ['linux-x86_64.rpm']);
      final release = AppRelease(
        version: '2.19.0',
        pageUrl: '',
        assets: [
          const ReleaseAsset(
            name: 'Yoru-2.19.0-linux-x86_64.AppImage',
            url: 'a',
          ),
          asset(),
        ],
      );
      expect(release.assetFor(suffixes), asset());
      expect(
        release.copyWith(assets: [release.assets.first]).assetFor(suffixes),
        isNull,
      );
    });

    test(
      'verifies the download and prompts for DNF before restarting',
      () async {
        final progress = await installer.install(asset()).toList();
        expect(progress.first, isA<UpdateDownloading>());
        expect(progress.last, isA<UpdateInstalling>());
        expect(progress.whereType<UpdateInstallFailed>(), isEmpty);
        expect(restarted, isTrue);
        final (command, args) = commands.last;
        expect(command, '/usr/bin/pkexec');
        expect(args.take(4), [
          '--disable-internal-agent',
          '/usr/bin/dnf',
          '--assumeyes',
          'install',
        ]);
        // Paths containing spaces and shell metacharacters remain one argument.
        expect(args, hasLength(5));
        expect(args.last, startsWith(temp.path));
        expect(args.last, endsWith('/update.rpm'));
      },
    );

    test(
      'cancelled approval and failed DNF leave the app open and retryable',
      () async {
        for (final code in [126, 127, 1]) {
          installExitCode = code;
          final progress = await installer.install(asset()).toList();
          expect(progress.last, isA<UpdateInstallFailed>());
          expect(restarted, isFalse);
          expect(await temp.list().toList(), isEmpty);
        }
        installExitCode = 0;
        await installer.install(asset()).drain<void>();
        expect(restarted, isTrue);
      },
    );

    test('missing digest refuses the RPM before download or administrator approval', () async {
      final progress = await installer
          .install(asset().copyWith(sha256: null))
          .toList();
      expect(
        (progress.single as UpdateInstallFailed).message,
        'CHECKSUM_MISSING',
      );
      expect(requests, 0);
      expect(commands.map((entry) => entry.$1), ['/usr/bin/rpm']);
      expect(restarted, isFalse);
      expect(await temp.list().toList(), isEmpty);
    });

    test('checksum mismatch never invokes the privileged installer', () async {
      final progress = await installer.install(asset(checksum: 'bad')).toList();
      expect((progress.last as UpdateInstallFailed).message, 'CHECKSUM_ERROR');
      expect(commands.map((entry) => entry.$1), ['/usr/bin/rpm']);
      expect(restarted, isFalse);
      expect(await temp.list().toList(), isEmpty);
    });

    test(
      'download failure is reported without an unhandled asynchronous error',
      () async {
        responseCode = HttpStatus.notFound;
        final progress = await installer.install(asset()).toList();
        expect(
          (progress.last as UpdateInstallFailed).message,
          startsWith('DOWNLOAD_ERROR:'),
        );
        expect(commands.map((entry) => entry.$1), ['/usr/bin/rpm']);
        expect(restarted, isFalse);
        expect(await temp.list().toList(), isEmpty);
      },
    );

    test(
      'missing pkexec leaves the app open and cleans up the package',
      () async {
        missingPkexec = true;
        final progress = await installer.install(asset()).toList();
        expect(progress.last, isA<UpdateInstallFailed>());
        expect(restarted, isFalse);
        expect(await temp.list().toList(), isEmpty);
      },
    );
    test('temporary storage failure is reported before installation', () async {
      final noStorage = DesktopAppInstaller(
        dio,
        rpm: rpm,
        temporaryDirectory: () async =>
            throw const FileSystemException('No space'),
      );
      final progress = await noStorage.install(asset()).toList();
      expect(
        (progress.single as UpdateInstallFailed).message,
        'FILE_ERROR: No space',
      );
      expect(commands.map((entry) => entry.$1), ['/usr/bin/rpm']);
      expect(restarted, isFalse);
    });
  }, skip: !Platform.isLinux);
}
