import 'dart:math';

import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/category/domain/entities/category.dart';
import 'package:bacakomik_app/features/category/domain/usecases/category_usecases.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Categories and which comics are in them.
class CategoryState {
  const CategoryState({this.categories = const [], this.bySlug = const {}});

  /// Lowest [LibraryCategory.order] first.
  final List<LibraryCategory> categories;
  final Map<String, ComicCategories> bySlug;

  /// Ids of the existing categories the comic [slug] is in.
  Set<String> idsOf(String slug) {
    final ids = bySlug[slug]?.categoryIds ?? const [];
    return {
      for (final id in ids)
        if (categories.any((c) => c.id == id)) id,
    };
  }
}

@injectable
class CategoryCubit extends Cubit<CategoryState> {
  CategoryCubit(
    this._getCategories,
    this._saveCategories,
    this._deleteCategories,
    this._getComicCategories,
    this._saveComicCategories,
    this._clock,
  ) : super(const CategoryState());

  final GetCategories _getCategories;
  final SaveCategories _saveCategories;
  final DeleteCategories _deleteCategories;
  final GetComicCategories _getComicCategories;
  final SaveComicCategories _saveComicCategories;
  final Clock _clock;
  final _random = Random();

  Future<void> load() async {
    final categories = await _getCategories(const NoParams());
    final bySlug = await _getComicCategories(const NoParams());
    categories
        .flatMap((c) => bySlug.map((b) => (c, b)))
        .fold(
          _log,
          (data) => emit(CategoryState(categories: data.$1, bySlug: data.$2)),
        );
  }

  /// Adds a category after the others.
  Future<void> create(String name) {
    final order = state.categories.fold(-1, (m, c) => max(m, c.order)) + 1;
    return _thenReload(
      _saveCategories([
        LibraryCategory(
          id: _newId(),
          name: name.trim(),
          order: order,
          updatedDate: _clock.now(),
        ),
      ]),
    );
  }

  Future<void> rename(String id, String name) {
    final category = state.categories.where((c) => c.id == id).firstOrNull;
    if (category == null) return Future.value();
    return _thenReload(
      _saveCategories([
        category.copyWith(name: name.trim(), updatedDate: _clock.now()),
      ]),
    );
  }

  Future<void> delete(String id) => _thenReload(_deleteCategories([id]));

  /// Moves the category at [from] to [to] (indexes in [CategoryState.
  /// categories], [to] counted after the removal).
  Future<void> move(int from, int to) {
    final list = [...state.categories];
    list.insert(to, list.removeAt(from));
    final now = _clock.now();
    return _thenReload(
      _saveCategories([
        for (final (order, category) in list.indexed)
          if (category.order != order)
            category.copyWith(order: order, updatedDate: now),
      ]),
    );
  }

  /// Puts every comic of [slugs] in [add] and takes it out of [remove];
  /// other categories stay as they are.
  Future<void> setCategories(
    Iterable<String> slugs, {
    Set<String> add = const {},
    Set<String> remove = const {},
  }) {
    final now = _clock.now();
    return _thenReload(
      _saveComicCategories([
        for (final slug in slugs)
          ComicCategories(
            slug: slug,
            categoryIds: ({
              ...state.idsOf(slug),
              ...add,
            }..removeAll(remove)).toList(),
            updatedDate: now,
          ),
      ]),
    );
  }

  String _newId() =>
      _clock.now().microsecondsSinceEpoch.toRadixString(36) +
      _random.nextInt(1 << 32).toRadixString(36);

  Future<void> _thenReload(Future<Either<Failure, Unit>> action) async {
    (await action).fold(_log, (_) {});
    await load();
  }

  void _log(Failure failure) => debugPrint('CategoryCubit: $failure');
}
