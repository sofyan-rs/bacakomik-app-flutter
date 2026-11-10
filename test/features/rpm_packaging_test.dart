import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../linux/packaging/check_bundle.dart' as packaging;

void main() {
  late Directory libraries;

  setUp(() async {
    libraries = await Directory.systemTemp.createTemp('yoru-private-libs-');
  });

  tearDown(() => libraries.delete(recursive: true));

  test(
    'excludes bundled Flutter plugins but preserves system dependencies',
    () async {
      final names = [
        'libapp.so',
        'libflutter_linux_gtk.so',
        'libaudioplayers_linux_plugin.so',
        'libflutter_inappwebview_linux_plugin.so',
        'libflutter_js_plugin.so',
        'liburl_launcher_linux_plugin.so',
        'libquickjs_c_bridge_plugin.so',
        'libdartjni.so',
        'libversioned.so.1',
      ];
      for (final name in names) {
        await File('${libraries.path}/$name').writeAsString('ELF fixture name');
      }
      final filter = RegExp(packaging.privateLibraryRequires(libraries));
      for (final name in names) {
        expect(filter.hasMatch('$name()(64bit)'), isTrue, reason: name);
        expect(
          filter.hasMatch('$name(VERSION_1)(64bit)'),
          isTrue,
          reason: name,
        );
      }
      for (final dependency in [
        'libc.so.6(GLIBC_2.34)(64bit)',
        'libgtk-3.so.0()(64bit)',
        'libjvm.so()(64bit)',
        'libgstreamer-1.0.so.0()(64bit)',
        'libnot_bundled_plugin.so()(64bit)',
        'libversioned.so.10()(64bit)',
      ]) {
        expect(filter.hasMatch(dependency), isFalse, reason: dependency);
      }
    },
  );

  test('escapes names and ignores non-library files', () async {
    await File('${libraries.path}/liba+b.so').writeAsString('');
    await File('${libraries.path}/README.md').writeAsString('');
    final filter = RegExp(packaging.privateLibraryRequires(libraries));
    expect(filter.hasMatch('liba+b.so()(64bit)'), isTrue);
    expect(filter.hasMatch('libab.so()(64bit)'), isFalse);
    expect(filter.hasMatch('README.md'), isFalse);
  });

  test('an empty bundle excludes no dependency', () {
    final filter = RegExp(packaging.privateLibraryRequires(libraries));
    expect(filter.hasMatch('libc.so.6()(64bit)'), isFalse);
  });
}
