import 'package:bacakomik_app/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

/// Reading progress imported from another app, kept until the comic's
/// chapter list is known. Stays on this device; it is not synced.
abstract interface class PendingReadRepository {
  /// Number of the last chapter read, by comic key; null when none waits.
  Future<Either<Failure, String?>> lastReadOf(String key);

  /// Inserts or replaces last read chapter numbers by comic key.
  Future<Either<Failure, Unit>> save(Map<String, String> lastRead);

  Future<Either<Failure, Unit>> remove(String key);
}
