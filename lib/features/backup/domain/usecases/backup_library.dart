import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/backup/domain/entities/library_backup.dart';
import 'package:bacakomik_app/features/backup/domain/repositories/backup_repository.dart';
import 'package:bacakomik_app/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:bacakomik_app/features/category/domain/repositories/category_repository.dart';
import 'package:bacakomik_app/features/history/domain/repositories/history_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Writes all bookmarks, history and categories to a backup file.
@injectable
class BackupLibrary implements UseCase<BackupResult, NoParams> {
  const BackupLibrary(
    this._backup,
    this._bookmarks,
    this._history,
    this._categories,
  );

  final BackupRepository _backup;
  final BookmarkRepository _bookmarks;
  final HistoryRepository _history;
  final CategoryRepository _categories;

  @override
  Future<Either<Failure, BackupResult>> call(NoParams params) async {
    final bookmarks = await _bookmarks.getBookmarks();
    final history = await _history.getHistory();
    final categories = await _categories.getCategories();
    final comicCategories = await _categories.getComicCategories();

    return bookmarks
        .flatMap((b) => history.map((h) => (b, h)))
        .flatMap((d) => categories.map((c) => (d.$1, d.$2, c)))
        .flatMap((d) => comicCategories.map((cc) => (d.$1, d.$2, d.$3, cc)))
        .fold((failure) async => left(failure), (data) async {
          final backup = LibraryBackup(
            bookmarks: data.$1,
            history: data.$2,
            categories: data.$3,
            comicCategories: data.$4.values.toList(),
          );
          if (backup.isEmpty) return right(BackupResult.nothingToSave);

          final saved = await _backup.exportBackup(backup);
          return saved.map(
            (ok) => ok ? BackupResult.saved : BackupResult.cancelled,
          );
        });
  }
}

/// Merges a backup file into the library. Entries with the same slug (or
/// category id) are replaced by the backup's version.
@injectable
class RestoreLibrary implements UseCase<RestoreResult, NoParams> {
  const RestoreLibrary(
    this._backup,
    this._bookmarks,
    this._history,
    this._categories,
  );

  final BackupRepository _backup;
  final BookmarkRepository _bookmarks;
  final HistoryRepository _history;
  final CategoryRepository _categories;

  @override
  Future<Either<Failure, RestoreResult>> call(NoParams params) async {
    final imported = await _backup.importBackup();
    return imported.fold((failure) async => left(failure), (backup) async {
      if (backup == null) return right(RestoreResult.cancelled);

      if (backup.bookmarks.isNotEmpty) {
        final saved = await _bookmarks.saveBookmarks(backup.bookmarks);
        if (saved.isLeft()) return saved.map((_) => RestoreResult.restored);
      }
      if (backup.history.isNotEmpty) {
        final saved = await _history.saveHistory(backup.history);
        if (saved.isLeft()) return saved.map((_) => RestoreResult.restored);
      }
      if (backup.categories.isNotEmpty) {
        final saved = await _categories.saveCategories(backup.categories);
        if (saved.isLeft()) return saved.map((_) => RestoreResult.restored);
      }
      if (backup.comicCategories.isNotEmpty) {
        final saved = await _categories.saveComicCategories(
          backup.comicCategories,
        );
        if (saved.isLeft()) return saved.map((_) => RestoreResult.restored);
      }
      return right(RestoreResult.restored);
    });
  }
}
