part of 'chapter_read_bloc.dart';

@immutable
sealed class ChapterReadEvent {}

final class GetChapterRead extends ChapterReadEvent {
  final String slug;

  GetChapterRead(this.slug);
}
