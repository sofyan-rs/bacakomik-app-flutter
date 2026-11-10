import 'package:yoru/core/domain/entities/comic.dart';
import 'package:yoru/core/error/failures.dart';
import 'package:yoru/core/usecase/usecase.dart';
import 'package:yoru/features/latest/domain/repositories/latest_repository.dart';
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
