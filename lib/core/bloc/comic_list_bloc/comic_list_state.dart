part of 'comic_list_bloc.dart';

@immutable
sealed class ComicListState {}

final class ComicListInitial extends ComicListState {}

final class ComicListLoading extends ComicListState {}

final class ComicListLoaded extends ComicListState {
  final List<ComicListModel> comicList;

  ComicListLoaded({
    required this.comicList,
  });
}

final class ComicListError extends ComicListState {
  final String message;

  ComicListError({
    required this.message,
  });
}

final class NoInternet extends ComicListState {}
