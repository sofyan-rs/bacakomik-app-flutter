import 'dart:async';

import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/comic_grid.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/presentation/bloc/bookmark_cubit.dart';
import 'package:bacakomik_app/core/source/comic_key.dart';
import 'package:bacakomik_app/features/bookmark/presentation/widgets/bookmark_comic_card.dart';
import 'package:bacakomik_app/features/bookmark/presentation/widgets/bookmark_progress.dart';
import 'package:bacakomik_app/features/bookmark/presentation/widgets/bookmark_sort.dart';
import 'package:bacakomik_app/features/bookmark/presentation/widgets/group_by_sheet.dart';
import 'package:bacakomik_app/features/category/presentation/bloc/category_cubit.dart';
import 'package:bacakomik_app/features/category/presentation/widgets/set_categories_sheet.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/pages/comic_details_screen.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/history/presentation/bloc/history_cubit.dart';
import 'package:bacakomik_app/features/migration/presentation/pages/source_migration_screen.dart';
import 'package:bacakomik_app/features/settings/domain/entities/app_settings.dart';
import 'package:bacakomik_app/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:bacakomik_app/features/source/presentation/bloc/sources_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Bookmark tab: tabs split by status, source or category ([BookmarkGrouping]),
/// ordered by [BookmarkSort], local title search, long press to select,
/// categorize and delete.
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final _query = TextEditingController();
  var _searching = false;

  /// The search of the last build, to tell when it changes.
  var _lastQuery = '';

  /// Fling speed, in logical pixels per second, that changes the tab.
  static const _swipeVelocity = 300.0;

  /// Selected tab: [_allTab], a [BookmarkFilter] name, a source id, a category
  /// id or [_uncategorizedTab], depending on the grouping.
  var _group = _allTab;
  final _selected = <String>{};

  /// Progress per bookmark in the chosen order, recomputed only when
  /// bookmarks, history or the order change (not on search keystrokes,
  /// filter or selection changes). Grouping and search keep this order.
  List<BookmarkProgress> _all = const [];
  Object? _allBookmarks;
  Object? _allHistory;
  (BookmarkSort, SortDirection)? _allOrder;

  /// What each bookmark's progress was worked out from, by slug, so a
  /// history change (a page saved while reading) recounts only the comics
  /// whose history changed.
  var _sources = <String, _ProgressSource>{};

  List<BookmarkProgress> _progress(
    BookmarkCubit bookmarks,
    HistoryCubit history,
    (BookmarkSort, SortDirection) order,
  ) {
    final bookmarksChanged = !identical(_allBookmarks, bookmarks.state);
    final historyChanged = !identical(_allHistory, history.state);
    var changed = bookmarksChanged;
    if (bookmarksChanged || historyChanged) {
      _allBookmarks = bookmarks.state;
      _allHistory = history.state;
      final index = history.index;
      final sources = <String, _ProgressSource>{};
      final all = <BookmarkProgress>[];
      for (final bookmark in bookmarks.state) {
        final latest = index.latestOf(bookmark.slug);
        final count = index.countOf(bookmark.slug);
        final finished = index.finishedCountOf(bookmark.slug);
        var source = _sources[bookmark.slug];
        if (source == null ||
            !identical(source.bookmark, bookmark) ||
            !identical(source.latest, latest) ||
            source.count != count ||
            source.finished != finished) {
          changed = true;
          source = _ProgressSource(
            bookmark,
            latest,
            count,
            finished,
            BookmarkProgress.single(
              bookmark,
              index.isFinished,
              lastRead: latest?.readDate,
            ),
          );
        }
        sources[bookmark.slug] = source;
        all.add(source.progress);
      }
      _sources = sources;
      if (changed) _all = all;
      if (bookmarksChanged) {
        // Selected comics that were removed (deleted, migrated, synced
        // away) leave the selection.
        _selected.retainWhere(sources.containsKey);
      }
    }
    if (changed || order != _allOrder) {
      _allOrder = order;
      _all = sortBookmarks(_all, order.$1, order.$2);
    }
    return _all;
  }

  /// A refresh applied imported reading progress: show it right away.
  late final StreamSubscription<void> _historyChanges;

  @override
  void initState() {
    super.initState();
    final history = context.read<HistoryCubit>();
    _historyChanges = context.read<BookmarkCubit>().historyChanges.listen(
      (_) => history.load(),
    );
  }

  @override
  void dispose() {
    _historyChanges.cancel();
    _query.dispose();
    super.dispose();
  }

  void _toggleSelected(String slug) => setState(
    () =>
        _selected.contains(slug) ? _selected.remove(slug) : _selected.add(slug),
  );

  void _toggleSearch() => setState(() {
    _searching = !_searching;
    if (!_searching) _query.clear();
  });

  Future<void> _confirmDelete() async {
    final count = _selected.length;
    final confirmed = await showDotSheet<bool>(
      context: context,
      builder: (context) => _ConfirmSheet(
        icon: LucideIcons300.trash2,
        title: AppText.deleteBookmark,
        description: AppText.deleteBookmarkDescription,
        confirmLabel: AppText.delete,
        count: count,
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<BookmarkCubit>().removeBookmarkList(_selected.toList());
    if (mounted) setState(_selected.clear);
  }

  static const _allTab = 'all';
  static const _uncategorizedTab = '';

  /// Tabs of [grouping] as (key, label). Only status has an All tab: source
  /// and category tabs each hold their own comics. Uncategorized shows only
  /// while a comic has no category.
  List<Segment<String>> _tabs(
    BookmarkGrouping grouping,
    List<BookmarkProgress> all,
    CategoryState categories,
  ) => [
    ...switch (grouping) {
      BookmarkGrouping.status => [
        const Segment(value: _allTab, label: AppText.filterAll),
        Segment(
          value: BookmarkFilter.updated.name,
          label: AppText.filterUpdated,
        ),
        Segment(
          value: BookmarkFilter.finished.name,
          label: AppText.filterFinished,
        ),
      ],
      BookmarkGrouping.source => [
        for (final slug in {
          for (final item in all)
            ComicKey.sourceOf(item.bookmark.slug): item.bookmark.slug,
        }.values)
          Segment(
            value: ComicKey.sourceOf(slug),
            label: context.sourceNameOf(slug),
          ),
      ]..sort((a, b) => a.label.compareTo(b.label)),
      BookmarkGrouping.category => [
        for (final category in categories.categories)
          Segment(value: category.id, label: category.name),
        if (all.any((i) => categories.idsOf(i.bookmark.slug).isEmpty))
          const Segment(value: _uncategorizedTab, label: AppText.uncategorized),
      ],
    },
  ];

  bool _inGroup(
    BookmarkGrouping grouping,
    BookmarkProgress item,
    CategoryState categories,
    String group,
  ) {
    if (group == _allTab) return true;
    final slug = item.bookmark.slug;
    return switch (grouping) {
      BookmarkGrouping.status => item.matches(
        BookmarkFilter.values.byName(group),
      ),
      BookmarkGrouping.source => ComicKey.sourceOf(slug) == group,
      BookmarkGrouping.category =>
        group == _uncategorizedTab
            ? categories.idsOf(slug).isEmpty
            : categories.idsOf(slug).contains(group),
    };
  }

  /// Comics per tab of [grouping] (as [_inGroup] counts them, except the
  /// All tab, which holds every comic), in one pass over [all].
  Map<String, int> _counts(
    BookmarkGrouping grouping,
    List<BookmarkProgress> all,
    CategoryState categories,
  ) {
    final counts = <String, int>{};
    void add(String tab) => counts.update(tab, (n) => n + 1, ifAbsent: () => 1);
    for (final item in all) {
      final slug = item.bookmark.slug;
      switch (grouping) {
        case BookmarkGrouping.status:
          for (final filter in BookmarkFilter.values) {
            if (item.matches(filter)) add(filter.name);
          }
        case BookmarkGrouping.source:
          add(ComicKey.sourceOf(slug));
        case BookmarkGrouping.category:
          final ids = categories.idsOf(slug);
          if (ids.isEmpty) add(_uncategorizedTab);
          ids.forEach(add);
      }
    }
    return counts;
  }

  Future<void> _setCategories() async {
    final saved = await showSetCategoriesSheet(context, {..._selected});
    if (saved && mounted) setState(_selected.clear);
  }

  /// Marks every stored chapter of the selected comics read: the chapters
  /// their cards count, as of the last refresh.
  Future<void> _markAllRead() async {
    final selected = {..._selected};
    setState(_selected.clear);
    await context.read<HistoryCubit>().markAllRead({
      for (final b in context.read<BookmarkCubit>().state)
        if (selected.contains(b.slug)) b.slug: b.comicDetails,
    });
    if (!mounted) return;
    showSnackBar(
      context: context,
      message:
          '${AppText.count(selected.length, AppText.comic, AppText.comics)} '
          '${AppText.markedAllRead}',
    );
  }

  /// Removes the read chapters of the selected comics, after confirming:
  /// their progress cannot be brought back.
  Future<void> _markAllUnread() async {
    final selected = {..._selected};
    final confirmed = await showDotSheet<bool>(
      context: context,
      builder: (context) => _ConfirmSheet(
        icon: LucideIcons300.rotateCcw,
        title: AppText.markAllUnread,
        description: AppText.markAllUnreadDescription,
        confirmLabel: AppText.markUnread,
        count: selected.length,
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(_selected.clear);
    await context.read<HistoryCubit>().markAllUnread(selected);
    if (!mounted) return;
    showSnackBar(
      context: context,
      message:
          '${AppText.count(selected.length, AppText.comic, AppText.comics)} '
          '${AppText.markedAllUnread}',
    );
  }

  Future<void> _migrate() async {
    final keys = {..._selected};
    setState(_selected.clear);
    await SourceMigrationScreen.open(context, keys: keys);
  }

  @override
  Widget build(BuildContext context) {
    final grouping = context.select(
      (SettingsCubit s) => s.state.bookmarkGrouping,
    );
    final order = context.select(
      (SettingsCubit s) =>
          (s.state.bookmarkSort, s.state.bookmarkSortDirection),
    );
    final categories = context.watch<CategoryCubit>().state;
    final all = _progress(
      context.watch<BookmarkCubit>(),
      context.watch<HistoryCubit>(),
      order,
    );
    final updated = all.where((i) => i.hasUpdate).length;
    // A search covers every tab; the tab counts show its matches.
    final query = _query.text.trim().toLowerCase();
    final matching = query.isEmpty
        ? all
        : [
            for (final item in all)
              if (_matchesSearch(item, query)) item,
          ];
    final counts = _counts(grouping, matching, categories);
    final tabs = [
      for (final tab in _tabs(grouping, all, categories))
        Segment(
          value: tab.value,
          label: tab.label,
          count: tab.value == _allTab
              ? matching.length
              : counts[tab.value] ?? 0,
        ),
    ];
    // The tab is gone (grouping changed, category deleted): show the first.
    if (!tabs.any((t) => t.value == _group)) {
      _group = tabs.isEmpty ? _allTab : tabs.first.value;
    }
    // A new search with nothing in the open tab opens the first tab that
    // has matches.
    if (query != _lastQuery) {
      _lastQuery = query;
      final open = tabs.where((t) => t.value == _group).firstOrNull;
      if (query.isNotEmpty && open != null && open.count == 0) {
        _group =
            tabs.where((t) => (t.count ?? 0) > 0).firstOrNull?.value ?? _group;
      }
    }
    final shown = [
      for (final item in matching)
        if (_inGroup(grouping, item, categories, _group)) item,
    ];

    return PopScope(
      canPop: _selected.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(_selected.clear);
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Outside the scroll view so the title stays put.
              if (_selected.isEmpty)
                ValueListenableBuilder(
                  valueListenable: context.read<BookmarkCubit>().refreshing,
                  builder: (_, refreshing, _) =>
                      _header(all.length, updated, refreshing: refreshing),
                )
              else
                _selectionHeader(),
              // Search and tabs stay put too; only the grid scrolls.
              if (_searching)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DotSpace.s4,
                    0,
                    DotSpace.s4,
                    DotSpace.s4,
                  ),
                  child: SearchField(
                    hint: AppText.searchBookmarkHint,
                    controller: _query,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    onClear: () => setState(_query.clear),
                  ),
                ),
              if (all.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DotSpace.s4,
                    0,
                    DotSpace.s4,
                    DotSpace.s4,
                  ),
                  child: ScrollableTabs<String>(
                    selected: _group,
                    onChanged: (g) => setState(() => _group = g),
                    segments: tabs,
                  ),
                ),
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: _selected.isEmpty
                      ? (d) => _swipeTab(d, tabs)
                      : null,
                  child: RefreshIndicator(
                    color: Dotline.of(context).ink,
                    backgroundColor: Dotline.of(context).surface,
                    // Not awaited: the notification shows progress, and pulling
                    // again in another group adds that group to the running queue.
                    // The comics on screen: the open group, narrowed by a search.
                    onRefresh: () async => unawaited(
                      context.read<BookmarkCubit>().updateBookmarkList([
                        for (final item in shown) item.bookmark.slug,
                      ]),
                    ),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (shown.isEmpty)
                          SliverToBoxAdapter(child: _empty(all.isEmpty))
                        else
                          CoverGridSliver(
                            itemCount: shown.length,
                            textHeight: BookmarkComicCard.textHeight,
                            itemBuilder: (context, index) {
                              final item = shown[index];
                              final slug = item.bookmark.slug;
                              return BookmarkComicCard(
                                item: item,
                                isSelected: _selected.contains(slug),
                                onLongPress: () => _toggleSelected(slug),
                                onTap: _selected.isNotEmpty
                                    ? () => _toggleSelected(slug)
                                    : () => ComicDetailsScreen.open(
                                        context,
                                        slug: slug,
                                        title: item.bookmark.comicDetails.title,
                                        cover:
                                            item.bookmark.comicDetails.coverImg,
                                      ),
                              );
                            },
                          ),
                        SliverPadding(
                          padding: EdgeInsets.only(
                            bottom:
                                DotSpace.s4 +
                                MediaQuery.paddingOf(context).bottom,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The search [query] (trimmed, lower case) is in the title or one of the
  /// alternative titles.
  static bool _matchesSearch(BookmarkProgress item, String query) {
    final details = item.bookmark.comicDetails;
    return details.title.toLowerCase().contains(query) ||
        details.alternativeTitle.toLowerCase().contains(query);
  }

  /// A sideways fling on the comics opens the next or previous tab.
  void _swipeTab(DragEndDetails details, List<Segment<String>> tabs) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < _swipeVelocity || tabs.length < 2) return;
    final i = tabs.indexWhere((t) => t.value == _group);
    final next = (i + (velocity < 0 ? 1 : -1)).clamp(0, tabs.length - 1);
    if (next == i) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() => _group = tabs[next].value);
  }

  Widget _header(int count, int updated, {required bool refreshing}) {
    return ScreenHeader(
      title: AppText.bookmark,
      subtitle: count == 0
          ? null
          : '${AppText.count(count, AppText.comic, AppText.comics)} · '
                '$updated ${AppText.hasUpdate}',
      actions: [
        if (refreshing)
          RoundIconButton(
            icon: LucideIcons300.circleStop,
            semanticLabel: AppText.stopRefresh,
            onTap: context.read<BookmarkCubit>().cancelRefresh,
          ),
        if (count > 0) ...[
          RoundIconButton(
            icon: LucideIcons300.layers,
            semanticLabel: AppText.groupAndSort,
            onTap: () => showGroupBySheet(context),
          ),
          RoundIconButton(
            icon: _searching ? LucideIcons300.x : LucideIcons300.search,
            semanticLabel: AppText.searchBookmarkHint,
            onTap: _toggleSearch,
          ),
        ],
      ],
    );
  }

  Widget _selectionHeader() {
    final c = Dotline.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DotSpace.s4,
        DotSpace.s5,
        DotSpace.s4,
        DotSpace.s5,
      ),
      child: Row(
        children: [
          RoundIconButton(
            icon: LucideIcons300.x,
            semanticLabel: AppText.cancel,
            onTap: () => setState(_selected.clear),
          ),
          const SizedBox(width: DotSpace.s3),
          Expanded(
            child: Text(
              '${_selected.length} ${AppText.selected}'.toUpperCase(),
              style: DotlineText.label.copyWith(color: c.ink),
            ),
          ),
          DotMenuButton(
            items: [
              DotMenuItem(
                label: AppText.markRead,
                icon: LucideIcons300.checkCheck,
                onTap: _markAllRead,
              ),
              DotMenuItem(
                label: AppText.markUnread,
                icon: LucideIcons300.rotateCcw,
                onTap: _markAllUnread,
              ),
              DotMenuItem(
                label: AppText.setCategories,
                icon: LucideIcons300.folder,
                onTap: _setCategories,
              ),
              DotMenuItem(
                label: AppText.migrateSource,
                icon: LucideIcons300.arrowRightLeft,
                onTap: _migrate,
              ),
              DotMenuItem(
                label: AppText.deleteBookmark,
                icon: LucideIcons300.trash2,
                onTap: _confirmDelete,
                destructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _empty(bool noBookmarks) {
    if (noBookmarks) {
      return const EmptyState(
        icon: LucideIcons300.bookmark,
        title: AppText.bookmarkEmpty,
        message: AppText.bookmarkEmptyHint,
      );
    }
    return EmptyState(
      icon: LucideIcons300.searchX,
      title: AppText.comicNotFound,
      message: _query.text.isEmpty ? null : AppText.comicNotFoundSearch,
    );
  }
}

/// The bookmark and history state one [BookmarkProgress] was made from.
class _ProgressSource {
  _ProgressSource(
    this.bookmark,
    this.latest,
    this.count,
    this.finished,
    this.progress,
  );

  final Bookmark bookmark;
  final ReadHistory? latest;
  final int count;
  final int finished;
  final BookmarkProgress progress;
}

/// Confirms a destructive action on the selected bookmarks. Pops `true` to
/// go ahead.
class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.icon,
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.count,
  });

  final IconData icon;
  final String title;
  final String description;
  final String confirmLabel;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActionSheetHeader(
          icon: icon,
          title: title,
          subtitle: AppText.count(count, AppText.comic, AppText.comics),
        ),
        const SizedBox(height: DotSpace.s4),
        Text(description, style: DotlineText.body.copyWith(color: c.inkMuted)),
        const SizedBox(height: DotSpace.s5),
        DotButton.destructive(
          label: confirmLabel,
          onTap: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: DotSpace.s3),
        DotButton.outline(
          label: AppText.cancel,
          onTap: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
