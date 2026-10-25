import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/migration/domain/entities/comix_csv.dart';
import 'package:bacakomik_app/features/migration/domain/entities/mihon_backup.dart';
import 'package:bacakomik_app/features/migration/domain/repositories/migration_file_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Null when the user cancels.
@injectable
class PickMihonBackup implements UseCase<MihonBackup?, NoParams> {
  const PickMihonBackup(this._files);

  final MigrationFileRepository _files;

  @override
  Future<Either<Failure, MihonBackup?>> call(NoParams params) =>
      _files.pickMihonBackup();
}

/// Null when the user cancels.
@injectable
class PickComixCsv implements UseCase<List<ComixCsvEntry>?, NoParams> {
  const PickComixCsv(this._files);

  final MigrationFileRepository _files;

  @override
  Future<Either<Failure, List<ComixCsvEntry>?>> call(NoParams params) =>
      _files.pickComixCsv();
}
