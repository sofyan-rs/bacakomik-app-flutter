import 'package:yoru/core/domain/entities/comic.dart';
import 'package:yoru/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class LatestRepository {
  Future<Either<Failure, List<Comic>>> getLatest(int page);
}
