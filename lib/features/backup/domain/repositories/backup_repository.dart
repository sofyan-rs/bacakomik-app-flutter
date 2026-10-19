import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/backup/domain/entities/library_backup.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class BackupRepository {
  /// Asks the user for a folder and writes [backup] there.
  /// Returns false when the user cancels.
  Future<Either<Failure, bool>> exportBackup(LibraryBackup backup);

  /// Asks the user for a backup file and reads it.
  /// Returns null when the user cancels.
  Future<Either<Failure, LibraryBackup?>> importBackup();
}
