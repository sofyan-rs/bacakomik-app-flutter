import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:bacakomik_app/core/source/extension_bridge.dart';
import 'package:bacakomik_app/core/source/extension_manager.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/core/source/extension_runtime.dart';
import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import '../helpers/hive.dart';

class FakeEngine implements LoadedSource {
  FakeEngine(this.meta);

  @override
  final ExtensionMeta meta;

  var disposed = false;

  @override
  void dispose() => disposed = true;

  @override
  Future<Object?> call(String method, List<Object?> args) async => null;

  @override
  Future<SourceFeatures> features() => throw UnimplementedError();
}

/// Loads [FakeEngine]s, each finishing when the test completes [pending].
class SlowLoader {
  final loads = <FakeEngine>[];
  final pending = <Completer<void>>[];
  Object? failWith;

  Future<LoadedSource> call(ExtensionMeta meta) async {
    final done = Completer<void>();
    pending.add(done);
    await done.future;
    if (failWith case final error?) {
      failWith = null;
      throw error;
    }
    final engine = FakeEngine(meta);
    loads.add(engine);
    return engine;
  }

  void finishAll() {
    for (final c in pending) {
      if (!c.isCompleted) c.complete();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Future<void> Function() tearDownHive;
  late Directory support;
  late SlowLoader loader;
  late ExtensionManager manager;

  setUp(() async {
    tearDownHive = await setUpTempHive();
    support = await Directory.systemTemp.createTemp('bacakomik_support_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => support.path,
        );
    final installed = await Hive.openBox<String>(HiveBoxes.extensions);
    await installed.put(
      'demo',
      jsonEncode({
        'id': 'demo',
        'name': 'Demo',
        'lang': 'en',
        'version': '1.0.0',
        'file': 'demo.js',
        'sha256': '',
      }),
    );
    loader = SlowLoader();
    manager = ExtensionManager(
      installed,
      await Hive.openBox<String>(HiveBoxes.sourceSettings),
      Dio(),
      ExtensionBridge(await Hive.openBox<String>(HiveBoxes.extensionStorage)),
      loader: loader.call,
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await tearDownHive();
    await support.delete(recursive: true);
  });

  test('callers asking at the same time share one engine', () async {
    final first = manager.backend('demo');
    final second = manager.backend('demo');
    await pumpEventQueue();
    expect(loader.pending, hasLength(1));

    loader.finishAll();
    final engines = await Future.wait([first, second]);

    expect(loader.loads, hasLength(1));
    expect(identical(engines[0], engines[1]), isTrue);
    expect(identical(await manager.backend('demo'), engines[0]), isTrue);
    expect(loader.pending, hasLength(1));
  });

  test('a failed load is not kept', () async {
    loader.failWith = const ServerException('boom');
    final failing = manager.backend('demo');
    final alsoFailing = manager.backend('demo');
    loader.finishAll();
    await expectLater(failing, throwsA(isA<ServerException>()));
    await expectLater(alsoFailing, throwsA(isA<ServerException>()));

    final retry = manager.backend('demo');
    await pumpEventQueue();
    loader.finishAll();
    expect(await retry, same(loader.loads.single));
    expect(loader.pending, hasLength(2));
  });

  test('an engine still loading when its extension is removed is '
      'dropped', () async {
    final loading = manager.backend('demo');
    await pumpEventQueue();

    await manager.uninstall('demo');
    loader.finishAll();

    await expectLater(loading, throwsA(isA<ServerException>()));
    expect(loader.loads.single.disposed, isTrue);
  });

  test('uninstall disposes a loaded engine', () async {
    final loading = manager.backend('demo');
    await pumpEventQueue();
    loader.finishAll();
    final engine = await loading as FakeEngine;

    await manager.uninstall('demo');

    expect(engine.disposed, isTrue);
  });
}
