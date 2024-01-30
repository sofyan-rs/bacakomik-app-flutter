part of 'search_comic_bloc.dart';

@immutable
sealed class SearchComicState {}

final class SearchComicInitial extends SearchComicState {}

final class SearchComicLoading extends SearchComicState {}

final class SearchComicLoaded extends SearchComicState {
  final List<ComicModel> result;
  final bool isLoadMore;

  SearchComicLoaded({
    required this.result,
    this.isLoadMore = false,
  });
}

final class SearchComicError extends SearchComicState {
  final String message;
  SearchComicError({
    required this.message,
  });
}
