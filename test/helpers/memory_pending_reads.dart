import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/migration/domain/repositories/pending_read_repository.dart';
import 'package:fpdart/fpdart.dart';

/// [PendingReadRepository] over a map.
class MemoryPendingReads implements PendingReadRepository {
  final values = <String, String>{};

  @override
  Future<Either<Failure, String?>> lastReadOf(String key) async =>
      right(values[key]);

  @override
  Future<Either<Failure, Unit>> save(Map<String, String> lastRead) async {
    values.addAll(lastRead);
    return right(unit);
  }

  @override
  Future<Either<Failure, Unit>> remove(String key) async {
    values.remove(key);
    return right(unit);
  }
}
