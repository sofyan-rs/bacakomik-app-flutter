part of 'comic_details_model.dart';

class ChapterModel {
  final String number;
  final String slug;
  final String date;
  ChapterModel({
    required this.number,
    required this.slug,
    required this.date,
  });

  ChapterModel copyWith({
    String? number,
    String? slug,
    String? date,
  }) {
    return ChapterModel(
      number: number ?? this.number,
      slug: slug ?? this.slug,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'number': number,
      'slug': slug,
      'date': date,
    };
  }

  factory ChapterModel.fromMap(Map<String, dynamic> map) {
    return ChapterModel(
      number: map['number'] as String,
      slug: map['slug'] as String,
      date: map['date'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChapterModel.fromJson(String source) =>
      ChapterModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'ChapterModel(number: $number, slug: $slug, date: $date)';

  @override
  bool operator ==(covariant ChapterModel other) {
    if (identical(this, other)) return true;

    return other.number == number && other.slug == slug && other.date == date;
  }

  @override
  int get hashCode => number.hashCode ^ slug.hashCode ^ date.hashCode;
}
