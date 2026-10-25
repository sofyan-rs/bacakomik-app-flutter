import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/bookmark/presentation/widgets/bookmark_sort.dart';
import 'package:bacakomik_app/features/category/presentation/pages/categories_screen.dart';
import 'package:bacakomik_app/features/settings/domain/entities/app_settings.dart';
import 'package:bacakomik_app/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// "Group & sort": what the Bookmarks tabs split by and how the comics are
/// ordered; both saved in settings.
Future<void> showGroupBySheet(BuildContext context) => showDotSheet<void>(
  context: context,
  builder: (context) => const _GroupBySheet(),
);

enum _Tab { group, sort }

class _GroupBySheet extends StatefulWidget {
  const _GroupBySheet();

  @override
  State<_GroupBySheet> createState() => _GroupBySheetState();
}

class _GroupBySheetState extends State<_GroupBySheet> {
  var _tab = _Tab.group;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ActionSheetHeader(
          icon: LucideIcons300.layers,
          title: AppText.groupAndSort,
        ),
        const SizedBox(height: DotSpace.s4),
        SegmentedControl<_Tab>(
          background: c.bg,
          selected: _tab,
          onChanged: (tab) => setState(() => _tab = tab),
          segments: const [
            Segment(value: _Tab.group, label: AppText.groupTab),
            Segment(value: _Tab.sort, label: AppText.sortShort),
          ],
        ),
        const SizedBox(height: DotSpace.s4),
        Flexible(
          child: SingleChildScrollView(
            child: switch (_tab) {
              _Tab.group => const _GroupOptions(),
              _Tab.sort => const _SortOptions(),
            },
          ),
        ),
      ],
    );
  }
}

/// Picking a grouping closes the sheet.
class _GroupOptions extends StatelessWidget {
  const _GroupOptions();

  static const _options = [
    (
      BookmarkGrouping.status,
      LucideIcons300.listFilter,
      AppText.groupByStatus,
      AppText.groupByStatusDescription,
    ),
    (
      BookmarkGrouping.source,
      LucideIcons300.puzzle,
      AppText.groupBySource,
      AppText.groupBySourceDescription,
    ),
    (
      BookmarkGrouping.category,
      LucideIcons300.folder,
      AppText.groupByCategory,
      AppText.groupByCategoryDescription,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final current = context.select(
      (SettingsCubit s) => s.state.bookmarkGrouping,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListGroup(
          background: c.bg,
          children: [
            for (final (grouping, icon, title, subtitle) in _options)
              ListRow(
                icon: icon,
                title: title,
                subtitle: subtitle,
                trailing: grouping == current
                    ? Icon(LucideIcons300.check, color: c.ink)
                    : null,
                onTap: () {
                  context.read<SettingsCubit>().update(
                    (s) => s.copyWith(bookmarkGrouping: grouping),
                  );
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
        const SizedBox(height: DotSpace.s4),
        DotButton.outline(
          label: AppText.manageCategories,
          leading: LucideIcons300.settings2,
          onTap: () {
            final navigator = Navigator.of(context)..pop();
            navigator.push(CategoriesScreen.route());
          },
        ),
      ],
    );
  }
}

/// Tapping an order picks it in its usual direction; tapping the selected
/// one reverses it. The sheet stays open so the direction can be flipped.
class _SortOptions extends StatelessWidget {
  const _SortOptions();

  static const _options = [
    (
      BookmarkSort.updated,
      LucideIcons300.refreshCw,
      AppText.sortUpdated,
      AppText.sortOldestFirst,
      AppText.sortNewestFirst,
    ),
    (
      BookmarkSort.title,
      LucideIcons300.caseSensitive,
      AppText.sortTitle,
      AppText.sortAToZ,
      AppText.sortZToA,
    ),
    (
      BookmarkSort.chapters,
      LucideIcons300.listOrdered,
      AppText.sortChapters,
      AppText.sortFewestFirst,
      AppText.sortMostFirst,
    ),
    (
      BookmarkSort.latestChapter,
      LucideIcons300.calendarClock,
      AppText.sortLatestChapter,
      AppText.sortOldestFirst,
      AppText.sortNewestFirst,
    ),
    (
      BookmarkSort.added,
      LucideIcons300.calendarPlus,
      AppText.sortAdded,
      AppText.sortOldestFirst,
      AppText.sortNewestFirst,
    ),
    (
      BookmarkSort.lastRead,
      LucideIcons300.history,
      AppText.sortLastRead,
      AppText.sortOldestFirst,
      AppText.sortNewestFirst,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final (current, direction) = context.select(
      (SettingsCubit s) =>
          (s.state.bookmarkSort, s.state.bookmarkSortDirection),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListGroup(
          background: c.bg,
          children: [
            for (final (sort, icon, title, ascending, descending) in _options)
              if ((sort == current ? direction : defaultDirectionOf(sort))
                  case final shown)
                ListRow(
                  icon: icon,
                  title: title,
                  // Selected: its direction. Otherwise: the one a tap picks.
                  subtitle: shown == SortDirection.ascending
                      ? ascending
                      : descending,
                  trailing: sort == current
                      ? Icon(
                          shown == SortDirection.ascending
                              ? LucideIcons300.arrowUp
                              : LucideIcons300.arrowDown,
                          color: c.ink,
                        )
                      : null,
                  onTap: () => context.read<SettingsCubit>().update(
                    (s) => s.copyWith(
                      bookmarkSort: sort,
                      bookmarkSortDirection: sort == current
                          ? _reversed(direction)
                          : shown,
                    ),
                  ),
                ),
          ],
        ),
        const SizedBox(height: DotSpace.s3),
        Text(
          AppText.sortReverseHint,
          textAlign: TextAlign.center,
          style: DotlineText.bodyS.copyWith(color: c.inkFaint),
        ),
      ],
    );
  }

  static SortDirection _reversed(SortDirection direction) =>
      direction == SortDirection.ascending
      ? SortDirection.descending
      : SortDirection.ascending;
}
