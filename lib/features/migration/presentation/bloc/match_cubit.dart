import 'dart:async';

import 'package:bacakomik_app/core/domain/entities/comic.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/source/comic_key.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/migrate_comic.dart';
import 'package:bacakomik_app/features/migration/domain/entities/library_import.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/import_library.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/source_migration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// What the matches are for: moving bookmarks ([MatchItem.fromKey]) to the
/// target source, or adding comics found by title to the library.
enum MatchMode { migrate, import }

enum MatchStatus {
  waiting,
  searching,
  found,
  notFound,
  failed,
  skipped,

  /// Migrated or imported.
  done,

  /// Migrating failed.
  error,
}

/// One comic looked up by title in the target sources.
class MatchItem {
  const MatchItem({
    required this.title,
    this.altTitles = const [],
    this.fromKey,
    this.lastRead,
    this.status = MatchStatus.waiting,
    this.match,
    this.message,
  });

  final String title;

  /// Other titles of the comic, tried when [title] finds nothing.
  final List<String> altTitles;

  /// Bookmark to move, in [MatchMode.migrate].
  final String? fromKey;

  /// Last chapter read elsewhere, in [MatchMode.import].
  final String? lastRead;

  final MatchStatus status;

  /// The comic in a target source; set when [status] is found or done.
  final Comic? match;

  /// Error of a failed search or migration.
  final String? message;

  MatchItem copyWith({MatchStatus? status, Comic? match, String? message}) =>
      MatchItem(
        title: title,
        altTitles: altTitles,
        fromKey: fromKey,
        lastRead: lastRead,
        status: status ?? this.status,
        match: match ?? this.match,
        message: message,
      );

  /// Picked as the match, and not applied yet.
  bool get ready => status == MatchStatus.found && match != null;
}

enum MatchPhase { searching, review, applying, finished }

class MatchState {
  const MatchState({
    this.items = const [],
    this.phase = MatchPhase.searching,
    this.result,
  });

  final List<MatchItem> items;
  final MatchPhase phase;

  /// Set when an import finished.
  final ImportResult? result;

  int get readyCount => items.where((i) => i.ready).length;

  int count(MatchStatus status) =>
      items.where((i) => i.status == status).length;

  /// Items searched so far, found or not.
  int get searched => items
      .where(
        (i) =>
            i.status != MatchStatus.waiting &&
            i.status != MatchStatus.searching,
      )
      .length;

  MatchState copyWith({
    List<MatchItem>? items,
    MatchPhase? phase,
    ImportResult? result,
  }) => MatchState(
    items: items ?? this.items,
    phase: phase ?? this.phase,
    result: result ?? this.result,
  );
}

/// Finds comics by title in the target sources, one at a time with a pause
/// between searches so sites do not block the user. Each comic is looked up
/// in [targets] in order until one has a result with the same title (case,
/// spacing and punctuation ignored), which is picked automatically; the
/// rest wait for the user. [apply] then migrates or imports the picks.
@injectable
class MatchCubit extends Cubit<MatchState> {
  MatchCubit(this._search, this._migrate, this._import, this._clock)
    : super(const MatchState());

  /// Pause between two searches, and between two migrations.
  static const gap = Duration(seconds: 3);

  final SearchSource _search;
  final MigrateToSource _migrate;
  final ImportLibrary _import;
  final Clock _clock;

  late MatchMode mode;

  /// Sources the comics are looked up in, most wanted first.
  late List<String> targets;

  DateTime? _lastRequest;

  void start({
    required MatchMode mode,
    required List<String> targets,
    required List<MatchItem> items,
  }) {
    this.mode = mode;
    this.targets = targets;
    emit(MatchState(items: items));
    unawaited(_searchAll());
  }

  Future<void> _searchAll() async {
    for (var i = 0; i < state.items.length; i++) {
      if (isClosed) return;
      if (state.items[i].status != MatchStatus.waiting) continue;
      await _searchItem(i);
    }
    if (!isClosed && state.phase == MatchPhase.searching) {
      emit(state.copyWith(phase: MatchPhase.review));
    }
  }

  /// Looks item [i] up in each of [targetsOf] it in turn, until one finds
  /// it. Failed only when every source failed.
  Future<void> _searchItem(int i) async {
    _update(i, state.items[i].copyWith(status: MatchStatus.searching));
    final first = state.items[i];
    Failure? failure;
    var answered = false;
    Comic? found;
    for (final source in targetsOf(first)) {
      for (final query in [first.title, ...altQueries(first)]) {
        final result = await search(query, source: source);
        if (isClosed) return;
        // The user may have picked or skipped it meanwhile.
        if (state.items[i].status != MatchStatus.searching) return;
        found = result.fold(
          (f) {
            failure ??= f;
            return null;
          },
          (comics) {
            answered = true;
            return exactMatch(first.title, comics, altTitles: first.altTitles);
          },
        );
        // A failed search moves on to the next source; alternative titles
        // won't help.
        if (found != null || result.isLeft()) break;
      }
      if (found != null) break;
    }
    final item = state.items[i];
    _update(i, switch ((found, failure)) {
      (final comic?, _) => item.copyWith(
        status: MatchStatus.found,
        match: comic,
      ),
      (_, final failure?) when !answered => item.copyWith(
        status: MatchStatus.failed,
        message: failure.message,
      ),
      _ => item.copyWith(status: MatchStatus.notFound),
    });
  }

  /// [targets] [item] is looked up in: all but the source it is moved from.
  List<String> targetsOf(MatchItem item) => [
    for (final t in targets)
      if (item.fromKey == null || ComicKey.sourceOf(item.fromKey!) != t) t,
  ];

  /// Most alternative titles searched for an item whose title finds nothing.
  static const maxAltQueries = 2;

  static final _latin = RegExp('[A-Za-z]');

  /// The alternative titles to search when [item]'s title finds nothing:
  /// those in Latin letters first, which sites index most often.
  static List<String> altQueries(MatchItem item) {
    final title = normalizeTitle(item.title);
    final alts = [
      for (final t in item.altTitles)
        if (normalizeTitle(t) case final n when n.isNotEmpty && n != title) t,
    ];
    return [
      ...alts.where(_latin.hasMatch),
      ...alts.where((t) => !_latin.hasMatch(t)),
    ].take(maxAltQueries).toList();
  }

  /// A title search in [source], the first of [targets] by default.
  /// Requests run one at a time, [gap] apart, also when the user searches
  /// while the automatic search runs.
  Future<Either<Failure, List<Comic>>> search(String query, {String? source}) =>
      _serial(() => _search((sourceId: source ?? targets.first, query: query)));

  /// The user picked [comic] for item [i].
  void pick(int i, Comic comic) => _update(
    i,
    state.items[i].copyWith(status: MatchStatus.found, match: comic),
  );

  void skip(int i) =>
      _update(i, state.items[i].copyWith(status: MatchStatus.skipped));

  /// Migrates or imports every picked match, once the search ended: while
  /// it runs, comics found later would be left out.
  Future<void> apply() async {
    if (state.phase != MatchPhase.review) return;
    emit(state.copyWith(phase: MatchPhase.applying));
    switch (mode) {
      case MatchMode.migrate:
        await _migrateAll();
        if (isClosed) return;
        emit(state.copyWith(phase: MatchPhase.finished));
      case MatchMode.import:
        final picked = [
          for (final (i, item) in state.items.indexed)
            if (item.ready) (i, item),
        ];
        final result = await _import([
          for (final (_, item) in picked)
            ImportEntry(
              key: item.match!.slug,
              title: item.match!.title,
              lastRead: item.lastRead,
            ),
        ]);
        if (isClosed) return;
        result.fold(
          (failure) => emit(
            state.copyWith(
              phase: MatchPhase.review,
              items: [
                for (final item in state.items)
                  item.ready ? item.copyWith(message: failure.message) : item,
              ],
            ),
          ),
          (result) => emit(
            state.copyWith(
              phase: MatchPhase.finished,
              result: result,
              items: [
                for (final item in state.items)
                  item.ready ? item.copyWith(status: MatchStatus.done) : item,
              ],
            ),
          ),
        );
    }
  }

  Future<void> _migrateAll() async {
    for (var i = 0; i < state.items.length; i++) {
      final item = state.items[i];
      if (isClosed) return;
      if (!item.ready || item.fromKey == null) continue;
      final result = await _serial(
        () => _migrate((from: item.fromKey!, to: item.match!.slug)),
      );
      if (isClosed) return;
      _update(
        i,
        result.fold(
          (failure) => item.copyWith(
            status: MatchStatus.error,
            message: failure.message,
          ),
          (_) => item.copyWith(status: MatchStatus.done),
        ),
      );
    }
  }

  Future<void> _lock = Future.value();

  Future<T> _serial<T>(Future<T> Function() request) {
    final run = _lock.then((_) async {
      await _wait();
      return request();
    });
    _lock = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  Future<void> _wait() async {
    final last = _lastRequest;
    if (last != null) {
      final left = gap - _clock.now().difference(last);
      if (left > Duration.zero) await Future<void>.delayed(left);
    }
    _lastRequest = _clock.now();
  }

  void _update(int i, MatchItem item) {
    if (isClosed) return;
    emit(state.copyWith(items: [...state.items]..[i] = item));
  }
}
