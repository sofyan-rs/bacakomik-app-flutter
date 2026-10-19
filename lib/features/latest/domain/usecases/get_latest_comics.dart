import 'package:bacakomik_app/core/domain/entities/comic.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/latest/domain/repositories/latest_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Params: page number, starting at 1.
@injectable
class GetLatestComics implements UseCase<List<Comic>, int> {
  const GetLatestComics(this._repository);

  final LatestRepository _repository;

  @override
  Future<Either<Failure, List<Comic>>> call(int page) =>
      _repository.getLatest(page);
}
