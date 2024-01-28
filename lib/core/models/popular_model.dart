import 'dart:convert';

class PopularModel {
  final String title;
  final String coverImg;
  final String type;
  final String latestChapter;
  final String slug;
  final String rating;
  PopularModel({
    required this.title,
    required this.coverImg,
    required this.type,
    required this.latestChapter,
    required this.slug,
    required this.rating,
  });

  PopularModel copyWith({
    String? title,
    String? coverImg,
    String? type,
    String? latestChapter,
    String? slug,
    String? rating,
  }) {
    return PopularModel(
      title: title ?? this.title,
      coverImg: coverImg ?? this.coverImg,
      type: type ?? this.type,
      latestChapter: latestChapter ?? this.latestChapter,
      slug: slug ?? this.slug,
      rating: rating ?? this.rating,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'coverImg': coverImg,
      'type': type,
      'latestChapter': latestChapter,
      'slug': slug,
      'rating': rating,
    };
  }

  factory PopularModel.fromMap(Map<String, dynamic> map) {
    return PopularModel(
      title: map['title'] as String,
      coverImg: map['coverImg'] as String,
      type: map['type'] as String,
      latestChapter: map['latestChapter'] as String,
      slug: map['slug'] as String,
      rating: map['rating'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory PopularModel.fromJson(String source) =>
      PopularModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PopularModel(title: $title, coverImg: $coverImg, type: $type, latestChapter: $latestChapter, slug: $slug, rating: $rating)';
  }

  @override
  bool operator ==(covariant PopularModel other) {
    if (identical(this, other)) return true;

    return other.title == title &&
        other.coverImg == coverImg &&
        other.type == type &&
        other.latestChapter == latestChapter &&
        other.slug == slug &&
        other.rating == rating;
  }

  @override
  int get hashCode {
    return title.hashCode ^
        coverImg.hashCode ^
        type.hashCode ^
        latestChapter.hashCode ^
        slug.hashCode ^
        rating.hashCode;
  }
}
