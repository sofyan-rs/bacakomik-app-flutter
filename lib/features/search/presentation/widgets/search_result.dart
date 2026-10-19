import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/bloc/comic_list_state.dart';
import 'package:bacakomik_app/core/presentation/widgets/comic_grid.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/features/search/presentation/bloc/search_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Search results in the Jelajah cover grid, with next-page loading.
class SearchResult extends StatefulWidget {
  const SearchResult({
    super.key,
    required this.keyword,
    required this.onRefresh,
  });

  /// Current keyword, read when the next page is requested.
  final String Function() keyword;
  final VoidCallback onRefresh;

  @override
  State<SearchResult> createState() => SearchResultState();
}

class SearchResultState extends State<SearchResult> {
  final _scrollController = ScrollController();
  late final _nextPage = NextPageTrigger(
    controller: _scrollController,
    isLoading: () {
      final state = context.read<SearchBloc>().state;
      return state is! ComicListLoaded || state.isLoadMore;
    },
    onNextPage: (page) => context.read<SearchBloc>().add(
      SearchNextPageRequested(keyword: widget.keyword(), page: page),
    ),
  );

  void resetPaging() => _nextPage.reset();

  @override
  void initState() {
    super.initState();
    // Creating the trigger attaches its scroll listener.
    _nextPage;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return BlocBuilder<SearchBloc, ComicListState>(
      builder: (context, state) {
        return switch (state) {
          ComicListInitial() => const EmptyState(
            icon: LucideIcons300.search,
            title: AppText.searchComicHere,
            message: AppText.searchStart,
          ),
          ComicListLoading() => const Center(child: DotLoader()),
          ComicListLoaded(:final comics) when comics.isEmpty =>
            const EmptyState(
              icon: LucideIcons300.searchX,
              title: AppText.comicNotFound,
              message: AppText.comicNotFoundSearch,
            ),
          ComicListLoaded(:final comics, :final isLoadMore) => RefreshIndicator(
            color: Dotline.of(context).ink,
            backgroundColor: Dotline.of(context).surface,
            onRefresh: () async => widget.onRefresh(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                ComicGridSliver(comics: comics),
                LoadMoreSliver(visible: isLoadMore),
                SliverPadding(padding: EdgeInsets.only(bottom: bottomInset)),
              ],
            ),
          ),
          ComicListNoInternet() => EmptyState.offline(
            onAction: widget.onRefresh,
          ),
          ComicListError(:final message) => EmptyState(
            icon: LucideIcons300.bug,
            title: AppText.error,
            message: message,
            actionLabel: AppText.retry,
            onAction: widget.onRefresh,
          ),
        };
      },
    );
  }
}
