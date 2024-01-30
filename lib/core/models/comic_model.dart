import 'dart:convert';

class ComicModel {
  final String title;
  final String coverImg;
  final String slug;
  final String type;
  final bool completed;
  final String rating;
  final String latestChapter;
  ComicModel({
    required this.title,
    required this.coverImg,
    required this.slug,
    required this.type,
    required this.completed,
    required this.rating,
    required this.latestChapter,
  });

  ComicModel copyWith({
    String? title,
    String? coverImg,
    String? slug,
    String? type,
    bool? completed,
    String? rating,
    String? latestChapter,
  }) {
    return ComicModel(
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

  factory ComicModel.fromMap(Map<String, dynamic> map) {
    return ComicModel(
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

  factory ComicModel.fromJson(String source) =>
      ComicModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ComicModel(title: $title, coverImg: $coverImg, slug: $slug, type: $type, completed: $completed, rating: $rating, latestChapter: $latestChapter)';
  }

  @override
  bool operator ==(covariant ComicModel other) {
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
