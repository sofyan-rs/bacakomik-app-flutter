import 'package:bacakomik_app/core/domain/entities/comic.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/explore/domain/entities/explore_filter.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class ExploreRepository {
  Future<Either<Failure, List<Comic>>> explore(ExploreFilter filter, int page);
}
