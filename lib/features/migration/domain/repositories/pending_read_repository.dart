import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/migration/domain/entities/pending_read.dart';
import 'package:fpdart/fpdart.dart';

/// Reading progress imported from another app, kept until the comic's
/// chapter list is known. Stays on this device; it is not synced.
abstract interface class PendingReadRepository {
  /// What waits for the comic with [key]; null when nothing does.
  Future<Either<Failure, PendingRead?>> pendingOf(String key);

  /// Inserts or replaces progress by comic key.
  Future<Either<Failure, Unit>> save(Map<String, PendingRead> pending);

  Future<Either<Failure, Unit>> remove(String key);
}
