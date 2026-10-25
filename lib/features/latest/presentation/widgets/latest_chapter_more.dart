import 'package:bacakomik_app/core/presentation/bloc/comic_list_state.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/home/presentation/widgets/latest_chapter_card.dart';
import 'package:bacakomik_app/features/latest/presentation/bloc/latest_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bacakomik_app/features/source/presentation/widgets/source_error.dart';
import 'package:bacakomik_app/features/source/presentation/bloc/sources_cubit.dart';

/// Paginated latest chapters, in the same list group rows as the home tab.
class LatestChapterMore extends StatefulWidget {
  const LatestChapterMore({super.key});

  @override
  State<LatestChapterMore> createState() => _LatestChapterMoreState();
}

class _LatestChapterMoreState extends State<LatestChapterMore> {
  static const _maxPage = 10;

  var _page = 1;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<LatestBloc>().add(LatestRequested());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    final state = context.read<LatestBloc>().state;
    final loadingMore = state is ComicListLoaded && state.isLoadMore;
    if (position.pixels >= position.maxScrollExtent - 200 &&
        !loadingMore &&
        _page < _maxPage) {
      _page++;
      context.read<LatestBloc>().add(LatestNextPageRequested(page: _page));
    }
  }

  Future<void> _refresh() async {
    _page = 1;
    context.read<LatestBloc>().add(LatestRequested());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return BlocBuilder<LatestBloc, ComicListState>(
      builder: (context, state) {
        return switch (state) {
          ComicListLoaded(:final comics, :final isLoadMore) => RefreshIndicator(
            color: Dotline.of(context).ink,
            backgroundColor: Dotline.of(context).surface,
            onRefresh: _refresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverPadding(padding: EdgeInsets.only(top: DotSpace.s2)),
                SliverListGroup(
                  itemCount: comics.length,
                  itemBuilder: (context, index) {
                    final comic = comics[index];
                    return LatestChapterCard(
                      title: comic.title,
                      cover: comic.coverImg,
                      chapter: comic.latestChapter,
                      type: comic.type,
                      isCompleted: comic.completed,
                      slug: comic.slug,
                    );
                  },
                ),
                SliverToBoxAdapter(
                  child: isLoadMore
                      ? const Padding(
                          padding: EdgeInsets.all(DotSpace.s5),
                          child: Center(child: DotLoader()),
                        )
                      : const SizedBox.shrink(),
                ),
                SliverPadding(
                  padding: EdgeInsets.only(bottom: DotSpace.s4 + bottomInset),
                ),
              ],
            ),
          ),
          ComicListNoInternet() => EmptyState.offline(onAction: _refresh),
          ComicListError(:final message) => SourceError(
            message: message,
            sourceId: context.read<SourcesCubit>().state.activeId,
            onRetry: _refresh,
          ),
          ComicListInitial() ||
          ComicListLoading() => const Center(child: DotLoader()),
        };
      },
    );
  }
}
