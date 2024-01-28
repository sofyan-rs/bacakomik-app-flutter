part of 'comic_details_bloc.dart';

@immutable
sealed class ComicDetailsEvent {}

final class GetComicDetails extends ComicDetailsEvent {
  final String slug;

  GetComicDetails(this.slug);
}
