import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bacakomik_app/core/bloc/latest_more_bloc/latest_more_bloc.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/presentation/screens/main/home/widgets/latest_chapter_card.dart';

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
    context.read<LatestMoreBloc>().add(GetMoreLatest());
  }

  Future _refreshData(LatestMoreState state) async {
    context.read<LatestMoreBloc>().add(GetMoreLatest());
  }

  @override
  Widget build(BuildContext context) {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          page < maxPage) {
        page++;
        context.read<LatestMoreBloc>().add(GetMoreLatestNext(page: page));
      }
    });

    return BlocBuilder<LatestMoreBloc, LatestMoreState>(
      builder: (context, state) {
        if (state is LatestMoreInitial || state is LatestMoreLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        if (state is LatestMoreLoaded) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              _refreshData(state);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _scrollController,
              padding: const EdgeInsets.all(
                10,
              ),
              itemBuilder: (context, index) {
                return LatestChapterCard(
                  title: state.latest[index].title,
                  cover: state.latest[index].coverImg,
                  chapter: state.latest[index].latestChapter,
                  type: state.latest[index].type,
                  isCompleted: state.latest[index].completed,
                  slug: state.latest[index].slug,
                  isFromLatestScreen: true,
                );
              },
              itemCount: state.latest.length,
            ),
          );
        }

        if (state is LatestMoreError) {
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
            child: Text('Something went wrong'),
          ),
        );
      },
    );
  }
}
