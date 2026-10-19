import 'package:auto_height_grid_view/auto_height_grid_view.dart';
import 'package:bacakomik_app/features/explore/presentation/bloc/explore_bloc.dart';
import 'package:bacakomik_app/core/presentation/bloc/comic_list_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/comic_card.dart';
import 'package:solar_icons/solar_icons.dart';

class FilterResult extends StatefulWidget {
  const FilterResult({
    super.key,
    required this.onLoadMore,
    required this.onRefresh,
  });

  final Function(int page) onLoadMore;
  final Function() onRefresh;

  @override
  State<FilterResult> createState() => _FilterResultState();
}

class _FilterResultState extends State<FilterResult> {
  int _page = 1;
  final int _maxPage = 10;
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
          _page < _maxPage) {
        _page++;
        widget.onLoadMore(_page);
      }
    });

    return BlocBuilder<ExploreBloc, ComicListState>(
      builder: (context, state) {
        if (state is ComicListInitial || state is ComicListLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is ComicListLoaded) {
          if (state.comics.isNotEmpty) {
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
                    itemCount: state.comics.length,
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 640 ? 4 : 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    shrinkWrap: true,
                    builder: (context, index) {
                      return ComicCard(
                        title: state.comics[index].title,
                        cover: state.comics[index].coverImg,
                        chapter: state.comics[index].latestChapter,
                        type: state.comics[index].type,
                        rating: state.comics[index].rating,
                        completed: state.comics[index].completed,
                        slug: state.comics[index].slug,
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
                    color: AppColors.primary.withValues(alpha: 0.5),
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
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            );
          }
        }

        if (state is ComicListError) {
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
