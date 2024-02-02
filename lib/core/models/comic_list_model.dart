// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ComicListModel {
  final String title;
  final String slug;
  final String group;
  ComicListModel({
    required this.title,
    required this.slug,
    required this.group,
  });

  ComicListModel copyWith({
    String? title,
    String? slug,
    String? group,
  }) {
    return ComicListModel(
      title: title ?? this.title,
      slug: slug ?? this.slug,
      group: group ?? this.group,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'slug': slug,
      'group': group,
    };
  }

  factory ComicListModel.fromMap(Map<String, dynamic> map) {
    return ComicListModel(
      title: map['title'] as String,
      slug: map['slug'] as String,
      group: map['group'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory ComicListModel.fromJson(String source) =>
      ComicListModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'ComicListModel(title: $title, slug: $slug, group: $group)';

  @override
  bool operator ==(covariant ComicListModel other) {
    if (identical(this, other)) return true;

    return other.title == title && other.slug == slug && other.group == group;
  }

  @override
  int get hashCode => title.hashCode ^ slug.hashCode ^ group.hashCode;
}
