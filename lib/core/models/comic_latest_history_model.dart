import 'package:bacakomik_app/core/models/comic_details_model/comic_details_model.dart';
import 'package:bacakomik_app/core/models/history_model.dart';

class ComicLatestHistoryModel {
  final String comicSlug;
  final ComicDetailsModel comicDetails;
  final HistoryModel latestHistory;

  ComicLatestHistoryModel({
    required this.comicSlug,
    required this.comicDetails,
    required this.latestHistory,
  });
}
