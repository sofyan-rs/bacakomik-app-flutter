import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';

abstract interface class BackupFileDataSource {
  /// Null when the user cancels.
  Future<String?> pickDirectory();

  Future<void> writeFile(String path, String content);

  /// Content of the chosen `.json` file, or null when the user cancels.
  Future<String?> pickAndReadJsonFile();
}

@LazySingleton(as: BackupFileDataSource)
class BackupFileDataSourceImpl implements BackupFileDataSource {
  @override
  Future<String?> pickDirectory() => FilePicker.getDirectoryPath();

  @override
  Future<void> writeFile(String path, String content) =>
      File(path).writeAsString(content);

  @override
  Future<String?> pickAndReadJsonFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (files.isEmpty) return null;
    return File(files.single.path!).readAsString();
  }
}
