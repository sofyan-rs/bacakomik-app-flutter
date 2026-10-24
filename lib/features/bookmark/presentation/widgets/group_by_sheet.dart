import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/category/presentation/pages/categories_screen.dart';
import 'package:bacakomik_app/features/settings/domain/entities/app_settings.dart';
import 'package:bacakomik_app/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Picks what the Bookmarks tabs split by; saved in settings.
Future<void> showGroupBySheet(BuildContext context) => showDotSheet<void>(
  context: context,
  builder: (context) => const _GroupBySheet(),
);

class _GroupBySheet extends StatelessWidget {
  const _GroupBySheet();

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
    final current = context.watch<SettingsCubit>().state.bookmarkGrouping;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ActionSheetHeader(
          icon: LucideIcons300.layers,
          title: AppText.groupBy,
        ),
        const SizedBox(height: DotSpace.s4),
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
