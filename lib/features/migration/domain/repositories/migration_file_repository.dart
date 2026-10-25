import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/migration/domain/entities/comix_csv.dart';
import 'package:bacakomik_app/features/migration/domain/entities/mihon_backup.dart';
import 'package:fpdart/fpdart.dart';

/// Library files exported by other apps. Each pick returns null when the
/// user cancels, and [FileFailure] when the file cannot be read.
abstract interface class MigrationFileRepository {
  /// A Mihon/Tachiyomi backup (`.tachibk`, also `.proto.gz`).
  Future<Either<Failure, MihonBackup?>> pickMihonBackup();

  /// A Comix.to library export (`.csv`).
  Future<Either<Failure, List<ComixCsvEntry>?>> pickComixCsv();
}
