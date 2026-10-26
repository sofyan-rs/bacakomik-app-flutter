import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/explore/domain/entities/explore_filter.dart';
import 'package:bacakomik_app/features/explore/presentation/bloc/filter_cubit.dart';
import 'package:bacakomik_app/features/source/presentation/bloc/sources_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Whether [group] has a value other than its default in [filter].
bool _isSet(ExploreFilter filter, FilterGroup group) {
  final value = filter.values[group.key];
  return value != null && !listEquals(value, group.defaults);
}

/// Filters shown on the Explore filter button: every group set away from
/// its default, multi groups by their picked count. The quick group is not
/// counted because its picker is already on screen.
int activeFilterCount(ExploreFilter filter, SourceFeatures source) => [
  for (final group in source.groups)
    if (!group.quick && _isSet(filter, group))
      group.multi ? filter.values[group.key]!.length : 1,
].fold(0, (a, b) => a + b);

/// "LATEST UPDATE · ONGOING · 2 GENRE" line above the Explore grid: the
/// first group (usually the sort) always, the rest when set.
String filterSummary(ExploreFilter filter, SourceFeatures source) {
  final parts = <String>[];
  for (final (i, group) in source.groups.indexed) {
    if (group.quick || (i > 0 && !_isSet(filter, group))) continue;
    final value = source.valueOf(filter.values, group.key);
    if (group.multi) {
      if (value.isNotEmpty) parts.add('${value.length} ${group.label}');
    } else if (value.isNotEmpty) {
      parts.add(group.labelOf(value.first));
    }
  }
  return parts.join(' · ').toUpperCase();
}

/// Opens the filter sheet. Calls [onApply] after the filter is saved.
Future<void> showFilterSheet(
  BuildContext context, {
  required VoidCallback onApply,
}) {
  final cubit = context.read<FilterCubit>();
  final sources = context.read<SourcesCubit>();
  return showDotSheet(
    context: context,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: cubit),
        BlocProvider.value(value: sources),
      ],
      child: FilterComic(onApply: onApply),
    ),
  );
}

/// Filter sheet content: one section per filter group of the source,
/// single-select or multi-select. Changes apply only on "Show results".
class FilterComic extends StatefulWidget {
  const FilterComic({super.key, required this.onApply});

  final VoidCallback onApply;

  @override
  State<FilterComic> createState() => _FilterComicState();
}

class _FilterComicState extends State<FilterComic> {
  late FilterValues _values = {...context.read<FilterCubit>().state.values};

  void _apply() {
    context.read<FilterCubit>().setValues(_values);
    widget.onApply();
    Navigator.of(context).pop();
  }

  void _tap(FilterGroup group, String value) {
    setState(() {
      if (!group.multi) {
        _values = {
          ..._values,
          group.key: [value],
        };
        return;
      }
      final current = [...?_values[group.key]];
      current.contains(value) ? current.remove(value) : current.add(value);
      _values = {..._values, group.key: current};
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final source = context.watch<SourcesCubit>().state.features;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppText.filter,
                style: DotlineText.title.copyWith(color: c.ink),
              ),
            ),
            GestureDetector(
              // Reset clears the filters, not the search text.
              onTap: () => setState(() => _values = {}),
              child: Padding(
                padding: const EdgeInsets.all(DotSpace.s3),
                child: Text(
                  AppText.reset,
                  style: DotlineText.body.copyWith(color: c.inkMuted),
                ),
              ),
            ),
            RoundIconButton(
              icon: LucideIcons300.x,
              semanticLabel: AppText.close,
              background: Colors.transparent,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: DotSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (source.groups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: DotSpace.s5),
                    child: Text(
                      AppText.noFilters,
                      style: DotlineText.body.copyWith(color: c.inkMuted),
                    ),
                  ),
                for (final group in source.groups)
                  if (group.options.isNotEmpty)
                    _Section(
                      group: group,
                      selected: source.valueOf(_values, group.key),
                      onTap: (value) => _tap(group, value),
                    ),
              ],
            ),
          ),
        ),
        const Divider(),
        const SizedBox(height: DotSpace.s4),
        DotButton(label: AppText.showResults, onTap: _apply),
      ],
    );
  }
}

/// One filter group. A long one (Mihon sources list 50+ genres) shows its
/// first [_folded] options, plus any picked further down, until expanded.
class _Section extends StatefulWidget {
  const _Section({
    required this.group,
    required this.selected,
    required this.onTap,
  });

  final FilterGroup group;
  final List<String> selected;
  final void Function(String value) onTap;

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  static const _folded = 12;

  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final group = widget.group;
    final selected = widget.selected;
    final label = group.multi && selected.isNotEmpty
        ? '${group.label} · ${selected.length} ${AppText.selected}'
        : group.label;
    final foldable = group.options.length > _folded + 2;
    final options = !foldable || _expanded
        ? group.options
        : [
            for (final (i, o) in group.options.indexed)
              if (i < _folded || selected.contains(o.value)) o,
          ];
    return Padding(
      padding: const EdgeInsets.only(top: DotSpace.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: DotlineText.label.copyWith(color: c.inkFaint),
          ),
          const SizedBox(height: DotSpace.s3),
          if (group.sort)
            _SortChips(
              group: group,
              selected: selected.firstOrNull ?? '',
              onTap: widget.onTap,
            )
          else
            Wrap(
              spacing: DotSpace.s2,
              runSpacing: DotSpace.s2,
              children: [
                for (final option in options)
                  DotChip(
                    label: option.label,
                    selected: selected.contains(option.value),
                    onTap: () => widget.onTap(option.value),
                  ),
              ],
            ),
          if (foldable && !group.sort)
            Pressable(
              semanticLabel: _expanded ? AppText.showLess : AppText.showAll,
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.only(top: DotSpace.s3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      (_expanded
                              ? AppText.showLess
                              : '${AppText.showAll} · ${group.options.length}')
                          .toUpperCase(),
                      style: DotlineText.label.copyWith(color: c.inkMuted),
                    ),
                    const SizedBox(width: DotSpace.s1),
                    Icon(
                      _expanded
                          ? LucideIcons300.chevronUp
                          : LucideIcons300.chevronDown,
                      size: DotSize.iconSmall,
                      color: c.inkMuted,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A sort group ([FilterGroup.sort]) as one chip per field: the picked one
/// shows its direction, and tapping it again turns the direction around.
/// Another field starts descending (newest, most popular first).
class _SortChips extends StatelessWidget {
  const _SortChips({
    required this.group,
    required this.selected,
    required this.onTap,
  });

  final FilterGroup group;

  /// `<field>:a`, `<field>:d`, or `''` for the source's own order.
  final String selected;
  final void Function(String value) onTap;

  @override
  Widget build(BuildContext context) {
    final fields = <String, String>{};
    for (final o in group.options) {
      final i = o.value.indexOf(':');
      if (i > 0) fields.putIfAbsent(o.value.substring(0, i), () => o.label);
    }
    final hasDefault = group.options.any((o) => o.value.isEmpty);
    return Wrap(
      spacing: DotSpace.s2,
      runSpacing: DotSpace.s2,
      children: [
        if (hasDefault)
          DotChip(
            label: group.labelOf(''),
            selected: selected.isEmpty,
            onTap: () => onTap(''),
          ),
        for (final MapEntry(key: field, value: label) in fields.entries)
          if (selected.startsWith('$field:'))
            DotChip(
              label: label,
              selected: true,
              trailing: selected.endsWith(':a')
                  ? LucideIcons300.arrowUp
                  : LucideIcons300.arrowDown,
              onTap: () =>
                  onTap('$field:${selected.endsWith(':a') ? 'd' : 'a'}'),
            )
          else
            DotChip(label: label, onTap: () => onTap('$field:d')),
      ],
    );
  }
}
