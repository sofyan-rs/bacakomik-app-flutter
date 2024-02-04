// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:bacakomik_app/core/models/comic_details_model/comic_details_model.dart';

class FavoriteModel {
  final String slug;
  final ComicDetailsModel comicDetails;
  final DateTime updatedDate;

  FavoriteModel({
    required this.slug,
    required this.comicDetails,
    required this.updatedDate,
  });

  FavoriteModel copyWith({
    String? slug,
    ComicDetailsModel? comicDetails,
    DateTime? updatedDate,
  }) {
    return FavoriteModel(
      slug: slug ?? this.slug,
      comicDetails: comicDetails ?? this.comicDetails,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'slug': slug,
      'comicDetails': comicDetails.toMap(),
      'updatedDate': updatedDate.millisecondsSinceEpoch,
    };
  }

  factory FavoriteModel.fromMap(Map<String, dynamic> map) {
    return FavoriteModel(
      slug: map['slug'] as String,
      comicDetails: ComicDetailsModel.fromMap(
          map['comicDetails'] as Map<String, dynamic>),
      updatedDate:
          DateTime.fromMillisecondsSinceEpoch(map['updatedDate'] as int),
    );
  }

  String toJson() => json.encode(toMap());

  factory FavoriteModel.fromJson(String source) =>
      FavoriteModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'FavoriteModel(slug: $slug, comicDetails: $comicDetails, updatedDate: $updatedDate)';

  @override
  bool operator ==(covariant FavoriteModel other) {
    if (identical(this, other)) return true;

    return other.slug == slug &&
        other.comicDetails == comicDetails &&
        other.updatedDate == updatedDate;
  }

  @override
  int get hashCode =>
      slug.hashCode ^ comicDetails.hashCode ^ updatedDate.hashCode;
}
