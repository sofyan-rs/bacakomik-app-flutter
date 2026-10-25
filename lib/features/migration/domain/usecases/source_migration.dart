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
///
/// When no result has [title] as its title, a result matches if any of its
/// titles (main or [Comic.altTitles]) is [title] or one of [altTitles]:
/// sources often name a comic differently (`Solo Leveling` and
/// `Na Honjaman Level-Up`).
Comic? exactMatch(
  String title,
  List<Comic> results, {
  List<String> altTitles = const [],
}) {
  final wanted = normalizeTitle(title);
  if (wanted.isEmpty) return null;
  final byTitle = results.where((c) => normalizeTitle(c.title) == wanted);
  if (byTitle.isNotEmpty) return byTitle.length == 1 ? byTitle.single : null;

  final names = {wanted, for (final t in altTitles) normalizeTitle(t)}
    ..remove('');
  final byAnyTitle = results.where(
    (c) =>
        [c.title, ...c.altTitles].any((t) => names.contains(normalizeTitle(t))),
  );
  return byAnyTitle.length == 1 ? byAnyTitle.single : null;
}
