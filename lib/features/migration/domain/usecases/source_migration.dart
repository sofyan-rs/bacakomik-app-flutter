import 'package:bacakomik_app/core/domain/entities/comic.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/migrate_comic.dart';
import 'package:bacakomik_app/features/comic_detail/domain/repositories/comic_detail_repository.dart';
import 'package:bacakomik_app/features/explore/domain/entities/explore_filter.dart';
import 'package:bacakomik_app/features/explore/domain/repositories/explore_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

typedef SearchSourceParams = ({String sourceId, String query});

/// First page of a title search in one source.
@injectable
class SearchSource implements UseCase<List<Comic>, SearchSourceParams> {
  const SearchSource(this._explore);

  final ExploreRepository _explore;

  @override
  Future<Either<Failure, List<Comic>>> call(SearchSourceParams params) =>
      _explore.explore(
        ExploreFilter(source: params.sourceId, query: params.query.trim()),
        1,
      );
}

typedef MigrateToSourceParams = ({String from, String to});

/// Loads the comic [MigrateToSourceParams.to] from its source, then moves
/// the bookmark, history and categories of [MigrateToSourceParams.from] to
/// it with [MigrateComic].
@injectable
class MigrateToSource implements UseCase<Unit, MigrateToSourceParams> {
  const MigrateToSource(this._comicDetails, this._migrateComic);

  final ComicDetailRepository _comicDetails;
  final MigrateComic _migrateComic;

  @override
  Future<Either<Failure, Unit>> call(MigrateToSourceParams params) async {
    final details = await _comicDetails.getComicDetails(params.to);
    return details.fold(
      (failure) async => left(failure),
      (details) =>
          _migrateComic((from: params.from, to: params.to, details: details)),
    );
  }
}

/// The result that is [title] once case, spacing and punctuation are
/// ignored; null when none or several are.
Comic? exactMatch(String title, List<Comic> results) {
  final wanted = normalizeTitle(title);
  if (wanted.isEmpty) return null;
  final matches = results.where((c) => normalizeTitle(c.title) == wanted);
  return matches.length == 1 ? matches.single : null;
}
