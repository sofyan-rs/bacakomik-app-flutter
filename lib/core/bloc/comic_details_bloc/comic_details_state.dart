part of 'comic_details_bloc.dart';

@immutable
sealed class ComicDetailsState {}

final class ComicDetailsInitial extends ComicDetailsState {}

final class ComicDetailsLoading extends ComicDetailsState {}

final class ComicDetailsLoaded extends ComicDetailsState {
  final ComicDetailsModel comicDetails;
  ComicDetailsLoaded({
    required this.comicDetails,
  });
}

final class ComicDetailsError extends ComicDetailsState {
  final String message;
  ComicDetailsError({
    required this.message,
  });
}
