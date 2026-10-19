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
      ...state
    ]);
  }

  void removeBookmark(String slug) {
    final newState = state;
    newState.removeWhere((element) => element.slug == slug);
    emit([...newState]);
  }

  void removeBookmarkList(List<String> slugs) {
    final newState = state;
    newState.removeWhere((element) => slugs.contains(element.slug));
    emit([...newState]);
  }

  Future updateBookmarkList() async {
    final comicDetailsRepository =
        ComicDetailsRepository(BacaKomikDataProvider());
    final newState = [...state];

    for (var i = 0; i < newState.length; i++) {
      try {
        final comicDetails =
            await comicDetailsRepository.getComicDetails(newState[i].slug);
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
    final newState = state;
    for (var i = 0; i < comics.length; i++) {
      final isExist =
          state.indexWhere((element) => comics[i].slug == element.slug);
      if (isExist != -1) {
        newState.removeAt(isExist);
      }
      newState.add(comics[i]);
    }
    emit([...newState]);
  }

  bool isBookmark(String slug) {
    return state.any((element) => element.slug == slug);
  }

  List<BookmarkModel> searchBookmark(String keyword) {
    List<BookmarkModel> sortList() {
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
  List<BookmarkModel>? fromJson(Map<String, dynamic> json) {
    if (json['bookmarks_comic'] != null) {
      return List<BookmarkModel>.from(
          json['bookmarks_comic'].map((x) => BookmarkModel.fromJson(x)));
    }
    return null;
  }

  @override
  Map<String, dynamic>? toJson(List<BookmarkModel> state) {
    return {
      'bookmarks_comic': state.map((e) => e.toJson()).toList(),
    };
  }
}
