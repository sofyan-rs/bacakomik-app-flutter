import 'dart:convert';

import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/migration/data/datasources/mihon_backup_parser.dart';
import 'package:bacakomik_app/features/migration/data/datasources/migration_file_data_source.dart';
import 'package:bacakomik_app/features/migration/domain/entities/comix_csv.dart';
import 'package:bacakomik_app/features/migration/domain/entities/mihon_backup.dart';
import 'package:bacakomik_app/features/migration/domain/repositories/migration_file_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: MigrationFileRepository)
class MigrationFileRepositoryImpl implements MigrationFileRepository {
  const MigrationFileRepositoryImpl(this._files);

  final MigrationFileDataSource _files;

  @override
  Future<Either<Failure, MihonBackup?>> pickMihonBackup() =>
      _pick(const ['tachibk', 'proto.gz'], parseMihonBackup);

  @override
  Future<Either<Failure, List<ComixCsvEntry>?>> pickComixCsv() => _pick(const [
    'csv',
  ], (bytes) => parseComixCsv(utf8.decode(bytes, allowMalformed: true)));

  Future<Either<Failure, T?>> _pick<T>(
    List<String> extensions,
    T Function(List<int> bytes) parse,
  ) async {
    try {
      final bytes = await _files.pickFile(extensions);
      if (bytes == null) return right(null);
      // Big backups take a while to unzip and decode.
      return right(await compute(parse, bytes));
    } on FormatException catch (e) {
      return left(FileFailure(e.message));
    } catch (e) {
      return left(FileFailure('$e'));
    }
  }
}
