import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';

abstract interface class MigrationFileDataSource {
  /// Bytes of a file the user picks, or null when they cancel. Android does
  /// not know types like `.tachibk`, so any file can be picked; [extensions]
  /// (without dots) are checked after, throwing [FormatException].
  Future<List<int>?> pickFile(List<String> extensions);
}

@LazySingleton(as: MigrationFileDataSource)
class MigrationFileDataSourceImpl implements MigrationFileDataSource {
  @override
  Future<List<int>?> pickFile(List<String> extensions) async {
    final files = await FilePicker.pickFiles(type: FileType.any);
    if (files.isEmpty) return null;
    final file = files.single;
    final name = file.name.toLowerCase();
    if (!extensions.any((e) => name.endsWith('.$e'))) {
      throw FormatException(
        'Pick a ${extensions.map((e) => '.$e').join(' or ')} file',
      );
    }
    return File(file.path!).readAsBytes();
  }
}
