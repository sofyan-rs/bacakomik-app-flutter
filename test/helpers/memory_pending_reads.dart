import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/migration/domain/entities/pending_read.dart';
import 'package:bacakomik_app/features/migration/domain/repositories/pending_read_repository.dart';
import 'package:fpdart/fpdart.dart';

/// [PendingReadRepository] over a map.
class MemoryPendingReads implements PendingReadRepository {
  final values = <String, PendingRead>{};

  @override
  Future<Either<Failure, PendingRead?>> pendingOf(String key) async =>
      right(values[key]);

  @override
  Future<Either<Failure, Unit>> save(Map<String, PendingRead> pending) async {
    values.addAll(pending);
    return right(unit);
  }

  @override
  Future<Either<Failure, Unit>> remove(String key) async {
    values.remove(key);
    return right(unit);
  }

  @override
  Future<Either<Failure, Unit>> removeIfUnchanged(
    String key,
    PendingRead expected,
  ) async {
    if (values[key] == expected) values.remove(key);
    return right(unit);
  }
}
