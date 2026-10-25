import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/storage/box_recovery.dart';
import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/storage/local_call.dart';
import 'package:bacakomik_app/features/migration/domain/repositories/pending_read_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

/// [HiveBoxes.pendingReads]: chapter number strings keyed by comic key.
@LazySingleton(as: PendingReadRepository)
class PendingReadRepositoryImpl implements PendingReadRepository {
  const PendingReadRepositoryImpl(@Named(HiveBoxes.pendingReads) this._box);

  final Box<String> _box;

  @override
  Future<Either<Failure, String?>> lastReadOf(String key) =>
      runLocal(() => _box.get(key));

  @override
  Future<Either<Failure, Unit>> save(Map<String, String> lastRead) =>
      runLocal(() async {
        await _box.putAll({
          for (final MapEntry(:key, :value) in lastRead.entries)
            if (isValidHiveKey(key)) key: value,
        });
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> remove(String key) => runLocal(() async {
    await _box.delete(key);
    return unit;
  });
}
