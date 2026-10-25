// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryModel _$CategoryModelFromJson(Map<String, dynamic> json) =>
    CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      order: (json['order'] as num).toInt(),
      updatedDate: DateTime.parse(json['updatedDate'] as String),
    );

Map<String, dynamic> _$CategoryModelToJson(CategoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'order': instance.order,
      'updatedDate': instance.updatedDate.toIso8601String(),
    };

ComicCategoriesModel _$ComicCategoriesModelFromJson(
  Map<String, dynamic> json,
) => ComicCategoriesModel(
  slug: json['slug'] as String,
  categoryIds: (json['categoryIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  updatedDate: DateTime.parse(json['updatedDate'] as String),
);

Map<String, dynamic> _$ComicCategoriesModelToJson(
  ComicCategoriesModel instance,
) => <String, dynamic>{
  'slug': instance.slug,
  'categoryIds': instance.categoryIds,
  'updatedDate': instance.updatedDate.toIso8601String(),
};
