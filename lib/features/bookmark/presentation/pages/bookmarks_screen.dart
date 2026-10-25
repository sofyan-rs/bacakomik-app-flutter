import 'dart:async';

import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/comic_grid.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/bookmark/presentation/bloc/bookmark_cubit.dart';
import 'package:bacakomik_app/core/source/comic_key.dart';
import 'package:bacakomik_app/features/bookmark/presentation/widgets/bookmark_comic_card.dart';
import 'package:bacakomik_app/features/bookmark/presentation/widgets/bookmark_progress.dart';
import 'package:bacakomik_app/features/bookmark/presentation/widgets/group_by_sheet.dart';
import 'package:bacakomik_app/features/category/presentation/bloc/category_cubit.dart';
import 'package:bacakomik_app/features/category/presentation/widgets/set_categories_sheet.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/pages/comic_details_screen.dart';
import 'package:bacakomik_app/features/history/presentation/bloc/history_cubit.dart';
import 'package:bacakomik_app/features/migration/presentation/pages/source_migration_screen.dart';
import 'package:bacakomik_app/features/settings/domain/entities/app_settings.dart';
import 'package:bacakomik_app/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:bacakomik_app/features/source/presentation/bloc/sources_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Bookmark tab: tabs split by status, source or category ([BookmarkGrouping]),
/// local title search, long press to select, categorize and delete.
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final _query = TextEditingController();
  var _searching = false;

  /// Selected tab: [_allTab], a [BookmarkFilter] name, a source id, a category
  /// id or [_uncategorizedTab], depending on the grouping.
  var _group = _allTab;
  final _selected = <String>{};

  /// Progress per bookmark, recomputed only when bookmarks or history
  /// change (not on search keystrokes, filter or selection changes).
  List<BookmarkProgress> _all = const [];
  Object? _allBookmarks;
  Object? _allHistory;

  List<BookmarkProgress> _progress(
    BookmarkCubit bookmarks,
    HistoryCubit history,
  ) {
    if (!identical(_allBookmarks, bookmarks.state) ||
        !identical(_allHistory, history.state)) {
      _allBookmarks = bookmarks.state;
      _allHistory = history.state;
      _all = BookmarkProgress.of(bookmarks.state, history.index.isFinished);
    }
    return _all;
  }

  @override
  void dispose() {
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
      builder: (context) => _DeleteSheet(count: count),
    );
    if (confirmed != true || !mounted) return;
    await context.read<BookmarkCubit>().removeBookmarkList(_selected.toList());
    setState(_selected.clear);
  }

  static const _allTab = 'all';
  static const _uncategorizedTab = '';

  /// Tabs of [grouping] as (key, label).
  List<Segment<String>> _tabs(
    BookmarkGrouping grouping,
    List<BookmarkProgress> all,
    CategoryState categories,
  ) => [
    const Segment(value: _allTab, label: AppText.filterAll),
    ...switch (grouping) {
      BookmarkGrouping.status => [
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
        const Segment(value: _uncategorizedTab, label: AppText.uncategorized),
      ],
    },
  ];

  bool _inGroup(
    BookmarkGrouping grouping,
    BookmarkProgress item,
    CategoryState categories,
  ) {
    if (_group == _allTab) return true;
    final slug = item.bookmark.slug;
    return switch (grouping) {
      BookmarkGrouping.status => item.matches(
        BookmarkFilter.values.byName(_group),
      ),
      BookmarkGrouping.source => ComicKey.sourceOf(slug) == _group,
      BookmarkGrouping.category =>
        _group == _uncategorizedTab
            ? categories.idsOf(slug).isEmpty
            : categories.idsOf(slug).contains(_group),
    };
  }

  Future<void> _setCategories() async {
    final saved = await showSetCategoriesSheet(context, {..._selected});
    if (saved && mounted) setState(_selected.clear);
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
    final categories = context.watch<CategoryCubit>().state;
    final all = _progress(
      context.watch<BookmarkCubit>(),
      context.watch<HistoryCubit>(),
    );
    final updated = all.where((i) => i.hasUpdate).length;
    final tabs = _tabs(grouping, all, categories);
    // The tab is gone (grouping changed, category deleted): show all.
    if (!tabs.any((t) => t.value == _group)) _group = _allTab;
    final query = _query.text.trim().toLowerCase();
    final group = [
      for (final item in all)
        if (_inGroup(grouping, item, categories)) item,
    ];
    final shown = [
      for (final item in group)
        if (item.bookmark.comicDetails.title.toLowerCase().contains(query))
          item,
    ];

    return PopScope(
      canPop: _selected.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(_selected.clear);
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: Dotline.of(context).ink,
            backgroundColor: Dotline.of(context).surface,
            // Not awaited: the notification shows progress, and pulling
            // again in another group adds that group to the running queue.
            // Imported progress may be applied on the way: reload history
            // after the run.
            onRefresh: () async {
              final history = context.read<HistoryCubit>();
              unawaited(
                context
                    .read<BookmarkCubit>()
                    .updateBookmarkList([
                      for (final item in group) item.bookmark.slug,
                    ])
                    .then((_) => history.load()),
              );
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _selected.isEmpty
                      ? _header(all.length, updated)
                      : _selectionHeader(),
                ),
                if (_searching)
                  SliverToBoxAdapter(
                    child: Padding(
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
                  ),
                if (all.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DotSpace.s4,
                        0,
                        DotSpace.s4,
                        DotSpace.s5,
                      ),
                      child: ScrollableTabs<String>(
                        selected: _group,
                        onChanged: (g) => setState(() => _group = g),
                        segments: tabs,
                      ),
                    ),
                  ),
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
                                cover: item.bookmark.comicDetails.coverImg,
                              ),
                      );
                    },
                  ),
                SliverPadding(
                  padding: EdgeInsets.only(
                    bottom: DotSpace.s4 + MediaQuery.paddingOf(context).bottom,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(int count, int updated) {
    return ScreenHeader(
      title: AppText.bookmark,
      subtitle: count == 0
          ? null
          : '${AppText.count(count, AppText.comic, AppText.comics)} · '
                '$updated ${AppText.hasUpdate}',
      actions: [
        if (count > 0) ...[
          RoundIconButton(
            icon: LucideIcons300.layers,
            semanticLabel: AppText.groupBy,
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
          RoundIconButton(
            icon: LucideIcons300.arrowRightLeft,
            semanticLabel: AppText.migrateSource,
            onTap: _migrate,
          ),
          const SizedBox(width: DotSpace.s2),
          RoundIconButton(
            icon: LucideIcons300.folder,
            semanticLabel: AppText.setCategories,
            onTap: _setCategories,
          ),
          const SizedBox(width: DotSpace.s2),
          RoundIconButton(
            icon: LucideIcons300.trash2,
            semanticLabel: AppText.deleteBookmark,
            background: c.accent,
            foreground: c.onAccent,
            onTap: _confirmDelete,
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

/// Confirms deleting the selected bookmarks. Pops `true` to delete.
class _DeleteSheet extends StatelessWidget {
  const _DeleteSheet({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActionSheetHeader(
          icon: LucideIcons300.trash2,
          title: AppText.deleteBookmark,
          subtitle: AppText.count(count, AppText.comic, AppText.comics),
        ),
        const SizedBox(height: DotSpace.s4),
        Text(
          AppText.deleteBookmarkDescription,
          style: DotlineText.body.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: DotSpace.s5),
        DotButton.destructive(
          label: AppText.delete,
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
