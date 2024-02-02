part of 'comic_list_bloc.dart';

@immutable
sealed class ComicListEvent {}

final class GetComicList extends ComicListEvent {}
