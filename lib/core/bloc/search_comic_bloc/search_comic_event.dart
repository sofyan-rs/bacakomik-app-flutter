part of 'search_comic_bloc.dart';

@immutable
sealed class SearchComicEvent {}

final class GetSearchResult extends SearchComicEvent {
  final String keyword;
  final int page;

  GetSearchResult({
    required this.keyword,
    required this.page,
  });
}

final class GetSearchResultNext extends SearchComicEvent {
  final String keyword;
  final int page;

  GetSearchResultNext({
    required this.keyword,
    required this.page,
  });
}
