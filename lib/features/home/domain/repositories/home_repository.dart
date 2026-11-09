import 'package:yoru/core/error/failures.dart';
import 'package:yoru/features/home/domain/entities/home.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class HomeRepository {
  Future<Either<Failure, Home>> getHome();
}
