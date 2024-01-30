import 'package:auto_height_grid_view/auto_height_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bacakomik_app/core/bloc/search_comic_bloc/search_comic_bloc.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/presentation/screens/sub/search/widgets/comic_card.dart';
import 'package:solar_icons/solar_icons.dart';

class SearchResult extends StatefulWidget {
  const SearchResult({
    Key? key,
    required this.onLoadMore,
    required this.onRefresh,
  }) : super(key: key);

  final Function(int page) onLoadMore;
  final Function() onRefresh;

  @override
  State<SearchResult> createState() => _SearchResultState();
}

class _SearchResultState extends State<SearchResult> {
  var page = 1;
  final maxPage = 10;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          page < maxPage) {
        page++;
        widget.onLoadMore(page);
      }
    });

    return BlocBuilder<SearchComicBloc, SearchComicState>(
      builder: (context, state) {
        if (state is SearchComicInitial) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  SolarIconsOutline.magnifier,
                  color: AppColors.primary.withOpacity(0.5),
                  size: 80,
                ),
                const SizedBox(height: 20),
                Text(
                  AppText.searchComicHere,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .colorScheme
                        .onBackground
                        .withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }

        if (state is SearchComicLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is SearchComicLoaded) {
          if (state.result.isNotEmpty) {
            return Stack(
              children: [
                RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    widget.onRefresh();
                  },
                  child: AutoHeightGridView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(15),
                    itemCount: state.result.length,
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 640 ? 4 : 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    shrinkWrap: true,
                    builder: (context, index) {
                      return ComicCard(
                        title: state.result[index].title,
                        cover: state.result[index].coverImg,
                        chapter: state.result[index].latestChapter,
                        type: state.result[index].type,
                        rating: state.result[index].rating,
                        completed: state.result[index].completed,
                        slug: state.result[index].slug,
                      );
                    },
                  ),
                ),
                if (state.isLoadMore)
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: LinearProgressIndicator(
                      minHeight: 5,
                    ),
                  )
              ],
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    SolarIconsOutline.magnifier,
                    color: AppColors.primary.withOpacity(0.5),
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppText.comicNotFound,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          }
        }

        if (state is SearchComicError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(state.message),
            ),
          );
        }

        return const Center(
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Text(AppText.error),
          ),
        );
      },
    );
  }
}
