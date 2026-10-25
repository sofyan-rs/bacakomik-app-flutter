import 'dart:convert';

import 'package:bacakomik_app/core/data/models/comic_details_model.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/backup/data/datasources/backup_file_data_source.dart';
import 'package:bacakomik_app/features/backup/domain/entities/library_backup.dart';
import 'package:bacakomik_app/features/backup/domain/repositories/backup_repository.dart';
import 'package:bacakomik_app/features/bookmark/data/models/bookmark_model.dart';
import 'package:bacakomik_app/features/category/data/models/category_model.dart';
import 'package:bacakomik_app/features/history/data/models/read_history_model.dart';
import 'package:flutter/foundation.dart';
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

      await _files.writeFile(
        '$directory/${fileName(_clock.now())}',
        encode(backup),
      );
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

  /// Current backup file format. Files with another version are rejected.
  static const formatVersion = 2;

  /// `{version, bookmarks, history, historyComics, categories,
  /// comicCategories}` as plain JSON objects. Versions before categories
  /// ignore the last two, so they stay readable by older app versions.
  static String encode(LibraryBackup backup) =>
      jsonEncode({'version': formatVersion, ...libraryToJson(backup)});

  /// `{bookmarks, history, historyComics, categories, comicCategories}`.
  /// History entries refer to their comic by slug; each comic's details
  /// are written once in `historyComics`. Also used by sync.
  static Map<String, dynamic> libraryToJson(LibraryBackup backup) => {
    'bookmarks': [
      for (final b in backup.bookmarks) BookmarkModel.fromEntity(b).toJson(),
    ],
    'history': [
      for (final h in backup.history) ReadHistoryModel.fromEntity(h).toJson(),
    ],
    'historyComics': [
      for (final h in {for (final h in backup.history) h.comicSlug: h}.values)
        HistoryComicModel(
          slug: h.comicSlug,
          comicDetails: ComicDetailsModel.fromEntity(h.comicDetails),
        ).toJson(),
    ],
    'categories': [
      for (final c in backup.categories) CategoryModel.fromEntity(c).toJson(),
    ],
    'comicCategories': [
      for (final c in backup.comicCategories)
        ComicCategoriesModel.fromEntity(c).toJson(),
    ],
  };

  static LibraryBackup decode(String content) {
    final json = jsonDecode(content) as Map<String, dynamic>;
    if (json['version'] != formatVersion) {
      throw FormatException('Unsupported backup version: ${json['version']}');
    }
    return libraryFromJson(json);
  }

  /// Reads [libraryToJson] output. History entries whose comic is missing
  /// are skipped, and so is an entry that does not parse, so one bad record
  /// cannot hide the rest.
  static LibraryBackup libraryFromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) read) {
      final items = json[key];
      if (items is! List) return [];
      final result = <T>[];
      for (final item in items) {
        try {
          result.add(read(item as Map<String, dynamic>));
        } catch (e) {
          debugPrint('Skipping unreadable $key entry: $e');
        }
      }
      return result;
    }

    final comics = {
      for (final c in list(
        'historyComics',
        (j) => HistoryComicModel.fromJson(j),
      ))
        c.slug: c.comicDetails.toEntity(),
    };
    return LibraryBackup(
      bookmarks: list('bookmarks', (j) => BookmarkModel.fromJson(j).toEntity()),
      history: [
        for (final entry in list('history', ReadHistoryModel.fromJson))
          if (comics[entry.comicSlug] case final details?)
            entry.toEntity(details),
      ],
      categories: list(
        'categories',
        (j) => CategoryModel.fromJson(j).toEntity(),
      ),
      comicCategories: list(
        'comicCategories',
        (j) => ComicCategoriesModel.fromJson(j).toEntity(),
      ),
    );
  }
}
