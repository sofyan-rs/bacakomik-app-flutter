import 'package:bacakomik_app/features/category/domain/entities/category.dart';
import 'package:json_annotation/json_annotation.dart';

part 'category_model.g.dart';

/// Stored category, also used in backup and sync files.
@JsonSerializable()
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.order,
    required this.updatedDate,
  });

  factory CategoryModel.fromEntity(LibraryCategory e) => CategoryModel(
    id: e.id,
    name: e.name,
    order: e.order,
    updatedDate: e.updatedDate,
  );

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);

  final String id;
  final String name;
  final int order;
  final DateTime updatedDate;

  Map<String, dynamic> toJson() => _$CategoryModelToJson(this);

  LibraryCategory toEntity() => LibraryCategory(
    id: id,
    name: name,
    order: order,
    updatedDate: updatedDate,
  );
}

/// Stored categories of one comic, also used in backup and sync files.
@JsonSerializable()
class ComicCategoriesModel {
  const ComicCategoriesModel({
    required this.slug,
    required this.categoryIds,
    required this.updatedDate,
  });

  factory ComicCategoriesModel.fromEntity(ComicCategories e) =>
      ComicCategoriesModel(
        slug: e.slug,
        categoryIds: e.categoryIds,
        updatedDate: e.updatedDate,
      );

  factory ComicCategoriesModel.fromJson(Map<String, dynamic> json) =>
      _$ComicCategoriesModelFromJson(json);

  final String slug;
  final List<String> categoryIds;
  final DateTime updatedDate;

  Map<String, dynamic> toJson() => _$ComicCategoriesModelToJson(this);

  ComicCategories toEntity() => ComicCategories(
    slug: slug,
    categoryIds: categoryIds,
    updatedDate: updatedDate,
  );
}
