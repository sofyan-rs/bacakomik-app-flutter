import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

/// A comic found in the API's current source.
typedef SeriesMatch = ({String slug, ComicDetails details});

/// Finds comics stored before the API switched source.
abstract interface class SeriesLookupRepository {
  /// The comic stored as [slug] with [stored] details: the series with the
  /// same slug, otherwise the one with the same title. Null when neither
  /// exists. A failure means the lookup could not finish (offline, rate
  /// limited) and should be retried later.
  Future<Either<Failure, SeriesMatch?>> find(String slug, ComicDetails stored);
}
