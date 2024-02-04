import 'package:bacakomik_app/core/models/comic_details_model/comic_details_model.dart';
import 'package:bacakomik_app/core/models/favorite_model.dart';
import 'package:bacakomik_app/data/data_provider/comic_details_data_provider.dart';
import 'package:bacakomik_app/data/repository/comic_details_repository.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class FavoriteCubit extends HydratedCubit<List<FavoriteModel>> {
  FavoriteCubit() : super([]);

  void addFavorite(ComicDetailsModel comic, String slug) {
    emit([
      FavoriteModel(
        slug: slug,
        comicDetails: comic,
        updatedDate: DateTime.now(),
      ),
      ...state
    ]);
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

  Future updateFavoriteList() async {
    final comicDetailsDataProvider = ComicDetailsDataProvider();
    final comicDetailsRepository =
        ComicDetailsRepository(comicDetailsDataProvider);
    final slugs = state.map((e) => e.slug).toList();
    final newState = state;

    try {
      for (var i = 0; i < slugs.length; i++) {
        final slug = slugs[i];
        final oldComicDetails = newState[i].comicDetails;
        final comicDetails = await comicDetailsRepository.getComicDetails(slug);
        if (oldComicDetails != comicDetails) {
          newState[i] = newState[i].copyWith(
            updatedDate: DateTime.now(),
            comicDetails: comicDetails,
          );
        }
      }
      emit([...newState]);
    } catch (e) {
      debugPrint(e.toString());
    }
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
    List<FavoriteModel> sortList() {
      final sortedList = state
          .where((element) =>
              element.comicDetails.title.toLowerCase().contains(keyword))
          .toList();
      sortedList.sort((a, b) => a.updatedDate.compareTo(b.updatedDate));
      return sortedList.reversed.toList();
    }

    return sortList();
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
