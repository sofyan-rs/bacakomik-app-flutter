import 'package:yoru/core/domain/entities/comic.dart';
import 'package:yoru/core/error/failures.dart';
import 'package:yoru/features/explore/domain/entities/explore_filter.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class ExploreRepository {
  Future<Either<Failure, List<Comic>>> explore(ExploreFilter filter, int page);
}
