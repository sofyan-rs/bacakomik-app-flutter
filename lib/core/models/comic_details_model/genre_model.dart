part of 'comic_details_model.dart';

class GenreModel {
  final String name;
  final String slug;
  GenreModel({
    required this.name,
    required this.slug,
  });

  GenreModel copyWith({
    String? name,
    String? slug,
  }) {
    return GenreModel(
      name: name ?? this.name,
      slug: slug ?? this.slug,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'slug': slug,
    };
  }

  factory GenreModel.fromMap(Map<String, dynamic> map) {
    return GenreModel(
      name: map['name'] as String,
      slug: map['slug'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory GenreModel.fromJson(String source) =>
      GenreModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'GenreModel(name: $name, slug: $slug)';

  @override
  bool operator ==(covariant GenreModel other) {
    if (identical(this, other)) return true;

    return other.name == name && other.slug == slug;
  }

  @override
  int get hashCode => name.hashCode ^ slug.hashCode;
}
