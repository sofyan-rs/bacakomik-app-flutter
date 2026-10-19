import 'package:bacakomik_app/core/domain/entities/comic.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'comic_list_state.freezed.dart';

/// State shared by the paginated comic lists (latest, search, explore).
@freezed
sealed class ComicListState with _$ComicListState {
  const factory ComicListState.initial() = ComicListInitial;
  const factory ComicListState.loading() = ComicListLoading;
  const factory ComicListState.loaded({
    required List<Comic> comics,
    @Default(false) bool isLoadMore,
  }) = ComicListLoaded;
  const factory ComicListState.error({required String message}) =
      ComicListError;
  const factory ComicListState.noInternet() = ComicListNoInternet;
}

typedef ComicPage = Future<Either<Failure, List<Comic>>>;
typedef ComicPageFetcher = ComicPage Function();

/// First-page and next-page loading for blocs that emit [ComicListState].
mixin ComicListLoader<E> on Bloc<E, ComicListState> {
  Future<void> loadFirstPage(
    Emitter<ComicListState> emit,
    ComicPageFetcher fetch,
  ) async {
    emit(const ComicListState.loading());
    final result = await fetch();
    emit(result.fold(_failureState, (c) => ComicListState.loaded(comics: c)));
  }

  /// Appends the next page; ignored until a first page has loaded.
  Future<void> loadNextPage(
    Emitter<ComicListState> emit,
    ComicPageFetcher fetch,
  ) async {
    final current = state;
    if (current is! ComicListLoaded) return;

    emit(current.copyWith(isLoadMore: true));
    final result = await fetch();
    emit(result.fold(
      _failureState,
      (c) => ComicListState.loaded(comics: [...current.comics, ...c]),
    ));
  }

  ComicListState _failureState(Failure failure) => switch (failure) {
        NetworkFailure() => const ComicListState.noInternet(),
        _ => ComicListState.error(message: failure.message),
      };
}
