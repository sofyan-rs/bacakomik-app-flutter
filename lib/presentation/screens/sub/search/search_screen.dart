import 'package:bacakomik_app/core/bloc/search_comic_bloc/search_comic_bloc.dart';
import 'package:bacakomik_app/presentation/screens/sub/search/widgets/search_result.dart';
import 'package:flutter/material.dart';

import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchInputController = TextEditingController();

  Future _getSearchData(int page) async {
    final String keyword = _searchInputController.text;
    context.read<SearchComicBloc>().add(
          GetSearchResult(
            keyword: keyword,
            page: page,
          ),
        );
  }

  Future _getSearchDataNext(int page) async {
    final String keyword = _searchInputController.text;
    context.read<SearchComicBloc>().add(
          GetSearchResultNext(
            keyword: keyword,
            page: page,
          ),
        );
  }

  @override
  void dispose() {
    _searchInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 75,
        title: TextField(
          controller: _searchInputController,
          cursorColor: AppColors.primary,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 15),
            hintText: 'Search',
            hintStyle: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onBackground
                    .withOpacity(0.9)),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(
                Radius.circular(7),
              ),
              borderSide: BorderSide(
                color:
                    Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(7),
              ),
              borderSide: BorderSide(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(
            SolarIconsOutline.arrowLeft,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () {
                _getSearchData(1);
              },
              icon: const Icon(
                SolarIconsOutline.magnifier,
                color: Colors.white,
                size: 23,
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
      body: SearchResult(
        onLoadMore: (page) {
          _getSearchDataNext(page);
        },
        onRefresh: () {
          _getSearchData(1);
        },
      ),
    );
  }
}
