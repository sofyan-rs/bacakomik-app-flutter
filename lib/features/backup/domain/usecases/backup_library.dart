import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/backup/domain/entities/library_backup.dart';
import 'package:bacakomik_app/features/backup/domain/repositories/backup_repository.dart';
import 'package:bacakomik_app/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:bacakomik_app/features/history/domain/repositories/history_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Writes all bookmarks and history to a backup file.
@injectable
class BackupLibrary implements UseCase<BackupResult, NoParams> {
  const BackupLibrary(this._backup, this._bookmarks, this._history);

  final BackupRepository _backup;
  final BookmarkRepository _bookmarks;
  final HistoryRepository _history;

  @override
  Future<Either<Failure, BackupResult>> call(NoParams params) async {
    final bookmarks = await _bookmarks.getBookmarks();
    final history = await _history.getHistory();

    return bookmarks.flatMap((b) => history.map((h) => (b, h))).fold(
      (failure) async => left(failure),
      (data) async {
        final backup = LibraryBackup(bookmarks: data.$1, history: data.$2);
        if (backup.isEmpty) return right(BackupResult.nothingToSave);

        final saved = await _backup.exportBackup(backup);
        return saved.map(
          (ok) => ok ? BackupResult.saved : BackupResult.cancelled,
        );
      },
    );
  }
}

/// Merges a backup file into the library. Entries with the same slug are
/// replaced by the backup's version.
@injectable
class RestoreLibrary implements UseCase<RestoreResult, NoParams> {
  const RestoreLibrary(this._backup, this._bookmarks, this._history);

  final BackupRepository _backup;
  final BookmarkRepository _bookmarks;
  final HistoryRepository _history;

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
      return right(RestoreResult.restored);
    });
  }
}
