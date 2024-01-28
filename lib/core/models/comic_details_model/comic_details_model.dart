import 'dart:convert';
import 'package:flutter/foundation.dart';

part 'chapter_model.dart';
part 'genre_model.dart';

class ComicDetailsModel {
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
  ComicDetailsModel({
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
  });

  ComicDetailsModel copyWith({
    String? title,
    String? coverImg,
    String? alternativeTitle,
    String? released,
    String? status,
    String? totalChapter,
    String? author,
    String? type,
    String? rating,
    String? synopsis,
    List<GenreModel>? genres,
    List<ChapterModel>? chapters,
  }) {
    return ComicDetailsModel(
      title: title ?? this.title,
      coverImg: coverImg ?? this.coverImg,
      alternativeTitle: alternativeTitle ?? this.alternativeTitle,
      released: released ?? this.released,
      status: status ?? this.status,
      totalChapter: totalChapter ?? this.totalChapter,
      author: author ?? this.author,
      type: type ?? this.type,
      rating: rating ?? this.rating,
      synopsis: synopsis ?? this.synopsis,
      genres: genres ?? this.genres,
      chapters: chapters ?? this.chapters,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'coverImg': coverImg,
      'alternativeTitle': alternativeTitle,
      'released': released,
      'status': status,
      'totalChapter': totalChapter,
      'author': author,
      'type': type,
      'rating': rating,
      'synopsis': synopsis,
      'genres': genres.map((x) => x.toMap()).toList(),
      'chapters': chapters.map((x) => x.toMap()).toList(),
    };
  }

  factory ComicDetailsModel.fromMap(Map<String, dynamic> map) {
    return ComicDetailsModel(
      title: map['title'] as String,
      coverImg: map['coverImg'] as String,
      alternativeTitle: map['alternativeTitle'] as String,
      released: map['released'] as String,
      status: map['status'] as String,
      totalChapter: map['totalChapter'] as String,
      author: map['author'] as String,
      type: map['type'] as String,
      rating: map['rating'] as String,
      synopsis: map['synopsis'] as String,
      genres: List<GenreModel>.from(
        (map['genres'] as List<dynamic>).map<GenreModel>(
          (x) => GenreModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
      chapters: List<ChapterModel>.from(
        (map['chapters'] as List<dynamic>).map<ChapterModel>(
          (x) => ChapterModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory ComicDetailsModel.fromJson(String source) =>
      ComicDetailsModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ComicDetailsModel(title: $title, coverImg: $coverImg, alternativeTitle: $alternativeTitle, released: $released, status: $status, totalChapter: $totalChapter, author: $author, type: $type, rating: $rating, synopsis: $synopsis, genres: $genres, chapters: $chapters)';
  }

  @override
  bool operator ==(covariant ComicDetailsModel other) {
    if (identical(this, other)) return true;

    return other.title == title &&
        other.coverImg == coverImg &&
        other.alternativeTitle == alternativeTitle &&
        other.released == released &&
        other.status == status &&
        other.totalChapter == totalChapter &&
        other.author == author &&
        other.type == type &&
        other.rating == rating &&
        other.synopsis == synopsis &&
        listEquals(other.genres, genres) &&
        listEquals(other.chapters, chapters);
  }

  @override
  int get hashCode {
    return title.hashCode ^
        coverImg.hashCode ^
        alternativeTitle.hashCode ^
        released.hashCode ^
        status.hashCode ^
        totalChapter.hashCode ^
        author.hashCode ^
        type.hashCode ^
        rating.hashCode ^
        synopsis.hashCode ^
        genres.hashCode ^
        chapters.hashCode;
  }
}
