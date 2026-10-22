import 'package:bacakomik_app/core/domain/entities/comic.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/explore/domain/entities/explore_filter.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class ExploreRepository {
  Future<Either<Failure, List<Comic>>> explore(ExploreFilter filter, int page);

  /// Every genre, sorted by name. [Genre.slug] holds the API id.
  Future<Either<Failure, List<Genre>>> genres();
}
