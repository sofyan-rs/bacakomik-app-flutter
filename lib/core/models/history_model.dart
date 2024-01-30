import 'package:bacakomik_app/core/models/chapter_read_model.dart';

class HistoryModel {
  final ChapterReadModel chapterReadModel;
  final DateTime readDate;

  HistoryModel({
    required this.chapterReadModel,
    required this.readDate,
  });
}
