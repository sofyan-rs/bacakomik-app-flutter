import 'package:yoru/core/error/failures.dart';
import 'package:yoru/core/usecase/usecase.dart';
import 'package:yoru/features/home/domain/entities/home.dart';
import 'package:yoru/features/home/domain/repositories/home_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetHome implements UseCase<Home, NoParams> {
  const GetHome(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, Home>> call(NoParams params) => _repository.getHome();
}
