import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:json_annotation/json_annotation.dart';

part 'comic_details_model.g.dart';

/// Stored copy of [ComicDetails] inside bookmarks, history and backup files.
@JsonSerializable()
class ComicDetailsModel {
  const ComicDetailsModel({
    required this.title,
    required this.coverImg,
    required this.alternativeTitle,
    required this.released,
    required this.status,
    required this.totalChapter,
    required this.author,
    required this.type,
    required this.rating,
    required this.synopsis,
    required this.genres,
    required this.chapters,
    this.source,
  });

  factory ComicDetailsModel.fromEntity(ComicDetails e) => ComicDetailsModel(
        title: e.title,
        coverImg: e.coverImg,
        alternativeTitle: e.alternativeTitle,
        released: e.released,
        status: e.status,
        totalChapter: e.totalChapter,
        author: e.author,
        type: e.type,
        rating: e.rating,
        synopsis: e.synopsis,
        genres: e.genres
            .map((g) => GenreModel(name: g.name, slug: g.slug))
            .toList(),
        chapters: e.chapters
            .map((c) => ChapterModel(number: c.number, slug: c.slug, date: c.date))
            .toList(),
        source: e.source,
      );

  factory ComicDetailsModel.fromJson(Map<String, dynamic> json) =>
      _$ComicDetailsModelFromJson(json);

  final String title;
  final String coverImg;
  final String alternativeTitle;
  final String released;
  final String status;
  final String totalChapter;
  final String author;
  final String type;
  final String rating;
  final String synopsis;
  final List<GenreModel> genres;
  final List<ChapterModel> chapters;

  /// See [ComicDetails.source]. Absent in data stored before the switch.
  @JsonKey(includeIfNull: false)
  final String? source;

  Map<String, dynamic> toJson() => _$ComicDetailsModelToJson(this);

  ComicDetails toEntity() => ComicDetails(
        title: title,
        coverImg: coverImg,
        alternativeTitle: alternativeTitle,
        released: released,
        status: status,
        totalChapter: totalChapter,
        author: author,
        type: type,
        rating: rating,
        synopsis: synopsis,
        genres: genres.map((g) => Genre(name: g.name, slug: g.slug)).toList(),
        chapters: chapters
            .map((c) => Chapter(number: c.number, slug: c.slug, date: c.date))
            .toList(),
        source: source,
      );
}

@JsonSerializable()
class GenreModel {
  const GenreModel({required this.name, required this.slug});

  factory GenreModel.fromJson(Map<String, dynamic> json) =>
      _$GenreModelFromJson(json);

  final String name;
  final String slug;

  Map<String, dynamic> toJson() => _$GenreModelToJson(this);
}

@JsonSerializable()
class ChapterModel {
  const ChapterModel({
    required this.number,
    required this.slug,
    required this.date,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) =>
      _$ChapterModelFromJson(json);

  final String number;
  final String slug;
  final String date;

  Map<String, dynamic> toJson() => _$ChapterModelToJson(this);
}

/// Dates were stored as milliseconds since epoch.
class EpochMillisConverter implements JsonConverter<DateTime, int> {
  const EpochMillisConverter();

  @override
  DateTime fromJson(int json) => DateTime.fromMillisecondsSinceEpoch(json);

  @override
  int toJson(DateTime object) => object.millisecondsSinceEpoch;
}
