import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/storage/box_recovery.dart';
import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/storage/local_call.dart';
import 'package:bacakomik_app/features/migration/domain/entities/pending_read.dart';
import 'package:bacakomik_app/features/migration/domain/repositories/pending_read_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

/// [HiveBoxes.pendingReads]: [PendingRead.encode] keyed by comic key. Older
/// versions stored a bare chapter number, which reads as [PendingRead.upTo].
@LazySingleton(as: PendingReadRepository)
class PendingReadRepositoryImpl implements PendingReadRepository {
  const PendingReadRepositoryImpl(@Named(HiveBoxes.pendingReads) this._box);

  final Box<String> _box;

  @override
  Future<Either<Failure, PendingRead?>> pendingOf(String key) => runLocal(
    () => switch (_box.get(key)) {
      final value? => PendingRead.decode(value),
      null => null,
    },
  );

  @override
  Future<Either<Failure, Unit>> save(Map<String, PendingRead> pending) =>
      runLocal(() async {
        await _box.putAll({
          for (final MapEntry(:key, :value) in pending.entries)
            if (isValidHiveKey(key) && !value.isEmpty) key: value.encode(),
        });
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> remove(String key) => runLocal(() async {
    await _box.delete(key);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> removeIfUnchanged(
    String key,
    PendingRead expected,
  ) => runLocal(() async {
    // Read and delete in one synchronous step: Hive applies the delete to
    // its index before the first await, so no save can come in between.
    if (_box.get(key) case final value?
        when PendingRead.decode(value) == expected) {
      await _box.delete(key);
    }
    return unit;
  });
}
