import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/placeholder/err_no_internet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bacakomik_app/features/latest/presentation/bloc/latest_bloc.dart';
import 'package:bacakomik_app/core/presentation/bloc/comic_list_state.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/features/home/presentation/widgets/latest_chapter_card.dart';

class LatestChapterMore extends StatefulWidget {
  const LatestChapterMore({super.key});

  @override
  State<LatestChapterMore> createState() => _LatestChapterMoreState();
}

class _LatestChapterMoreState extends State<LatestChapterMore> {
  var page = 1;
  final maxPage = 10;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<LatestBloc>().add(LatestRequested());
  }

  Future _refreshData() async {
    context.read<LatestBloc>().add(LatestRequested());
  }

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
        context.read<LatestBloc>().add(LatestNextPageRequested(page: page));
      }
    });

    return BlocBuilder<LatestBloc, ComicListState>(
      builder: (context, state) {
        if (state is ComicListInitial || state is ComicListLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is ComicListLoaded) {
          return Stack(
            children: [
              RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  _refreshData();
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: _scrollController,
                  padding: const EdgeInsets.all(
                    10,
                  ),
                  itemBuilder: (context, index) {
                    return LatestChapterCard(
                      title: state.comics[index].title,
                      cover: state.comics[index].coverImg,
                      chapter: state.comics[index].latestChapter,
                      type: state.comics[index].type,
                      isCompleted: state.comics[index].completed,
                      slug: state.comics[index].slug,
                    );
                  },
                  itemCount: state.comics.length,
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
        }

        if (state is ComicListError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(state.message),
            ),
          );
        }

        if (state is ComicListNoInternet) {
          return const ErrNoInternet();
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
