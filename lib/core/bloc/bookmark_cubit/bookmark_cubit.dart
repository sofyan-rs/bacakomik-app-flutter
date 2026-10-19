import 'package:bacakomik_app/core/models/comic_details_model/comic_details_model.dart';
import 'package:bacakomik_app/core/models/bookmark_model.dart';
import 'package:bacakomik_app/data/data_provider/bacakomik_data_provider.dart';
import 'package:bacakomik_app/data/repository/comic_details_repository.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class BookmarkCubit extends HydratedCubit<List<BookmarkModel>> {
  BookmarkCubit() : super([]);

  // Keep the pre-rename storage key so previously saved bookmarks still load.
  @override
  String get storagePrefix => 'FavoriteCubit';

  void addBookmark(ComicDetailsModel comic, String slug) {
    emit([
      BookmarkModel(
        slug: slug,
        comicDetails: comic,
        updatedDate: DateTime.now(),
      ),
      ...state,
    ]);
  }

  void removeBookmark(String slug) {
    emit(state.where((element) => element.slug != slug).toList());
  }

  void removeBookmarkList(List<String> slugs) {
    emit(state.where((element) => !slugs.contains(element.slug)).toList());
  }

  Future updateBookmarkList() async {
    final comicDetailsRepository = ComicDetailsRepository(
      BacaKomikDataProvider(),
    );
    final newState = [...state];

    for (var i = 0; i < newState.length; i++) {
      try {
        final comicDetails = await comicDetailsRepository.getComicDetails(
          newState[i].slug,
        );
        if (newState[i].comicDetails.chapters.length !=
            comicDetails.chapters.length) {
          newState[i] = newState[i].copyWith(
            updatedDate: DateTime.now(),
            comicDetails: comicDetails,
          );
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    emit(newState);
  }

  void clearBookmark() {
    emit([]);
  }

  void setBookmark(List<BookmarkModel> comics) {
    final newState = [...state];
    for (final comic in comics) {
      newState.removeWhere((element) => element.slug == comic.slug);
      newState.add(comic);
    }
    emit(newState);
  }

  bool isBookmark(String slug) {
    return state.any((element) => element.slug == slug);
  }

  List<BookmarkModel> searchBookmark(String keyword) {
    return state
        .where(
          (element) =>
              element.comicDetails.title.toLowerCase().contains(keyword),
        )
        .toList()
      ..sort((a, b) => b.updatedDate.compareTo(a.updatedDate));
  }

  @override
  List<BookmarkModel>? fromJson(Map<String, dynamic> json) {
    if (json['bookmarks_comic'] != null) {
      return List<BookmarkModel>.from(
        json['bookmarks_comic'].map((x) => BookmarkModel.fromJson(x)),
      );
    }
    return null;
  }

  @override
  Map<String, dynamic>? toJson(List<BookmarkModel> state) {
    return {'bookmarks_comic': state.map((e) => e.toJson()).toList()};
  }
}
