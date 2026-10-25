import 'package:bacakomik_app/core/data/models/series_response.dart';
import 'package:bacakomik_app/core/domain/entities/comic.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/utils/alt_titles.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/explore/domain/entities/explore_filter.dart';
import 'package:bacakomik_app/features/explore/domain/repositories/explore_repository.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/import_library.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/source_migration.dart';
import 'package:bacakomik_app/features/migration/presentation/bloc/match_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

Comic comic(String slug, String title, [List<String> altTitles = const []]) =>
    Comic(
      title: title,
      coverImg: '',
      slug: slug,
      type: '',
      completed: false,
      rating: '',
      latestChapter: '',
      altTitles: altTitles,
    );

/// Answers searches from [results] by query and records the queries.
class FakeExplore implements ExploreRepository {
  FakeExplore(this.results);

  final Map<String, Either<Failure, List<Comic>>> results;
  final queries = <String>[];

  @override
  Future<Either<Failure, List<Comic>>> explore(
    ExploreFilter filter,
    int page,
  ) async {
    queries.add(filter.query);
    return results[filter.query] ?? right(const []);
  }
}

/// Moves on by more than [MatchCubit.gap] on every call, so tests never wait.
class StepClock extends Clock {
  var _now = DateTime(2026);

  @override
  DateTime now() => _now = _now.add(const Duration(minutes: 1));
}

class UnusedMigrate implements MigrateToSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class UnusedImport implements ImportLibrary {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('exactMatch with alternative titles', () {
    test('matches a result by one of its alternative titles', () {
      expect(
        exactMatch('Solo Leveling', [
          comic('a', 'Na Honjaman Level-Up', ['나 혼자만 레벨업', 'Solo Leveling']),
          comic('b', 'Solo Leveling: Arise'),
        ])?.slug,
        'a',
      );
    });

    test("matches by the comic's own alternative titles", () {
      expect(
        exactMatch(
          'Solo Leveling',
          [comic('a', '나 혼자만 레벨업'), comic('b', 'Solo Leveling: Arise')],
          altTitles: ['나 혼자만 레벨업'],
        )?.slug,
        'a',
      );
    });

    test('a main-title match wins over alternative titles', () {
      expect(
        exactMatch('Magic Emperor', [
          comic('a', 'Demonic Emperor', ['Magic Emperor']),
          comic('b', 'Magic Emperor'),
        ])?.slug,
        'b',
      );
    });

    test('stays null when several results match', () {
      expect(
        exactMatch('X', [
          comic('a', 'A', ['X']),
          comic('b', 'B', ['x!']),
        ]),
        isNull,
      );
    });
  });

  test('SeriesResponse keeps clean alternative titles', () {
    final c = SeriesResponse.fromJson({
      'title': 'Solo Leveling',
      'slug': 's',
      'altTitles': ['Solo Leveling', 'Updating', '나 혼자만 레벨업'],
    }).toEntity();
    expect(c.altTitles, ['나 혼자만 레벨업']);
    expect(
      SeriesResponse.fromJson({'title': 'X', 'slug': 's'}).toEntity().altTitles,
      isEmpty,
    );
  });

  test('splitAltTitles drops "Updating"', () {
    expect(splitAltTitles('X', 'Updating'), isEmpty);
  });

  test('altQueries tries Latin titles first, at most two', () {
    expect(
      MatchCubit.altQueries(
        const MatchItem(
          title: 'Solo Leveling',
          altTitles: [
            '나 혼자만 레벨업',
            'solo leveling!',
            'Only I Level Up',
            'Ore Dake',
          ],
        ),
      ),
      ['Only I Level Up', 'Ore Dake'],
    );
  });

  group('MatchCubit', () {
    Future<(MatchItem, List<String>)> run(
      MatchItem item,
      Map<String, Either<Failure, List<Comic>>> results,
    ) async {
      final explore = FakeExplore(results);
      final cubit = MatchCubit(
        SearchSource(explore),
        UnusedMigrate(),
        UnusedImport(),
        StepClock(),
      );
      cubit.start(
        mode: MatchMode.migrate,
        target: 'mangadex-en',
        items: [item],
      );
      await cubit.stream.firstWhere((s) => s.phase == MatchPhase.review);
      final result = cubit.state.items.single;
      await cubit.close();
      return (result, explore.queries);
    }

    test(
      'searches an alternative title when the title finds nothing',
      () async {
        final (item, queries) = await run(
          const MatchItem(
            title: 'I Level Up Alone',
            altTitles: ['나 혼자만 레벨업', 'Solo Leveling'],
            fromKey: 'bacakomik/x',
          ),
          {
            'Solo Leveling': right([
              comic('a', 'Na Honjaman Level-Up', ['Solo Leveling']),
            ]),
          },
        );
        expect(queries, ['I Level Up Alone', 'Solo Leveling']);
        expect(item.status, MatchStatus.found);
        expect(item.match?.slug, 'a');
      },
    );

    test('stops after the title when it matches', () async {
      final (item, queries) = await run(
        const MatchItem(title: 'A', altTitles: ['B'], fromKey: 'k'),
        {
          'A': right([comic('a', 'A')]),
        },
      );
      expect(queries, ['A']);
      expect(item.status, MatchStatus.found);
    });

    test('reports a failed search without trying alternatives', () async {
      final (item, queries) = await run(
        const MatchItem(title: 'A', altTitles: ['B'], fromKey: 'k'),
        {'A': left(const ServerFailure('boom'))},
      );
      expect(queries, ['A']);
      expect(item.status, MatchStatus.failed);
      expect(item.message, 'boom');
    });

    test('not found after the alternatives', () async {
      final (item, queries) = await run(
        const MatchItem(title: 'A', altTitles: ['B', 'C', 'D'], fromKey: 'k'),
        {},
      );
      expect(queries, ['A', 'B', 'C']);
      expect(item.status, MatchStatus.notFound);
    });
  });
}
