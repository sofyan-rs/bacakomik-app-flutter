import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/category/presentation/bloc/category_cubit.dart';
import 'package:bacakomik_app/features/category/presentation/pages/categories_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Puts the comics [slugs] in categories. A category some of them are
/// already in starts half-checked and is left alone unless tapped. Pops
/// `true` when saved. With [skippable] (right after bookmarking) a Skip
/// button closes it instead of Add category.
Future<bool> showSetCategoriesSheet(
  BuildContext context,
  Set<String> slugs, {
  bool skippable = false,
}) async =>
    await showDotSheet<bool>(
      context: context,
      builder: (_) => _SetCategoriesSheet(slugs: slugs, skippable: skippable),
    ) ??
    false;

class _SetCategoriesSheet extends StatefulWidget {
  const _SetCategoriesSheet({required this.slugs, required this.skippable});

  final Set<String> slugs;
  final bool skippable;

  @override
  State<_SetCategoriesSheet> createState() => _SetCategoriesSheetState();
}

class _SetCategoriesSheetState extends State<_SetCategoriesSheet> {
  /// Per category id: true in all, false in none, null in some (untouched).
  final _checked = <String, bool?>{};

  bool? _initial(CategoryState state, String id) {
    final count = widget.slugs.where((s) => state.idsOf(s).contains(id)).length;
    return count == 0
        ? false
        : count == widget.slugs.length
        ? true
        : null;
  }

  Future<void> _save() async {
    final state = context.read<CategoryCubit>().state;
    final add = <String>{};
    final remove = <String>{};
    for (final category in state.categories) {
      final id = category.id;
      if (!_checked.containsKey(id)) continue;
      switch (_checked[id]) {
        case true:
          add.add(id);
        case false:
          remove.add(id);
        case null:
      }
    }
    await context.read<CategoryCubit>().setCategories(
      widget.slugs,
      add: add,
      remove: remove,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final state = context.watch<CategoryCubit>().state;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActionSheetHeader(
          icon: LucideIcons300.folder,
          title: AppText.setCategories,
          subtitle: AppText.count(
            widget.slugs.length,
            AppText.comic,
            AppText.comics,
          ),
        ),
        const SizedBox(height: DotSpace.s4),
        if (state.categories.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: DotSpace.s4),
            child: Text(
              AppText.noCategories,
              style: DotlineText.body.copyWith(color: c.inkMuted),
            ),
          )
        else
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final category in state.categories)
                  Builder(
                    builder: (context) {
                      final value = _checked.containsKey(category.id)
                          ? _checked[category.id]
                          : _initial(state, category.id);
                      void toggle() =>
                          setState(() => _checked[category.id] = value != true);
                      return ListRow(
                        title: category.name,
                        onTap: toggle,
                        trailing: Checkbox(
                          value: value,
                          tristate: value == null,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          activeColor: c.ink,
                          checkColor: c.onInk,
                          onChanged: (_) => toggle(),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        const SizedBox(height: DotSpace.s3),
        if (widget.skippable)
          DotButton.outline(
            label: AppText.skip,
            onTap: () => Navigator.of(context).pop(false),
          )
        else
          DotButton.outline(
            label: AppText.addCategory,
            leading: LucideIcons300.plus,
            onTap: () async {
              final cubit = context.read<CategoryCubit>();
              final name = await showCategoryNameSheet(context);
              if (name != null) await cubit.create(name);
            },
          ),
        const SizedBox(height: DotSpace.s3),
        DotButton(
          label: AppText.save,
          onTap: state.categories.isEmpty ? null : _save,
        ),
      ],
    );
  }
}
