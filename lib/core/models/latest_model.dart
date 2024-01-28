import 'dart:convert';

class LatestModel {
  final String title;
  final String coverImg;
  final String slug;
  final String type;
  final bool completed;
  final String rating;
  final String latestChapter;
  LatestModel({
    required this.title,
    required this.coverImg,
    required this.slug,
    required this.type,
    required this.completed,
    required this.rating,
    required this.latestChapter,
  });

  LatestModel copyWith({
    String? title,
    String? coverImg,
    String? slug,
    String? type,
    bool? completed,
    String? rating,
    String? latestChapter,
  }) {
    return LatestModel(
      title: title ?? this.title,
      coverImg: coverImg ?? this.coverImg,
      slug: slug ?? this.slug,
      type: type ?? this.type,
      completed: completed ?? this.completed,
      rating: rating ?? this.rating,
      latestChapter: latestChapter ?? this.latestChapter,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'coverImg': coverImg,
      'slug': slug,
      'type': type,
      'completed': completed,
      'rating': rating,
      'latestChapter': latestChapter,
    };
  }

  factory LatestModel.fromMap(Map<String, dynamic> map) {
    return LatestModel(
      title: map['title'] as String,
      coverImg: map['coverImg'] as String,
      slug: map['slug'] as String,
      type: map['type'] as String,
      completed: map['completed'] as bool,
      rating: map['rating'] as String,
      latestChapter: map['latestChapter'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory LatestModel.fromJson(String source) =>
      LatestModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'LatestModel(title: $title, coverImg: $coverImg, slug: $slug, type: $type, completed: $completed, rating: $rating, latestChapter: $latestChapter)';
  }

  @override
  bool operator ==(covariant LatestModel other) {
    if (identical(this, other)) return true;

    return other.title == title &&
        other.coverImg == coverImg &&
        other.slug == slug &&
        other.type == type &&
        other.completed == completed &&
        other.rating == rating &&
        other.latestChapter == latestChapter;
  }

  @override
  int get hashCode {
    return title.hashCode ^
        coverImg.hashCode ^
        slug.hashCode ^
        type.hashCode ^
        completed.hashCode ^
        rating.hashCode ^
        latestChapter.hashCode;
  }
}
