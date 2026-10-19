import 'dart:convert';

import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/backup/data/datasources/backup_file_data_source.dart';
import 'package:bacakomik_app/features/backup/domain/entities/library_backup.dart';
import 'package:bacakomik_app/features/backup/domain/repositories/backup_repository.dart';
import 'package:bacakomik_app/features/bookmark/data/models/bookmark_model.dart';
import 'package:bacakomik_app/features/history/data/models/read_history_model.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: BackupRepository)
class BackupRepositoryImpl implements BackupRepository {
  const BackupRepositoryImpl(this._files, this._clock);

  final BackupFileDataSource _files;
  final Clock _clock;

  @override
  Future<Either<Failure, bool>> exportBackup(LibraryBackup backup) async {
    try {
      final directory = await _files.pickDirectory();
      if (directory == null) return right(false);

      await _files.writeFile('$directory/${fileName(_clock.now())}', encode(backup));
      return right(true);
    } catch (e) {
      return left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LibraryBackup?>> importBackup() async {
    try {
      final content = await _files.pickAndReadJsonFile();
      if (content == null) return right(null);
      return right(decode(content));
    } catch (e) {
      return left(FileFailure(e.toString()));
    }
  }

  static String fileName(DateTime now) =>
      'bacakomik-backup-${now.year}-${now.month}-${now.day}-'
      '${now.hour}${now.minute}${now.second}.json';

  /// Backup file format shared with earlier app versions: every entry is an
  /// encoded JSON string, so older builds can still restore new backups.
  static String encode(LibraryBackup backup) => jsonEncode({
        'bookmarks': [
          for (final b in backup.bookmarks)
            jsonEncode(BookmarkModel.fromEntity(b).toJson()),
        ],
        'history': [
          for (final h in backup.history)
            jsonEncode(ReadHistoryModel.fromEntity(h).toJson()),
        ],
      });

  /// Accepts entries as encoded strings or plain objects, and the
  /// `favorites` key used by older backups.
  static LibraryBackup decode(String content) {
    final json = jsonDecode(content) as Map<String, dynamic>;
    final bookmarks = (json['bookmarks'] ?? json['favorites']) as List? ?? [];
    final history = json['history'] as List? ?? [];
    return LibraryBackup(
      bookmarks: [
        for (final e in bookmarks) BookmarkModel.fromJson(_entry(e)).toEntity(),
      ],
      history: [
        for (final e in history) ReadHistoryModel.fromJson(_entry(e)).toEntity(),
      ],
    );
  }

  static Map<String, dynamic> _entry(Object? e) =>
      (e is String ? jsonDecode(e) : e) as Map<String, dynamic>;
}
