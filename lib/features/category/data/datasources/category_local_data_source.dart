import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/storage/json_box.dart';
import 'package:bacakomik_app/features/category/data/models/category_model.dart';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

abstract interface class CategoryLocalDataSource {
  List<CategoryModel> getCategories();

  Future<void> putCategories(List<CategoryModel> categories);

  Future<void> deleteCategories(List<String> ids);

  List<ComicCategoriesModel> getComicCategories();

  Future<void> putComicCategories(List<ComicCategoriesModel> entries);

  Future<void> deleteComicCategories(List<String> slugs);
}

@LazySingleton(as: CategoryLocalDataSource)
class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  CategoryLocalDataSourceImpl(
    @Named(HiveBoxes.categories) Box<String> categories,
    @Named(HiveBoxes.comicCategories) Box<String> comicCategories,
  ) : _categories = JsonBox(
        categories,
        fromJson: CategoryModel.fromJson,
        toJson: (c) => c.toJson(),
        keyOf: (c) => c.id,
      ),
      _comicCategories = JsonBox(
        comicCategories,
        fromJson: ComicCategoriesModel.fromJson,
        toJson: (c) => c.toJson(),
        keyOf: (c) => c.slug,
      );

  final JsonBox<CategoryModel> _categories;
  final JsonBox<ComicCategoriesModel> _comicCategories;

  @override
  List<CategoryModel> getCategories() => _categories.values();

  @override
  Future<void> putCategories(List<CategoryModel> categories) =>
      _categories.putAll(categories);

  @override
  Future<void> deleteCategories(List<String> ids) => _categories.deleteAll(ids);

  @override
  List<ComicCategoriesModel> getComicCategories() => _comicCategories.values();

  @override
  Future<void> putComicCategories(List<ComicCategoriesModel> entries) =>
      _comicCategories.putAll(entries);

  @override
  Future<void> deleteComicCategories(List<String> slugs) =>
      _comicCategories.deleteAll(slugs);
}
