import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/category/domain/entities/category.dart';
import 'package:bacakomik_app/features/category/presentation/bloc/category_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Add, rename, delete and reorder bookmark categories.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const CategoriesScreen());

  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push(route());

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final categories = context.watch<CategoryCubit>().state.categories;
    final cubit = context.read<CategoryCubit>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DotTopBar(title: AppText.categories),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DotSpace.s4,
                0,
                DotSpace.s4,
                DotSpace.s4,
              ),
              child: Text(
                AppText.categoriesDescription,
                style: DotlineText.bodyS.copyWith(color: c.inkFaint),
              ),
            ),
            Expanded(
              child: categories.isEmpty
                  ? const EmptyState(
                      icon: LucideIcons300.folder,
                      title: AppText.noCategories,
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DotSpace.s4,
                      ),
                      buildDefaultDragHandles: false,
                      itemCount: categories.length,
                      onReorderItem: cubit.move,
                      itemBuilder: (context, index) => _CategoryRow(
                        key: ValueKey(categories[index].id),
                        index: index,
                        category: categories[index],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(DotSpace.s4),
              child: DotButton(
                label: AppText.addCategory,
                leading: LucideIcons300.plus,
                onTap: () async {
                  final name = await showCategoryNameSheet(context);
                  if (name != null) await cubit.create(name);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({super.key, required this.index, required this.category});

  final int index;
  final LibraryCategory category;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final cubit = context.read<CategoryCubit>();
    final count = cubit.state.bySlug.values
        .where((e) => e.categoryIds.contains(category.id))
        .length;

    return Padding(
      padding: const EdgeInsets.only(bottom: DotSpace.s2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DotRadius.m),
        child: ColoredBox(
          color: c.surface,
          child: ListRow(
            leading: ReorderableDragStartListener(
              index: index,
              child: Icon(LucideIcons300.gripVertical, color: c.inkFaint),
            ),
            title: category.name,
            subtitle: AppText.count(count, AppText.comic, AppText.comics),
            onTap: () async {
              final name = await showCategoryNameSheet(
                context,
                initial: category.name,
              );
              if (name != null) await cubit.rename(category.id, name);
            },
            trailing: RoundIconButton(
              icon: LucideIcons300.trash2,
              semanticLabel: AppText.deleteCategory,
              size: 36,
              iconSize: DotSize.iconSmall,
              background: Colors.transparent,
              onTap: () async {
                if (await _confirmDelete(context, category)) {
                  await cubit.delete(category.id);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  static Future<bool> _confirmDelete(
    BuildContext context,
    LibraryCategory category,
  ) async {
    final confirmed = await showDotSheet<bool>(
      context: context,
      builder: (context) {
        final c = Dotline.of(context);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ActionSheetHeader(
              icon: LucideIcons300.trash2,
              title: AppText.deleteCategory,
              subtitle: category.name,
            ),
            const SizedBox(height: DotSpace.s4),
            Text(
              AppText.deleteCategoryDescription,
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
      },
    );
    return confirmed ?? false;
  }
}

/// Asks for a category name; null when cancelled or left blank.
Future<String?> showCategoryNameSheet(
  BuildContext context, {
  String initial = '',
}) => showDotSheet<String>(
  context: context,
  builder: (context) => _NameSheet(initial: initial),
);

class _NameSheet extends StatefulWidget {
  const _NameSheet({required this.initial});

  final String initial;

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    Navigator.of(context).pop(name.isEmpty ? null : name);
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final renaming = widget.initial.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActionSheetHeader(
          icon: LucideIcons300.folder,
          title: renaming ? AppText.renameCategory : AppText.addCategory,
        ),
        const SizedBox(height: DotSpace.s4),
        TextField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          style: DotlineText.body.copyWith(color: c.ink),
          decoration: const InputDecoration(hintText: AppText.newCategoryHint),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: DotSpace.s4),
        DotButton(label: AppText.save, onTap: _submit),
      ],
    );
  }
}
