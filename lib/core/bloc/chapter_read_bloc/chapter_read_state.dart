part of 'chapter_read_bloc.dart';

@immutable
sealed class ChapterReadState {}

final class ChapterReadInitial extends ChapterReadState {}

final class ChapterReadLoading extends ChapterReadState {}

final class ChapterReadLoaded extends ChapterReadState {
  final ChapterReadModel chapterRead;

  ChapterReadLoaded({
    required this.chapterRead,
  });
}

final class ChapterReadError extends ChapterReadState {
  final String message;

  ChapterReadError({
    required this.message,
  });
}

final class NoInternet extends ChapterReadState {}
