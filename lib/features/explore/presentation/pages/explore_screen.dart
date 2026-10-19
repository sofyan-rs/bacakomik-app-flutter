import 'package:bacakomik_app/core/constants/filters.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/bloc/comic_list_state.dart';
import 'package:bacakomik_app/core/presentation/widgets/comic_grid.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/explore/domain/entities/explore_filter.dart';
import 'package:bacakomik_app/features/explore/presentation/bloc/explore_bloc.dart';
import 'package:bacakomik_app/features/explore/presentation/bloc/filter_cubit.dart';
import 'package:bacakomik_app/features/explore/presentation/widgets/filter_comic.dart';
import 'package:bacakomik_app/features/search/presentation/pages/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _scrollController = ScrollController();
  late final _nextPage = NextPageTrigger(
    controller: _scrollController,
    isLoading: () {
      final state = context.read<ExploreBloc>().state;
      return state is! ComicListLoaded || state.isLoadMore;
    },
    onNextPage: (page) => context.read<ExploreBloc>().add(
      ExploreNextPageRequested(
        filter: context.read<FilterCubit>().state,
        page: page,
      ),
    ),
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _nextPage.reset();
    context.read<ExploreBloc>().add(
      ExploreRequested(filter: context.read<FilterCubit>().state),
    );
  }

  void _setType(String type) {
    final filter = context.read<FilterCubit>().state;
    if (filter.type == type) return;
    context.read<FilterCubit>().setFilter(
      type: type,
      status: filter.status,
      sortBy: filter.sortBy,
      genres: filter.genres,
    );
    _load();
  }

  void _openSearch() =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const SearchScreen()));

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<FilterCubit>().state;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<ExploreBloc, ComicListState>(
          builder: (context, state) {
            return RefreshIndicator(
              color: Dotline.of(context).ink,
              backgroundColor: Dotline.of(context).surface,
              onRefresh: _load,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(
                    child: ScreenHeader(title: AppText.explore),
                  ),
                  SliverToBoxAdapter(child: _controls(filter)),
                  ..._results(state),
                  SliverPadding(padding: EdgeInsets.only(bottom: bottomInset)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _controls(ExploreFilter filter) {
    final c = Dotline.of(context);
    final count = activeFilterCount(filter);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DotSpace.s4,
        0,
        DotSpace.s4,
        DotSpace.s4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchField(hint: AppText.exploreSearchHint, onTap: _openSearch),
          const SizedBox(height: DotSpace.s4),
          SegmentedControl<String>(
            selected: filter.type,
            onChanged: _setType,
            segments: [
              for (final type in Filters.typeList)
                Segment(value: type.id, label: type.name),
            ],
          ),
          const SizedBox(height: DotSpace.s4),
          Row(
            children: [
              Expanded(
                child: Text(
                  filterSummary(filter),
                  style: DotlineText.label.copyWith(color: c.inkFaint),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: DotSpace.s3),
              Pressable(
                semanticLabel: AppText.filter,
                onTap: () => showFilterSheet(context, onApply: _load),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: DotSpace.s4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DotRadius.pill),
                    border: Border.all(
                      color: c.lineStrong,
                      width: DotSize.stroke,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons300.slidersHorizontal,
                        size: DotSize.iconSmall,
                        color: c.ink,
                      ),
                      const SizedBox(width: DotSpace.s2),
                      Text(
                        AppText.filter.toUpperCase(),
                        style: DotlineText.label.copyWith(color: c.ink),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: DotSpace.s2),
                        CountBadge(count: count),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _results(ComicListState state) => switch (state) {
    ComicListLoaded(:final comics) when comics.isEmpty => [
      const SliverToBoxAdapter(
        child: EmptyState(
          icon: LucideIcons300.searchX,
          title: AppText.comicNotFound,
          message: AppText.comicNotFoundFilter,
        ),
      ),
    ],
    ComicListLoaded(:final comics, :final isLoadMore) => [
      ComicGridSliver(comics: comics),
      LoadMoreSliver(visible: isLoadMore),
    ],
    ComicListNoInternet() => [
      SliverToBoxAdapter(child: EmptyState.offline(onAction: _load)),
    ],
    ComicListError(:final message) => [
      SliverToBoxAdapter(
        child: EmptyState(
          icon: LucideIcons300.bug,
          title: AppText.error,
          message: message,
          actionLabel: AppText.retry,
          onAction: _load,
        ),
      ),
    ],
    ComicListInitial() || ComicListLoading() => [
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(DotSpace.s7),
          child: Center(child: DotLoader()),
        ),
      ),
    ],
  };
}
