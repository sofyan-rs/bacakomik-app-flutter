import 'package:bacakomik_app/core/models/comic_details_model/comic_details_model.dart';
import 'package:bacakomik_app/core/models/favorite_model.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class FavoriteCubit extends HydratedCubit<List<FavoriteModel>> {
  FavoriteCubit() : super([]);

  void addFavorite(ComicDetailsModel comic, String slug) {
    emit([FavoriteModel(slug: slug, comicDetails: comic), ...state]);
  }

  void removeFavorite(String slug) {
    final newState = state;
    newState.removeWhere((element) => element.slug == slug);
    emit([...newState]);
  }

  void removeFavoriteList(List<String> slugs) {
    final newState = state;
    newState.removeWhere((element) => slugs.contains(element.slug));
    emit([...newState]);
  }

  void clearFavorite() {
    emit([]);
  }

  void setFavorite(List<FavoriteModel> comics) {
    emit([...comics]);
  }

  bool isFavorite(String slug) {
    return state.any((element) => element.slug == slug);
  }

  List<FavoriteModel> searchFavorite(String keyword) {
    return state
        .where((element) =>
            element.comicDetails.title.toLowerCase().contains(keyword))
        .toList();
  }

  @override
  List<FavoriteModel>? fromJson(Map<String, dynamic> json) {
    if (json['favorites_comic'] != null) {
      return List<FavoriteModel>.from(
          json['favorites_comic'].map((x) => FavoriteModel.fromJson(x)));
    }
    return null;
  }

  @override
  Map<String, dynamic>? toJson(List<FavoriteModel> state) {
    return {
      'favorites_comic': state.map((e) => e.toJson()).toList(),
    };
  }
}
