import 'package:bacakomik_app/core/domain/entities/comic.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class LatestRepository {
  Future<Either<Failure, List<Comic>>> getLatest(int page);
}
