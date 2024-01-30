import 'dart:convert';

import 'package:bacakomik_app/core/models/comic_details_model/comic_details_model.dart';

class FavoriteModel {
  final String slug;
  final ComicDetailsModel comicDetails;

  FavoriteModel({
    required this.slug,
    required this.comicDetails,
  });

  FavoriteModel copyWith({
    String? slug,
    ComicDetailsModel? comicDetails,
  }) {
    return FavoriteModel(
      slug: slug ?? this.slug,
      comicDetails: comicDetails ?? this.comicDetails,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'slug': slug,
      'comicDetails': comicDetails.toMap(),
    };
  }

  factory FavoriteModel.fromMap(Map<String, dynamic> map) {
    return FavoriteModel(
      slug: map['slug'] as String,
      comicDetails: ComicDetailsModel.fromMap(
          map['comicDetails'] as Map<String, dynamic>),
    );
  }

  String toJson() => json.encode(toMap());

  factory FavoriteModel.fromJson(String source) =>
      FavoriteModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'FavoriteModel(slug: $slug, comicDetails: $comicDetails)';

  @override
  bool operator ==(covariant FavoriteModel other) {
    if (identical(this, other)) return true;

    return other.slug == slug && other.comicDetails == comicDetails;
  }

  @override
  int get hashCode => slug.hashCode ^ comicDetails.hashCode;
}
