import 'dart:async';

import 'package:bacakomik_app/app/root_tabs.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/bloc/comic_list_state.dart';
import 'package:bacakomik_app/core/presentation/widgets/comic_grid.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/explore/domain/entities/explore_filter.dart';
import 'package:bacakomik_app/features/explore/presentation/bloc/explore_bloc.dart';
import 'package:bacakomik_app/features/explore/presentation/bloc/filter_cubit.dart';
import 'package:bacakomik_app/features/explore/presentation/widgets/filter_comic.dart';
import 'package:bacakomik_app/features/source/presentation/bloc/sources_cubit.dart';
import 'package:bacakomik_app/features/source/presentation/widgets/source_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:bacakomik_app/features/source/presentation/pages/web_view_screen.dart';
import 'package:bacakomik_app/features/source/presentation/widgets/source_error.dart';

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

  final _query = TextEditingController();
  final _queryFocus = FocusNode();
  Timer? _debounce;
  RootTabs? _tabs;
  var _searchRequests = 0;
  var _filterRequests = 0;

  /// The search field is shown: by its button, Home's search button, or a
  /// search already set.
  var _searching = false;

  @override
  void initState() {
    super.initState();
    _query.text = context.read<FilterCubit>().state.query;
    _searching = _query.text.isNotEmpty;
    // The header stays while the search is typed in.
    _queryFocus.addListener(_onFocus);
    // Built on the tab's first visit (RootScreen), so this is when Explore
    // first asks its source.
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tabs = RootTabsScope.read(context);
    if (!identical(tabs, _tabs)) {
      final first = _tabs == null;
      _tabs?.removeListener(_onTabs);
      _tabs = tabs..addListener(_onTabs);
      // The tab is built on its first visit, which may be Home's search
      // button: focus the field for it. initState already loaded the
      // filter set elsewhere.
      if (first && tabs.searchRequests != _searchRequests) _focusSearch();
      _searchRequests = tabs.searchRequests;
      _filterRequests = tabs.filterRequests;
    }
  }

  void _onFocus() => setState(() {});

  @override
  void dispose() {
    _queryFocus.removeListener(_onFocus);
    _tabs?.removeListener(_onTabs);
    _debounce?.cancel();
    _query.dispose();
    _queryFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Home's search button: focus the field once this tab is shown.
  /// A filter set elsewhere (a genre chip): show its results from the top.
  void _onTabs() {
    final tabs = _tabs!;
    if (tabs.filterRequests != _filterRequests) {
      _filterRequests = tabs.filterRequests;
      _debounce?.cancel();
      _query.text = context.read<FilterCubit>().state.query;
      if (_query.text.isNotEmpty) setState(() => _searching = true);
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
      _load();
    }
    if (tabs.searchRequests == _searchRequests) return;
    _searchRequests = tabs.searchRequests;
    _focusSearch();
  }

  /// Shows the search field and focuses it.
  void _focusSearch() {
    if (!_searching) setState(() => _searching = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _queryFocus.requestFocus();
    });
  }

  /// The search button: shows the field, or hides it and drops the search.
  void _toggleSearch() {
    if (!_searching) return _focusSearch();
    setState(() => _searching = false);
    if (_query.text.isNotEmpty) {
      _query.clear();
      _search('');
    }
  }

  void _onQueryChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(text));
  }

  void _search(String text) {
    _debounce?.cancel();
    final cubit = context.read<FilterCubit>();
    if (cubit.state.query == text.trim()) return;
    cubit.setQuery(text.trim());
    _load();
  }

  Future<void> _load() async {
    _nextPage.reset();
    context.read<ExploreBloc>().add(
      ExploreRequested(filter: context.read<FilterCubit>().state),
    );
  }

  /// Another source was picked: its results from the top, without the old
  /// search.
  void _onSourceChanged(BuildContext context, ExploreFilter filter) {
    _debounce?.cancel();
    _query.text = filter.query;
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _load();
  }

  void _setQuick(FilterGroup group, String value) {
    final cubit = context.read<FilterCubit>();
    final features = context.read<SourcesCubit>().state.features;
    if (features.valueOf(cubit.state.values, group.key).firstOrNull == value) {
      return;
    }
    cubit.setValue(group.key, [value]);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<FilterCubit>().state;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocListener<FilterCubit, ExploreFilter>(
          listenWhen: (previous, current) => previous.source != current.source,
          listener: _onSourceChanged,
          child: BlocBuilder<ExploreBloc, ComicListState>(
            builder: (context, state) {
              return ScrollAwayHeader(
                keepShown: _queryFocus.hasFocus,
                header: Column(children: [_header(state), _controls(filter)]),
                body: RefreshIndicator(
                  color: Dotline.of(context).ink,
                  backgroundColor: Dotline.of(context).surface,
                  onRefresh: _load,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    // Scrolling the results ends typing, so the header can go.
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      ..._results(state),
                      SliverPadding(
                        padding: EdgeInsets.only(bottom: bottomInset),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(ComicListState state) {
    final source = context.watch<SourcesCubit>().state.active;
    return ScreenHeader(
      overline: AppText.explore,
      title: source?.baseName ?? AppText.explore,
      titleSemanticLabel: AppText.changeSource,
      onTitleTap: () => showSourcePicker(context),
      actions: [
        if (source != null && source.baseUrl.isNotEmpty)
          RoundIconButton(
            icon: LucideIcons300.globe,
            semanticLabel: AppText.openWebView,
            onTap: () => WebViewScreen.open(
              context,
              sourceId: source.id,
              url: source.baseUrl,
            ),
          ),
        RoundIconButton(
          icon: _searching ? LucideIcons300.x : LucideIcons300.search,
          semanticLabel: AppText.exploreSearchHint,
          onTap: _toggleSearch,
        ),
      ],
      subtitleWidget: SourceSubtitle(
        source: source,
        status: switch (state) {
          ComicListLoaded() => SourceStatus.online,
          ComicListNoInternet() => SourceStatus.offline,
          ComicListError() => SourceStatus.error,
          ComicListInitial() || ComicListLoading() => SourceStatus.connecting,
        },
      ),
    );
  }

  /// The source's quick filter group: segments when it has few options,
  /// else a row of chips. Null when it has none.
  Widget? _quickPicker(ExploreFilter filter) {
    final features = context.watch<SourcesCubit>().state.features;
    final group = features.quick;
    if (group == null || group.multi || group.options.length < 2) {
      return null;
    }
    final selected = features.valueOf(filter.values, group.key).firstOrNull;
    if (group.options.length <= 4) {
      return SegmentedControl<String>(
        selected: selected ?? '',
        onChanged: (value) => _setQuick(group, value),
        segments: [
          for (final o in group.options)
            Segment(value: o.value, label: o.label),
        ],
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (i, o) in group.options.indexed) ...[
            if (i > 0) const SizedBox(width: DotSpace.s2),
            DotChip(
              label: o.label,
              selected: selected == o.value,
              onTap: () => _setQuick(group, o.value),
            ),
          ],
        ],
      ),
    );
  }

  /// Search (when shown), then the quick filters with the filter button at
  /// their end; what the filter sets is spelt out below only when it is not
  /// the source's default.
  Widget _controls(ExploreFilter filter) {
    final c = Dotline.of(context);
    final features = context.watch<SourcesCubit>().state.features;
    final count = activeFilterCount(filter, features);
    final quick = _quickPicker(filter);
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
          if (_searching) ...[
            SearchField(
              hint: AppText.exploreSearchHint,
              controller: _query,
              focusNode: _queryFocus,
              onChanged: _onQueryChanged,
              onSubmitted: _search,
              onClear: () {
                _query.clear();
                _search('');
              },
            ),
            const SizedBox(height: DotSpace.s4),
          ],
          Row(
            children: [
              Expanded(child: quick ?? const SizedBox.shrink()),
              const SizedBox(width: DotSpace.s3),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  RoundIconButton(
                    icon: LucideIcons300.funnel,
                    semanticLabel: AppText.filter,
                    outlined: true,
                    onTap: () => showFilterSheet(context, onApply: _load),
                  ),
                  if (count > 0)
                    Positioned(
                      top: -DotSpace.s1,
                      right: -DotSpace.s1,
                      child: CountBadge(count: count),
                    ),
                ],
              ),
            ],
          ),
          if (count > 0) ...[
            const SizedBox(height: DotSpace.s3),
            Text(
              filterSummary(filter, features),
              style: DotlineText.label.copyWith(color: c.inkFaint),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _results(ComicListState state) => switch (state) {
    ComicListLoaded(:final comics) when comics.isEmpty => [
      SliverToBoxAdapter(
        child: EmptyState(
          icon: LucideIcons300.searchX,
          title: AppText.comicNotFound,
          message: _query.text.trim().isEmpty
              ? AppText.comicNotFoundFilter
              : AppText.comicNotFoundSearch,
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
        child: SourceError(
          message: message,
          sourceId: context.read<SourcesCubit>().state.activeId,
          onRetry: _load,
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
