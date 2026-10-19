import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/home/domain/entities/home.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class HomeRepository {
  Future<Either<Failure, Home>> getHome();
}
