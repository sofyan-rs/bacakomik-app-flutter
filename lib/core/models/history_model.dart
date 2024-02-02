import 'dart:convert';
import 'package:bacakomik_app/core/models/comic_details_model/comic_details_model.dart';

class HistoryModel {
  final String slug;
  final String chapterNumber;
  final DateTime readDate;
  final ComicDetailsModel comicDetails;
  final String comicSlug;

  HistoryModel({
    required this.slug,
    required this.chapterNumber,
    required this.readDate,
    required this.comicDetails,
    required this.comicSlug,
  });

  HistoryModel copyWith({
    String? slug,
    String? chapterNumber,
    DateTime? readDate,
    ComicDetailsModel? comicDetails,
    String? comicSlug,
  }) {
    return HistoryModel(
      slug: slug ?? this.slug,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      readDate: readDate ?? this.readDate,
      comicDetails: comicDetails ?? this.comicDetails,
      comicSlug: comicSlug ?? this.comicSlug,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'slug': slug,
      'chapterNumber': chapterNumber,
      'readDate': readDate.millisecondsSinceEpoch,
      'comicDetails': comicDetails.toMap(),
      'comicSlug': comicSlug,
    };
  }

  factory HistoryModel.fromMap(Map<String, dynamic> map) {
    return HistoryModel(
      slug: map['slug'] as String,
      chapterNumber: map['chapterNumber'] as String,
      readDate: DateTime.fromMillisecondsSinceEpoch(map['readDate'] as int),
      comicDetails: ComicDetailsModel.fromMap(
          map['comicDetails'] as Map<String, dynamic>),
      comicSlug: map['comicSlug'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory HistoryModel.fromJson(String source) =>
      HistoryModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'HistoryModel(slug: $slug, chapterNumber: $chapterNumber, readDate: $readDate, comicDetails: $comicDetails, comicSlug: $comicSlug)';
  }

  @override
  bool operator ==(covariant HistoryModel other) {
    if (identical(this, other)) return true;

    return other.slug == slug &&
        other.chapterNumber == chapterNumber &&
        other.readDate == readDate &&
        other.comicDetails == comicDetails &&
        other.comicSlug == comicSlug;
  }

  @override
  int get hashCode {
    return slug.hashCode ^
        chapterNumber.hashCode ^
        readDate.hashCode ^
        comicDetails.hashCode ^
        comicSlug.hashCode;
  }
}
