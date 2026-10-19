import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/features/search/presentation/bloc/search_bloc.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/features/search/presentation/widgets/search_result.dart';
import 'package:flutter/material.dart';

import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SearchBloc>(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _searchInputController = TextEditingController();

  Future _getSearchData(int page) async {
    final String keyword = _searchInputController.text;
    context.read<SearchBloc>().add(
          SearchRequested(
            keyword: keyword,
            page: page,
          ),
        );
  }

  Future _getSearchDataNext(int page) async {
    final String keyword = _searchInputController.text;
    context.read<SearchBloc>().add(
          SearchNextPageRequested(
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
        toolbarHeight: 70,
        title: TextField(
          controller: _searchInputController,
          cursorColor: AppColors.primary,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 15),
            hintText: AppText.searchHint,
            hintStyle: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.9)),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(
                Radius.circular(7),
              ),
              borderSide: BorderSide(
                color:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
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
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () {
                if (_searchInputController.text.isNotEmpty) _getSearchData(1);
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
