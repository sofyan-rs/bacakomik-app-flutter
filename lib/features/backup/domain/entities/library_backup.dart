import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/category/domain/entities/category.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'library_backup.freezed.dart';

/// Contents of a backup file.
@freezed
abstract class LibraryBackup with _$LibraryBackup {
  const LibraryBackup._();

  const factory LibraryBackup({
    @Default([]) List<Bookmark> bookmarks,
    @Default([]) List<ReadHistory> history,
    @Default([]) List<LibraryCategory> categories,
    @Default([]) List<ComicCategories> comicCategories,
  }) = _LibraryBackup;

  bool get isEmpty => bookmarks.isEmpty && history.isEmpty;
}

enum BackupResult { saved, cancelled, nothingToSave }

enum RestoreResult { restored, cancelled }
